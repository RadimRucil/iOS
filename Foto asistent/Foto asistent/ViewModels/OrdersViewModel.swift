import Foundation
import UserNotifications

class OrdersViewModel: ObservableObject {
    @Published var orders: [Order] = []
    @Published var error: AppError?
    private let userDefaults = UserDefaults.standard
    private let ordersKey = "SavedOrders"
    weak var clientsViewModel: ClientsViewModel?
    
    init() {
        loadOrders()
    }
    
    func setClientsViewModel(_ clientsViewModel: ClientsViewModel) {
        self.clientsViewModel = clientsViewModel
        // Načíst klienty před migrací zakázek
        clientsViewModel.loadClients()
        migrateOrdersToUseClientID()
        saveOrders()
        clientsViewModel.recalculateAllClientStats(from: orders)
    }
    
    func addOrder(name: String, clientName: String = "", clientEmail: String = "", clientPhone: String = "", clientICO: String = "", clientAddress: String = "", location: String = "", date: Date, duration: Int = 60, price: Double, deposit: Double = 0, notes: String = "") {
        print("OrdersViewModel: Adding order: \(name) for client: '\(clientName)'")
        
        var clientID: UUID? = nil
        
        // Pokusit se najít existujícího klienta podle jména
        if !clientName.isEmpty {
            if let existingClient = clientsViewModel?.getClient(by: clientName) {
                clientID = existingClient.id
                print("OrdersViewModel: Found existing client: \(existingClient.name) (ID: \(existingClient.id.uuidString.prefix(8)))")
            } else {
                print("OrdersViewModel: Client '\(clientName)' not found, will be created automatically")
            }
        }
        
        var newOrder = Order(
            name: name, 
            clientName: clientName, 
            clientID: clientID, 
            clientEmail: clientEmail, 
            clientPhone: clientPhone, 
            clientICO: clientICO, 
            clientAddress: clientAddress, 
            location: location, 
            date: date, 
            duration: duration, 
            price: price, 
            deposit: deposit
        )
        newOrder.notes = notes
        
        orders.append(newOrder)
        print("OrdersViewModel: Order added, total orders: \(orders.count)")
        
        saveOrders()
        scheduleNotificationIfNeeded(for: newOrder)
        
        // Aktualizovat/vytvořit statistiky klienta
        clientsViewModel?.updateClientStatsFromOrder(newOrder, isDeleting: false)
    }
    
    private func updateClientStats(clientName: String, orderValue: Double) {
        guard !clientName.isEmpty else { return }
        
        // Zde by měla být reference na ClientsViewModel
        // Pro nyní necháme prázdné, bude implementováno později
        NotificationCenter.default.post(
            name: NSNotification.Name("UpdateClientStats"),
            object: nil,
            userInfo: ["clientName": clientName, "orderValue": orderValue]
        )
    }
    
    func updateOrderStatus(_ order: Order, status: OrderStatus) {
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index].status = status
            saveOrders()
            
