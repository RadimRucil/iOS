import SwiftUI
import MapKit

struct EditOrderView: View {
    let originalOrder: Order
    @ObservedObject var viewModel: OrdersViewModel
    let onOrderUpdated: (Order) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var name: String
    @State private var clientName: String
    @State private var clientEmail: String
    @State private var clientPhone: String
    @State private var clientICO: String
    @State private var clientAddress: String
    @State private var location: String
    @State private var date: Date
    @State private var duration: Int
    @State private var customDuration = ""
    @State private var showingCustomDuration = false
    @State private var customDurationMinutes = 0
    @State private var price: String
    @State private var deposit: String
    @State private var notes: String
    @State private var showingSuggestions = false
    @State private var locationSuggestions: [MKLocalSearchCompletion] = []
    @State private var addressSuggestions: [MKLocalSearchCompletion] = []
    @State private var showingAddressSuggestions = false
    @StateObject private var locationCoordinator = LocationSearchCoordinator()
    
    @EnvironmentObject var clientsViewModel: ClientsViewModel
    @State private var filteredClients: [Client] = []
    @State private var showClientSuggestions: Bool = false
    
    private let durationOptions = [30, 60, 90, 120, 180, 240, 300, 360, 480, 600, 720, -1]
    
    var priceValue: Double { Double(price) ?? 0 }
    var depositValue: Double { Double(deposit) ?? 0 }
    var remainingAmount: Double { priceValue - depositValue }
    
