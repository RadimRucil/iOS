import SwiftUI
import MapKit

struct OrderDetailView: View {
    @State private var order: Order
    @ObservedObject var viewModel: OrdersViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditDeposit = false
    @State private var showingEditNotes = false
    @State private var showingEditOrder = false
    @State private var newDeposit = ""
    @State private var newNotes = ""
    @State private var mapRegion = MKCoordinateRegion()
    @State private var locationFound = false
    @StateObject private var weatherService = WeatherService()
    @State private var showingPhoneOptions = false
    @StateObject private var messageService = MessageService()
    @State private var showingDeleteAlert = false
    
    init(order: Order, viewModel: OrdersViewModel) {
        self._order = State(initialValue: order)
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Sekce s detaily zakázky
                    Section {
                        // Mapa lokace
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Lokace")
                                .font(.headline)
                            
                            if locationFound {
                                Map(coordinateRegion: .constant(mapRegion))
                                    .frame(height: 150)
                                    .cornerRadius(12)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 150)
                                    .cornerRadius(12)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "map")
                                                .font(.title)
                                                .foregroundColor(.gray)
                                            Text("Hledám lokaci...")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    )
                            }
                            
                            Text(order.location)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Weather Widget - pouze pro nadcházející zakázky
                            if !order.location.isEmpty && (order.status == .planned || order.status == .inProgress) {
                                HStack {
                                    if weatherService.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Načítám počasí...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else if let weather = weatherService.weatherData {
                                        Image(systemName: weather.icon)
                                            .font(.title2)
                                            .foregroundColor(.blue)
                                        
                                        Text("\(Int(weather.temperature))°C")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        
                                        Text("pro \(order.date.formatted(.dateTime.day().month().year()))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .environment(\.locale, Locale(identifier: "cs_CZ"))
                                    }
                                    // Pokud weatherService.weatherData je nil a není loading, neukáže se nic
                                    Spacer()
                                }
                                .padding(.top, 4)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Detaily zakázky")
                                    .font(.headline)
                                Spacer()
                                Button("Upravit") {
                                    showingEditOrder = true
                                }
                                .foregroundColor(.blue)
                            }
                            
                            InfoRow(label: "Název", value: order.name)
                            InfoRow(label: "Klient", value: order.clientName.isEmpty ? "Není zadáno" : order.clientName)
                            if !order.clientEmail.isEmpty {
                                HStack {
                                    Text("E-mail:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button(order.clientEmail) {
                                        let subject = order.name
                                        let body = messageService.generateReminderMessage(for: order)
                                        messageService.sendEmail(to: order.clientEmail, subject: subject, body: body)
                                    }
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                }
                            }
                            if !order.clientPhone.isEmpty {
                                HStack {
                                    Text("Telefon:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button(order.clientPhone) {
                                        showingPhoneOptions = true
                                    }
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                                }
                            }
                            if !order.clientICO.isEmpty {
                                InfoRow(label: "IČO", value: order.clientICO)
                            }
                            if !order.clientAddress.isEmpty {
                                InfoRow(label: "Adresa", value: order.clientAddress)
                            }
                            InfoRow(label: "Datum", value: "\(order.date.formatted(date: .abbreviated, time: .omitted)) \(order.date.formatted(date: .omitted, time: .shortened))")
                            InfoRow(label: "Délka focení", value: order.formattedDuration)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Finanční údaje")
                                .font(.headline)
                            
                            InfoRow(label: "Celková cena", value: "\(Int(order.price).formatted(.number.locale(Locale(identifier: "cs_CZ")))) Kč")
                            
                            HStack {
                                Text("Záloha:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(order.deposit).formatted(.number.locale(Locale(identifier: "cs_CZ")))) Kč")
                                    .fontWeight(.medium)
                                    .foregroundColor(order.deposit > 0 ? (order.isDepositPaid ? .green : .red) : .primary)
                            }
                            
                            HStack {
                                Text("K doplacení:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(order.remainingAmount).formatted(.number.locale(Locale(identifier: "cs_CZ")))) Kč")
                                    .fontWeight(.medium)
                                    .foregroundColor(order.remainingAmount > 0 ? (order.isFinalPaymentPaid ? .green : .red) : .green)
                            }
                            
                            if order.deposit > 0 {
                                HStack {
                                    Text("Záloha zaplacena:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Toggle("", isOn: .init(
                                        get: { order.isDepositPaid },
                                        set: { newValue in
                                            viewModel.updateDepositStatus(order, isPaid: newValue)
                                            updateLocalOrder()
                                        }
                                    ))
                                    .toggleStyle(SwitchToggleStyle())
                                    .labelsHidden()
                                }
                            }
                            
                            if order.remainingAmount > 0 {
                                HStack {
                                    Text("Doplaceno:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Toggle("", isOn: .init(
                                        get: { order.isFinalPaymentPaid },
                                        set: { newValue in
                                            viewModel.updateFinalPaymentStatus(order, isPaid: newValue)
                                            updateLocalOrder()
                                        }
                                    ))
                                    .toggleStyle(SwitchToggleStyle())
                                    .labelsHidden()
                                }
                            }
                            
                            Button("Upravit zálohu") {
                                newDeposit = String(Int(order.deposit))
                                showingEditDeposit = true
                            }
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Poznámky")
                                .font(.headline)
                            
                            if order.notes.isEmpty {
                                Text("Žádné poznámky")
                                    .foregroundColor(.secondary)
                                    .italic()
                            } else {
                                Text(order.notes)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Stav zakázky")
                                .font(.headline)
                            
                            Menu {
                                ForEach(OrderStatus.allCases, id: \.self) { status in
                                    Button(status.rawValue) {
                                        viewModel.updateOrderStatus(order, status: status)
                                        updateLocalOrder()
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(order.status.rawValue)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Ostatní obsah
                    
                    // Na konec přidat tlačítka
                    VStack(spacing: 12) {
                        Button(action: {
                            showingEditOrder = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Upravit zakázku")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Smazat zakázku")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("Detail zakázky")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hotovo") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                searchLocation()
                updateLocalOrder()
                if !order.location.isEmpty && (order.status == .planned || order.status == .inProgress) {
                    weatherService.fetchWeather(for: order.location, date: order.date)
                }
            }
            .alert("Upravit zálohu", isPresented: $showingEditDeposit) {
                TextField("Záloha", text: $newDeposit)
                    .keyboardType(.numberPad)
                Button("Zrušit", role: .cancel) { 
                    newDeposit = ""
                }
                Button("Uložit") {
                    if let depositValue = Double(newDeposit) {
                        viewModel.updateOrderDeposit(order, deposit: depositValue)
                        updateLocalOrder()
                    }
                    newDeposit = ""
                }
            } message: {
                Text("Zadejte novou výši zálohy v Kč")
            }
            .sheet(isPresented: $showingEditNotes) {
                NavigationView {
                    VStack {
                        TextEditor(text: $newNotes)
                            .padding()
                        Spacer()
                    }
                    .navigationTitle("Poznámky")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Zrušit") {
                                showingEditNotes = false
                            }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Uložit") {
                                viewModel.updateOrder(order, notes: newNotes)
                                updateLocalOrder()
                                showingEditNotes = false
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingEditOrder) {
                EditOrderView(order: order, viewModel: viewModel) { updatedOrder in
                    order = updatedOrder
                }
            }
            .actionSheet(isPresented: $showingPhoneOptions) {
                ActionSheet(
                    title: Text("Kontaktovat klienta"),
                    message: Text(!order.clientName.isEmpty ? "\(order.clientName)\n\(order.clientPhone)" : order.clientPhone),
                    buttons: [
                        .default(Text("Volat")) {
                            if let url = URL(string: "tel:\(order.clientPhone)") {
                                UIApplication.shared.open(url)
                            }
                        },
                        .default(Text("Napsat zprávu")) {
                            let message = messageService.generateReminderMessage(for: order)
                            messageService.sendSMS(to: order.clientPhone, message: message)
                        },
                        .cancel(Text("Zrušit"))
                    ]
                )
            }
            .alert("Smazat zakázku", isPresented: $showingDeleteAlert) {
                Button("Zrušit", role: .cancel) { }
                Button("Smazat", role: .destructive) {
                    viewModel.deleteOrder(order)
                    dismiss()
                }
            } message: {
                Text("Opravdu chcete smazat zakázku \"\(order.name)\"? Tuto akci nelze vrátit zpět.")
            }
        }
    }
    
    private func updateLocalOrder() {
        if let updatedOrder = viewModel.orders.first(where: { $0.id == order.id }) {
            order = updatedOrder
        }
    }
    
    private func searchLocation() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(order.location) { placemarks, error in
            if let placemark = placemarks?.first,
               let location = placemark.location {
                DispatchQueue.main.async {
                    mapRegion = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                    locationFound = true
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .foregroundColor(.primary)    }
}

struct ClientOrderHistoryView: View {
    let client: Client
    @ObservedObject var viewModel: OrdersViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Historie zakázek")
                .font(.headline)

            let orders = viewModel.getOrderHistory(for: client)

            if orders.isEmpty {
                Text("Žádné zakázky k zobrazení.")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(orders) { order in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(order.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(order.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

struct ClientOrderListView: View {
    let client: Client
    @ObservedObject var viewModel: OrdersViewModel
    @State private var selectedOrder: Order?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Historie zakázek")
                .font(.headline)

            let orders = viewModel.getOrderHistory(for: client)

            if orders.isEmpty {
                Text("Žádné zakázky k zobrazení.")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                List(orders) { order in
                    Button(action: {
                        selectedOrder = order
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(order.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(order.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(order.status.rawValue)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .sheet(item: $selectedOrder) { order in
                    OrderDetailView(order: order, viewModel: viewModel)
                }
            }
        }
        .padding()
    }
}