            // Pokud je zakázka dokončena nebo zrušena, zruš notifikaci
            if status == .completed || status == .delivered || status == .cancelled {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [order.id.uuidString])
            }
        }
    }
    
    func updateOrderDeposit(_ order: Order, deposit: Double) {
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index].deposit = deposit
            saveOrders()
        }
    }
    
    func updateOrder(_ order: Order, notes: String) {
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index].notes = notes
            saveOrders()
        }
    }
    
    func updateCompleteOrder(_ order: Order) {
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index] = order
            saveOrders()
        }
    }
    
    func saveOrders() {
        do {
            let encodedOrders = try JSONEncoder().encode(orders)
            userDefaults.set(encodedOrders, forKey: ordersKey)
            userDefaults.synchronize()
            print("OrdersViewModel: Orders saved successfully.")
        } catch {
            print("OrdersViewModel: Failed to save orders: \(error)")
        }
    }
    
    private func loadOrders() {
        guard let data = userDefaults.data(forKey: ordersKey) else {
            print("OrdersViewModel: No saved orders found")
            return
        }
        
        do {
            orders = try JSONDecoder().decode([Order].self, from: data)
            print("OrdersViewModel: Successfully loaded \(orders.count) orders")
            
            // Přiřazení klientů podle jména, pokud chybí clientID
            migrateOrdersToUseClientID()
        } catch {
            print("OrdersViewModel: Failed to decode orders: \(error)")
        }
    }
    
    func scheduleNotificationIfNeeded(for order: Order) {
        // Naplánovat notifikaci pro nadcházející zakázku
        let content = UNMutableNotificationContent()
        content.title = "Připomínka zakázky"
        content.body = "Za hodinu začíná focení: \(order.name)"
        content.sound = UNNotificationSound.default
        
        // Naplánovat na hodinu před začátkem
        let triggerDate = Calendar.current.date(byAdding: .hour, value: -1, to: order.date)
        
        if let triggerDate = triggerDate, triggerDate > Date() {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(identifier: order.id.uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("OrdersViewModel: Failed to schedule notification: \(error)")
                } else {
                    print("OrdersViewModel: Notification scheduled for order: \(order.name)")
                }
            }
        }
    }
    
    func updateDepositStatus(_ order: Order, isPaid: Bool) {
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index].isDepositPaid = isPaid
            saveOrders()
            
            // Aktualizovat statistiky klienta
            clientsViewModel?.recalculateAllClientStats(from: orders)
        }
    }
    
    func updateFinalPaymentStatus(_ order: Order, isPaid: Bool) {
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index].isFinalPaymentPaid = isPaid
            saveOrders()
            
            // Aktualizovat statistiky klienta
            clientsViewModel?.recalculateAllClientStats(from: orders)
        }
    }
    
    func deleteOrder(_ order: Order) {
        print("OrdersViewModel: Deleting order: \(order.name)")
        print("OrdersViewModel: Order client: '\(order.clientName)' (ID: \(order.clientID?.uuidString ?? "nil"))")
        print("OrdersViewModel: Current orders count: \(orders.count)")
        
        // Smazat notifikaci před smazáním zakázky
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [order.id.uuidString])
        print("OrdersViewModel: Removed notification for order: \(order.id.uuidString)")
        
        // Najít index zakázky k smazání
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            print("OrdersViewModel: Found order at index \(index)")
            
            // Aktualizovat statistiky klienta před smazáním
            clientsViewModel?.updateClientStatsFromOrder(order, isDeleting: true)
            
            // Smazat zakázku
            orders.remove(at: index)
            print("OrdersViewModel: Remaining orders after deletion: \(orders.count)")
            
            // Uložit změny
            saveOrders()
            
            // Přepočítat statistiky klientů
            clientsViewModel?.recalculateAllClientStats(from: orders)
        } else {
            print("OrdersViewModel: Error - Order not found in orders array!")
        }
    }
    
    func deleteOrder(at offsets: IndexSet) {
        print("OrdersViewModel: Deleting orders at offsets: \(offsets)")
        print("OrdersViewModel: Current orders count: \(orders.count)")
        
        // Získat zakázky k smazání před jejich odstraněním
        let ordersToDelete = offsets.map { orders[$0] }
        print("OrdersViewModel: Orders to delete: \(ordersToDelete.map { "\($0.name) (client: \($0.clientName))" })")
        
        // Smazat notifikace pro všechny mazané zakázky
        let notificationIDs = ordersToDelete.map { $0.id.uuidString }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: notificationIDs)
        print("OrdersViewModel: Removed notifications for orders: \(notificationIDs)")
        
        // Aktualizovat statistiky klientů před smazáním
        for order in ordersToDelete {
            clientsViewModel?.updateClientStatsFromOrder(order, isDeleting: true)
        }
        
        // Smazat zakázky
        orders.remove(atOffsets: offsets)
        print("OrdersViewModel: Remaining orders after deletion: \(orders.count)")
        
        // Uložit změny
        saveOrders()
        
        // Přepočítat statistiky klientů
        clientsViewModel?.recalculateAllClientStats(from: orders)
    }
    
    func updateOrder(_ originalOrder: Order, with updatedOrder: Order) {
        print("OrdersViewModel: Updating order: \(originalOrder.name) -> \(updatedOrder.name)")
        
        // Smazat starou notifikaci
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [originalOrder.id.uuidString])
        print("OrdersViewModel: Removed old notification for order: \(originalOrder.id.uuidString)")
        
        if let index = orders.firstIndex(where: { $0.id == originalOrder.id }) {
            // Uložit původního klienta pro aktualizaci statistik
            let oldClientName = orders[index].clientName
            let oldClientID = orders[index].clientID
            
            // Místo přiřazení ID, které nejde, použijeme stávající order a aktualizujeme jeho vlastnosti
            var orderToUpdate = orders[index]
            orderToUpdate.name = updatedOrder.name
            orderToUpdate.clientName = updatedOrder.clientName
            orderToUpdate.clientEmail = updatedOrder.clientEmail
            orderToUpdate.clientPhone = updatedOrder.clientPhone
            orderToUpdate.clientICO = updatedOrder.clientICO
            orderToUpdate.clientAddress = updatedOrder.clientAddress
            orderToUpdate.location = updatedOrder.location
            orderToUpdate.date = updatedOrder.date
            orderToUpdate.duration = updatedOrder.duration
            orderToUpdate.price = updatedOrder.price
            orderToUpdate.deposit = updatedOrder.deposit
            orderToUpdate.notes = updatedOrder.notes
            
            // Aktualizovat clientID, pokud se změnilo jméno klienta
            if oldClientName != orderToUpdate.clientName {
                if let client = clientsViewModel?.getClient(by: orderToUpdate.clientName) {
                    orderToUpdate.clientID = client.id
                    print("OrdersViewModel: Updated clientID for client: \(orderToUpdate.clientName) to \(client.id.uuidString)")
                } else {
                    orderToUpdate.clientID = nil
                    print("OrdersViewModel: Reset clientID for new client name: \(orderToUpdate.clientName)")
                }
            }
            
            // Aktualizovat zakázku v seznamu
            orders[index] = orderToUpdate
            
            // Uložit změny
            saveOrders()
            
            // Naplánovat novou notifikaci
            scheduleNotificationIfNeeded(for: orders[index])
            
            // Aktualizovat statistiky
            if oldClientName != orderToUpdate.clientName || oldClientID != orderToUpdate.clientID {
                print("OrdersViewModel: Client changed, updating statistics")
                // Odečíst od starého klienta
                clientsViewModel?.updateClientStatsFromOrder(originalOrder, isDeleting: true)
                
                // Přičíst novému klientovi
                clientsViewModel?.updateClientStatsFromOrder(orderToUpdate, isDeleting: false)
            } else {
                print("OrdersViewModel: Recalculating all client statistics")
                // Kompletně přepočítat statistiky
                clientsViewModel?.recalculateAllClientStats(from: orders)
            }
        } else {
            print("OrdersViewModel: Error - Order not found for update!")
        }
    }
    
    func migrateOrdersToUseClientID() {
        for index in orders.indices {
            let order = orders[index]
            if order.clientID == nil, let client = clientsViewModel?.getClient(by: order.clientName) {
                orders[index].clientID = client.id
            }
        }
        saveOrders()
    }
    
    func getOrderHistory(for client: Client) -> [Order] {
        return clientsViewModel?.getOrderHistory(for: client, from: orders) ?? []
    }
}
