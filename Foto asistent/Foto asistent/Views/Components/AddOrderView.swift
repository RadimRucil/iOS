import SwiftUI
import MapKit

struct AddOrderView: View {
    @ObservedObject var viewModel: OrdersViewModel
    @EnvironmentObject var clientsViewModel: ClientsViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    @AppStorage("defaultDeposit") private var defaultDeposit: Double = 0
    
    @State private var name = ""
    @State private var clientName = ""
    @State private var clientEmail = ""
    @State private var clientPhone = ""
    @State private var clientICO = ""
    @State private var clientAddress = ""
    @State private var location = ""
    @State private var date = Date()
    @State private var duration = 60
    @State private var customDuration = ""
    @State private var showingCustomDuration = false
    @State private var customDurationMinutes = 0
    @State private var price = ""
    @State private var deposit = ""
    @State private var notes = ""
    @State private var showingSuggestions = false
    @State private var showingAddressSuggestions = false
    @State private var locationSuggestions: [MKLocalSearchCompletion] = []
    @State private var addressSuggestions: [MKLocalSearchCompletion] = []
    @State private var selectedTemplate: OrderTemplate? = nil
    @State private var filteredClients: [Client] = []
    @State private var showSuggestions: Bool = false
    
    private let templates = OrderTemplate.defaultTemplates
    private let durationOptions = [30, 60, 90, 120, 180, 240, 300, 360, 480, 600, 720, -1]
    
    var priceValue: Double {
        Double(price) ?? 0
    }
    
    var depositValue: Double {
        Double(deposit) ?? 0
    }
    
    var remainingAmount: Double {
        priceValue - depositValue
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Šablona") {
                    Picker("Vybrat šablonu", selection: $selectedTemplate) {
                        Text("Bez šablony").tag(nil as OrderTemplate?)
                        ForEach(templates) { template in
                            Text(template.name).tag(template as OrderTemplate?)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedTemplate) { template in
                        if let template = template {
                            applyTemplate(template)
                        } else {
                            clearFormToDefaults()
                        }
                    }
                }
                
                Section("Detaily zakázky") {
                    TextField("Název zakázky", text: $name)
                        .focused($isTextFieldFocused)
                    TextField("Jméno klienta", text: $clientName)
                        .focused($isTextFieldFocused)
                        .onChange(of: clientName) { newValue in
                            filterClients(by: newValue)
                        }
                        .onTapGesture {
                            showSuggestions = true
                        }
                    
                    if showSuggestions && !filteredClients.isEmpty {
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
                        .onChange(of: clientAddress) { newValue in
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
                            .onChange(of: location) { newValue in
                                searchLocation(newValue)
                            }
                        
                        if showingSuggestions && !locationSuggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(locationSuggestions.prefix(5), id: \.self) { suggestion in
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
                                    
                                    if suggestion != locationSuggestions.prefix(5).last {
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
                            if newValue != -1 {
                                customDuration = ""
                                customDurationMinutes = 0
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
            .navigationTitle("Nová zakázka")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zrušit") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Uložit") {
                        let finalDuration = showingCustomDuration ? customDurationMinutes : duration
                        
                        print("AddOrderView: Saving order with client: '\(clientName)'")
                        
                        viewModel.addOrder(
                            name: name,
                            clientName: clientName,
                            clientEmail: clientEmail,
                            clientPhone: clientPhone,
                            clientICO: clientICO,
                            clientAddress: clientAddress,
                            location: location,
                            date: date,
                            duration: finalDuration,
                            price: priceValue,
                            deposit: depositValue,
                            notes: notes
                        )
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
            .onAppear {
                // Při prvním zobrazení nastavit výchozí zálohu
                if deposit.isEmpty {
                    deposit = String(Int(defaultDeposit))
                }
            }
        }
    }
    
    private func searchLocation(_ query: String) {
        guard !query.isEmpty else {
            locationSuggestions = []
            showingSuggestions = false
            return
        }
        
        let completer = MKLocalSearchCompleter()
        completer.queryFragment = query
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.75, longitude: 15.5),
            span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.locationSuggestions = completer.results
            self.showingSuggestions = !completer.results.isEmpty
        }
    }
    
    private func searchAddress(_ query: String) {
        guard !query.isEmpty else {
            addressSuggestions = []
            showingAddressSuggestions = false
            return
        }
        
        // Pro demo účely - v produkční verzi by zde byla implementace MKLocalSearchCompleter
        showingAddressSuggestions = !query.isEmpty
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
    
    private func applyTemplate(_ template: OrderTemplate) {
        name = template.name
        duration = template.duration
        price = String(Int(template.price))
        // Použít zálohu ze šablony, ale pokud je 0, použít výchozí ze nastavení
        deposit = String(Int(template.deposit > 0 ? template.deposit : defaultDeposit))
        showingCustomDuration = !durationOptions.dropLast().contains(template.duration)
        if showingCustomDuration {
            customDuration = String(format: "%.1f", Double(template.duration) / 60.0)
            customDurationMinutes = template.duration
        }
    }
    
    private func clearFormToDefaults() {
        name = ""
        duration = 60
        price = ""
        deposit = String(Int(defaultDeposit))
        showingCustomDuration = false
        customDuration = ""
        customDurationMinutes = 0
    }
    
    private func filterClients(by query: String) {
        if query.isEmpty {
            filteredClients = []
            showSuggestions = false
        } else {
            filteredClients = clientsViewModel.clients.filter {
                $0.name.lowercased().contains(query.lowercased())
            }
            showSuggestions = true
        }
    }
    
    private func selectClient(_ client: Client) {
        clientName = client.name
        filteredClients = []
        showSuggestions = false
    }
}

