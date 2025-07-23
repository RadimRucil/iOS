import Foundation

class ClientsViewModel: ObservableObject {
    @Published var clients: [Client] = []
    
    private let userDefaults = UserDefaults.standard
    private let clientsKey = "SavedClients"
    
    init() {
        loadClients()
        // Naslouchat notifikacím o aktualizaci statistik
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UpdateClientStats"),
            object: nil,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo,
               let clientName = userInfo["clientName"] as? String,
               let orderValue = userInfo["orderValue"] as? Double {
                self.updateClientStats(clientName: clientName, orderValue: orderValue)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addClient(_ client: Client) {
        clients.append(client)
        saveClients()
        objectWillChange.send()
    }
    
    func updateClient(_ client: Client) {
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
            saveClients()
        }
    }
    
    func deleteClient(_ client: Client) {
        clients.removeAll { $0.id == client.id }
        saveClients()
    }
    
    func loadClients() {
        guard let data = userDefaults.data(forKey: clientsKey) else {
            print("ClientsViewModel: No saved clients found")
            return
        }
        
        do {
            clients = try JSONDecoder().decode([Client].self, from: data)
            print("ClientsViewModel: Successfully loaded \(clients.count) clients")
        } catch {
            print("ClientsViewModel: Failed to decode clients: \(error)")
        }
    }
    
    func getClient(by name: String) -> Client? {
        return clients.first { $0.name.lowercased() == name.lowercased() }
    }
    
    func updateClientStatsFromOrder(_ order: Order, isDeleting: Bool = false) {
        print("ClientsViewModel: Updating stats for order: \(order.name), deleting: \(isDeleting)")
        print("ClientsViewModel: Order clientName: '\(order.clientName)'")
        print("ClientsViewModel: Order clientID: \(order.clientID?.uuidString ?? "nil")")
        print("ClientsViewModel: Available clients: \(clients.map { "'\($0.name)' (ID: \($0.id.uuidString.prefix(8)))" })")
        
        let multiplier = isDeleting ? -1.0 : 1.0
        let paidAmount = calculatePaidAmount(for: order)
        
        var clientFound = false
        
        // Prioritně hledat podle clientID
        if let clientID = order.clientID,
           let index = clients.firstIndex(where: { $0.id == clientID }) {
            let oldOrders = clients[index].totalOrders
            let oldSpent = clients[index].totalSpent
            
            clients[index].totalOrders += Int(1 * multiplier)
            clients[index].totalSpent += paidAmount * multiplier
            
            // Zajistit, že hodnoty nejdou pod nulu
            clients[index].totalOrders = max(0, clients[index].totalOrders)
            clients[index].totalSpent = max(0, clients[index].totalSpent)
            
            clientFound = true
            print("ClientsViewModel: Updated client by ID: \(clients[index].name)")
            print("ClientsViewModel: Orders: \(oldOrders) -> \(clients[index].totalOrders)")
            print("ClientsViewModel: Spent: \(oldSpent) -> \(clients[index].totalSpent)")
        }
        // Fallback na jméno pro starší zakázky nebo když clientID není nastaveno
        else if !order.clientName.isEmpty {
            let matchingClients = clients.enumerated().filter { _, client in
                client.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == 
                order.clientName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            print("ClientsViewModel: Searching by name, found \(matchingClients.count) matches")
            
            if let (index, _) = matchingClients.first {
                let oldOrders = clients[index].totalOrders
                let oldSpent = clients[index].totalSpent
                
                clients[index].totalOrders += Int(1 * multiplier)
                clients[index].totalSpent += paidAmount * multiplier
                
                // Zajistit, že hodnoty nejdou pod nulu
                clients[index].totalOrders = max(0, clients[index].totalOrders)
                clients[index].totalSpent = max(0, clients[index].totalSpent)
                
                clientFound = true
                print("ClientsViewModel: Updated client by name: \(clients[index].name)")
                print("ClientsViewModel: Orders: \(oldOrders) -> \(clients[index].totalOrders)")
                print("ClientsViewModel: Spent: \(oldSpent) -> \(clients[index].totalSpent)")
            }
        }
        
        // Pokud klient není nalezen a přidáváme zakázku (ne mažeme), vytvoř nového klienta
        if !clientFound && !isDeleting && !order.clientName.isEmpty {
            print("ClientsViewModel: Creating new client for order")
            var newClient = Client(
                name: order.clientName,
                email: order.clientEmail,
                phone: order.clientPhone,
                ico: order.clientICO,
                address: order.clientAddress
            )
            newClient.totalOrders = 1
            newClient.totalSpent = paidAmount
            clients.append(newClient)
            print("ClientsViewModel: Created new client: \(newClient.name) (ID: \(newClient.id.uuidString.prefix(8)))")
            clientFound = true
        }
        
        if clientFound {
            saveClients()
        } else if isDeleting {
            print("ClientsViewModel: Client not found for deletion - this is normal if client was already deleted")
        } else {
            print("ClientsViewModel: ERROR - No client created or found for order!")
        }
    }
    
    func getUnpaidAmount(for client: Client, from orders: [Order]) -> Double {
        // Najít zakázky podle clientID nebo jména (fallback)
        let clientOrders = orders.filter { order in
            if let clientID = order.clientID {
                return clientID == client.id
            } else {
                return order.clientName.lowercased() == client.name.lowercased()
            }
        }
        
        return clientOrders.reduce(0.0) { total, order in
            var unpaidAmount = 0.0
            
            // Přidat nezaplacenou zálohu
            if order.deposit > 0 && !order.isDepositPaid {
                unpaidAmount += order.deposit
            }
            
            // Přidar nezaplacené doplacení
            if order.remainingAmount > 0 && !order.isFinalPaymentPaid {
                unpaidAmount += order.remainingAmount
            }
            
            // Pokud není záloha ale celá částka není zaplacená
            if order.deposit == 0 && !order.isFinalPaymentPaid {
                unpaidAmount += order.price
            }
            
            return total + unpaidAmount
        }
    }
    
    func recalculateAllClientStats(from orders: [Order]) {
        // Vynulovat všechny statistiky
        for index in clients.indices {
            clients[index].totalOrders = 0
            clients[index].totalSpent = 0
        }
        
        // Přepočítat ze zakázek podle skutečně zaplacených částek
        for order in orders {
            if !order.clientName.isEmpty {
                let paidAmount = calculatePaidAmount(for: order)
                
                // Prioritně hledat podle clientID
                if let clientID = order.clientID,
                   let index = clients.firstIndex(where: { $0.id == clientID }) {
                    clients[index].totalOrders += 1
                    clients[index].totalSpent += paidAmount
                }
                // Fallback na jméno
                else if let index = clients.firstIndex(where: { $0.name.lowercased() == order.clientName.lowercased() }) {
                    clients[index].totalOrders += 1
                    clients[index].totalSpent += paidAmount
                }
            }
        }
        
        saveClients()
    }
    
    func migrateOrdersToUseClientID(_ orders: inout [Order]) {
        for orderIndex in orders.indices {
            let order = orders[orderIndex]
            
            // Pokud zakázka nemá clientID, pokus se ho najít podle jména
            if order.clientID == nil && !order.clientName.isEmpty {
                if let client = clients.first(where: { $0.name.lowercased() == order.clientName.lowercased() }) {
                    orders[orderIndex].clientID = client.id
                }
            }
        }
    }
    
    func getOrderHistory(for client: Client, from orders: [Order]) -> [Order] {
        // Použití stejné logiky jako v recalculateAllClientStats
        let filteredOrders = orders.filter { order in
            if let clientID = order.clientID {
                return clientID == client.id
            } else {
                return order.clientName.lowercased() == client.name.lowercased()
            }
        }
        print("getOrderHistory: Found \(filteredOrders.count) orders for client \(client.name)")
        for order in filteredOrders {
            print("Order: \(order.name), Date: \(order.date), Status: \(order.status.rawValue)")
        }
        return filteredOrders
    }
    
    private func updateClientStats(clientName: String, orderValue: Double) {
        if let index = clients.firstIndex(where: { $0.name.lowercased() == clientName.lowercased() }) {
            clients[index].totalOrders += 1
            clients[index].totalSpent += orderValue
            saveClients()
        } else if !clientName.isEmpty {
            // Vytvořit nového klienta pokud neexistuje
            var newClient = Client(name: clientName)
            newClient.totalOrders = 1
            newClient.totalSpent = orderValue
            clients.append(newClient)
            saveClients()
        }
    }
    
    private func saveClients() {
        if let encoded = try? JSONEncoder().encode(clients) {
            userDefaults.set(encoded, forKey: clientsKey)
            userDefaults.synchronize()
            objectWillChange.send()
        }
    }
    
    private func calculatePaidAmount(for order: Order) -> Double {
        var paidAmount = 0.0
        
        // Přidat zálohu pokud je zaplacená
        if order.deposit > 0 && order.isDepositPaid {
            paidAmount += order.deposit
        }
        
        // Přidat doplacení pokud je zaplacené
        if order.remainingAmount > 0 && order.isFinalPaymentPaid {
            paidAmount += order.remainingAmount
        }
        
        // Pokud není záloha ale celá částka je zaplacená (pro případ bez zálohy)
        if order.deposit == 0 && order.isFinalPaymentPaid {
            paidAmount += order.price
        }
        
        return paidAmount
    }
}
