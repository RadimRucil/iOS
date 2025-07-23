import SwiftUI

struct ClientDetailView: View {
    @State private var client: Client
    @ObservedObject var clientsViewModel: ClientsViewModel
    @ObservedObject var ordersViewModel: OrdersViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditClient = false
    @State private var showingPhoneOptions = false
    @State private var showingAddOrder = false
    @StateObject private var messageService = MessageService()
    
    init(client: Client, clientsViewModel: ClientsViewModel, ordersViewModel: OrdersViewModel) {
        self._client = State(initialValue: client)
        self.clientsViewModel = clientsViewModel
        self.ordersViewModel = ordersViewModel
    }
    
    var clientOrders: [Order] {
        ordersViewModel.orders.filter { order in
            if let clientID = order.clientID {
                return clientID == client.id
            } else {
                return order.clientName.lowercased() == client.name.lowercased()
            }
        }.sorted { $0.date > $1.date }
    }
    
    private var unpaidAmount: Double {
        clientsViewModel.getUnpaidAmount(for: client, from: ordersViewModel.orders)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Avatar a základní info
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(client.name.prefix(2).uppercased())
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            )
                        
                        Text(client.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        // Tlačítko pro novou zakázku
                        Button(action: {
                            showingAddOrder = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Nová zakázka")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.top, 8)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(client.totalOrders)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                Text("Zakázek")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(Int(client.totalSpent).formatted(.number.locale(Locale(identifier: "cs_CZ")))) Kč")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("Zaplaceno")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if unpaidAmount > 0 {
                                VStack {
                                    Text("\(Int(unpaidAmount).formatted(.number.locale(Locale(identifier: "cs_CZ")))) Kč")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                    Text("K doplacení")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Kontaktní údaje
                    if !client.email.isEmpty || !client.phone.isEmpty || !client.address.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kontaktní údaje")
                                .font(.headline)
                            
                            if !client.email.isEmpty {
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.blue)
                                    Button(client.email) {
                                        let subject = "Ohledně fotografických služeb"
                                        let body = messageService.generateReminderMessage(for: client)
                                        messageService.sendEmail(to: client.email, subject: subject, body: body)
                                    }
                                    .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                            
                            if !client.phone.isEmpty {
                                HStack {
                                    Image(systemName: "phone")
                                        .foregroundColor(.green)
                                    Button(client.phone) {
                                        showingPhoneOptions = true
                                    }
                                    .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                            
                            if !client.ico.isEmpty {
                                HStack {
                                    Image(systemName: "building.2")
                                        .foregroundColor(.purple)
                                    Text("IČO: \(client.ico)")
                                    Spacer()
                                }
                            }
                            
                            if !client.address.isEmpty {
                                HStack {
                                    Image(systemName: "location")
                                        .foregroundColor(.orange)
                                    Text(client.address)
                                    Spacer()
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Poznámky
                    if !client.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Poznámky")
                                .font(.headline)
                            
                            Text(client.notes)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Historie zakázek
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Historie zakázek (\(clientOrders.count))")
                            .font(.headline)
                        
                        if clientOrders.isEmpty {
                            Text("Žádné zakázky")
                                .foregroundColor(.secondary)
                                .italic()
                                .padding()
                        } else {
                            ForEach(clientOrders) { order in
                                OrderRowView(order: order, showWeather: false) {
                                    // Můžeme přidat navigaci k detailu zakázky
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Detail klienta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hotovo") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Upravit") {
                        showingEditClient = true
                    }
                }
            }
            .sheet(isPresented: $showingEditClient) {
                EditClientView(client: client, viewModel: clientsViewModel) { updatedClient in
                    client = updatedClient
                }
            }
            .actionSheet(isPresented: $showingPhoneOptions) {
                ActionSheet(
                    title: Text("Kontaktovat klienta"),
                    message: Text("\(client.name)\n\(client.phone)"),
                    buttons: [
                        .default(Text("Volat")) {
                            if let url = URL(string: "tel:\(client.phone)") {
                                UIApplication.shared.open(url)
                            }
                        },
                        .default(Text("Napsat zprávu")) {
                            let message = messageService.generateReminderMessage(for: client)
                            messageService.sendSMS(to: client.phone, message: message)
                        },
                        .cancel(Text("Zrušit"))
                    ]
                )
            }
            .sheet(isPresented: $showingAddOrder) {
                AddOrderForClientView(client: client, ordersViewModel: ordersViewModel)
            }
        }
    }
}