    init(order: Order, viewModel: OrdersViewModel, onOrderUpdated: @escaping (Order) -> Void) {
        self.originalOrder = order
        self.viewModel = viewModel
        self.onOrderUpdated = onOrderUpdated
        
        _name = State(initialValue: order.name)
        _clientName = State(initialValue: order.clientName)
        _clientEmail = State(initialValue: order.clientEmail)
        _clientPhone = State(initialValue: order.clientPhone)
        _clientICO = State(initialValue: order.clientICO)
        _clientAddress = State(initialValue: order.clientAddress)
        _location = State(initialValue: order.location)
        _date = State(initialValue: order.date)
        
        // Zkontroluj, zda je duration v seznamu možností
        let standardDurationOptions = [30, 60, 90, 120, 180, 240, 300, 360, 480, 600]
        if standardDurationOptions.contains(order.duration) {
            _duration = State(initialValue: order.duration)
            _showingCustomDuration = State(initialValue: false)
            _customDuration = State(initialValue: "")
            _customDurationMinutes = State(initialValue: 0)
        } else {
            _duration = State(initialValue: -1)
            _showingCustomDuration = State(initialValue: true)
            _customDuration = State(initialValue: String(format: "%.1f", Double(order.duration) / 60.0))
            _customDurationMinutes = State(initialValue: order.duration)
        }
        
        _price = State(initialValue: String(Int(order.price)))
        _deposit = State(initialValue: String(Int(order.deposit)))
        _notes = State(initialValue: order.notes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Detaily zakázky") {
                    TextField("Název zakázky", text: $name)
                        .focused($isTextFieldFocused)
                    TextField("Jméno klienta", text: $clientName)
                        .focused($isTextFieldFocused)
                        .onChange(of: clientName) { newValue in
                            filterClients(by: newValue)
                        }
                        .onTapGesture {
                            showClientSuggestions = true
                        }
                    
                    if showClientSuggestions && !filteredClients.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(filteredClients, id: \.id) { client in
                                    Button(action: {
                                        selectClient(client)
                                    }) {
                                        Text(client.name)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .frame(maxHeight: 150)
                    }
                    
                    TextField("E-mail klienta", text: $clientEmail)
                        .keyboardType(.emailAddress)
                        .focused($isTextFieldFocused)
                    TextField("Telefon klienta", text: $clientPhone)
                        .keyboardType(.phonePad)
                        .focused($isTextFieldFocused)
                    TextField("IČO klienta", text: $clientICO)
                        .keyboardType(.numberPad)
                        .focused($isTextFieldFocused)
                    TextField("Adresa klienta", text: $clientAddress)
                        .focused($isTextFieldFocused)
                        .onChange(of: clientAddress) { oldValue, newValue in
                            searchAddress(newValue)
                        }
                    
                    if showingAddressSuggestions && !addressSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(addressSuggestions.prefix(5), id: \.self) { suggestion in
                                Button(action: {
                                    clientAddress = suggestion.title + (suggestion.subtitle.isEmpty ? "" : ", " + suggestion.subtitle)
                                    showingAddressSuggestions = false
                                    addressSuggestions = []
                                }) {
                                    VStack(alignment: .leading) {
                                        Text(suggestion.title)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        if !suggestion.subtitle.isEmpty {
                                            Text(suggestion.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if suggestion != addressSuggestions.prefix(5).last {
                                    Divider()
                                }
                            }
                        }
                        .padding(.horizontal)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    }
                    
                    VStack(alignment: .leading) {
                        TextField("Lokace", text: $location)
                            .focused($isTextFieldFocused)
                            .onChange(of: location) { oldValue, newValue in
                                locationCoordinator.search(query: newValue)
                            }
                        
                        if !locationCoordinator.searchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(locationCoordinator.searchResults.prefix(5), id: \.self) { suggestion in
                                    Button(action: {
                                        location = suggestion.title + (suggestion.subtitle.isEmpty ? "" : ", " + suggestion.subtitle)
                                        showingSuggestions = false
                                        locationSuggestions = []
                                    }) {
                                        VStack(alignment: .leading) {
                                            Text(suggestion.title)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            if !suggestion.subtitle.isEmpty {
                                                Text(suggestion.subtitle)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if suggestion != locationCoordinator.searchResults.prefix(5).last {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    DatePicker("Datum a čas", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .environment(\.locale, Locale(identifier: "cs_CZ"))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Délka focení", selection: $duration) {
                            ForEach(durationOptions, id: \.self) { minutes in
                                if minutes == -1 {
                                    Text("Jiné").tag(minutes)
                                } else {
                                    Text(formatDuration(minutes)).tag(minutes)
                                }
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: duration) { newValue in
                            showingCustomDuration = (newValue == -1)
                            if newValue == -1 && customDuration.isEmpty {
                                customDuration = String(format: "%.1f", Double(originalOrder.duration) / 60.0)
                                customDurationMinutes = originalOrder.duration
                            } else if newValue != -1 {
                                customDuration = ""
                                customDurationMinutes = 0
                            }
                        }
                        .onAppear {
                            if !durationOptions.dropLast().contains(duration) {
                                duration = -1
                                showingCustomDuration = true
                                customDuration = String(format: "%.1f", Double(originalOrder.duration) / 60.0)
                                customDurationMinutes = originalOrder.duration
                            }
                        }
                        
                        if showingCustomDuration {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Vlastní délka focení")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    TextField("Počet hodin", text: $customDuration)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .focused($isTextFieldFocused)
                                        .onSubmit {
                                            updateDurationFromCustomInput()
                                        }
                                        .onChange(of: customDuration) { _ in
                                            // Pouze validace, neaktualizujeme duration při psaní
                                        }
                                    Text("hodin")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Section("Finanční údaje") {
                    HStack {
                        Text("Celková cena:")
                            .foregroundColor(.primary)
                        Spacer()
                        TextField("0", text: $price)
                            .keyboardType(.numberPad)
                            .focused($isTextFieldFocused)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                        Text("Kč")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Záloha:")
                            .foregroundColor(.primary)
                        Spacer()
                        TextField("0", text: $deposit)
                            .keyboardType(.numberPad)
                            .focused($isTextFieldFocused)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                        Text("Kč")
                            .foregroundColor(.secondary)
                    }
                    
                    if priceValue > 0 {
                        HStack {
                            Text("K doplacení:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(remainingAmount)) Kč")
                                .fontWeight(.semibold)
                                .foregroundColor(remainingAmount > 0 ? .orange : .green)
                        }
                    }
                }
                
                Section("Poznámky") {
                    TextField("Poznámky k zakázce", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
                }
            }
            .navigationTitle("Upravit zakázku")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zrušit") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Uložit") {
                        // Před uložením aktualizuj duration z custom inputu
                        if showingCustomDuration {
                            updateDurationFromCustomInput()
                        }
                        updateOrder()
                        dismiss()
                    }
                    .disabled(name.isEmpty || priceValue <= 0)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Hotovo") {
                        isTextFieldFocused = false
                    }
                }
            }
            .onTapGesture {
                showingSuggestions = false
                showingAddressSuggestions = false
                isTextFieldFocused = false
            }
        }
    }
    
    private func searchLocation(_ query: String) {
        locationCoordinator.searchLocation(query)
        showingSuggestions = !query.isEmpty
        
        // Sledovat výsledky z koordinátoru
        locationSuggestions = locationCoordinator.searchResults
    }
    
    private func searchAddress(_ query: String) {
        guard !query.isEmpty else {
            addressSuggestions = []
            showingAddressSuggestions = false
            return
        }
        
        let searchCompleter = MKLocalSearchCompleter()
        searchCompleter.queryFragment = query
        searchCompleter.resultTypes = .address
        
        // Pro plnou funkcionalität by bylo potřeba implementovat MKLocalSearchCompleterDelegate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !query.isEmpty {
                self.showingAddressSuggestions = true
            }
        }
    }
    
    private func updateOrder() {
        // Vytvořit aktualizovanou zakázku
        var updatedOrder = originalOrder
        updatedOrder.name = name
        updatedOrder.clientName = clientName
        updatedOrder.clientEmail = clientEmail
        updatedOrder.clientPhone = clientPhone
        updatedOrder.clientICO = clientICO
        updatedOrder.clientAddress = clientAddress
        updatedOrder.location = location
        updatedOrder.date = date
        updatedOrder.duration = showingCustomDuration ? customDurationMinutes : duration
        updatedOrder.price = priceValue
        updatedOrder.deposit = depositValue
        updatedOrder.notes = notes
        
        // Použít novou komplexní metodu pro aktualizaci
        viewModel.updateOrder(originalOrder, with: updatedOrder)
        
        // Informovat volající komponentu
        onOrderUpdated(updatedOrder)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 && remainingMinutes > 0 {
            return "\(hours)h \(remainingMinutes)min"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)min"
        }
    }
    
    private func updateDurationFromCustomInput() {
        if let hours = Double(customDuration.replacingOccurrences(of: ",", with: ".")), hours > 0 {
            customDurationMinutes = Int(hours * 60)
        }
    }
    
    private func filterClients(by query: String) {
        if query.isEmpty {
            filteredClients = []
            showClientSuggestions = false
        } else {
            filteredClients = clientsViewModel.clients.filter {
                $0.name.lowercased().contains(query.lowercased())
            }
            showClientSuggestions = true
        }
    }
    
    private func selectClient(_ client: Client) {
        clientName = client.name
        filteredClients = []
        showClientSuggestions = false
    }
}

