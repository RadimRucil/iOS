import SwiftUI
import MapKit

struct AddOrderForClientView: View {
    let client: Client
    @ObservedObject var ordersViewModel: OrdersViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    @AppStorage("defaultDeposit") private var defaultDeposit: Double = 0
    
    @State private var name = ""
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
    @State private var locationSuggestions: [MKLocalSearchCompletion] = []
    @State private var selectedTemplate: OrderTemplate? = nil
    
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
                // Informace o klientovi
                Section("Klient") {
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(client.name.prefix(2).uppercased())
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(client.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if !client.phone.isEmpty {
                                Text(client.phone)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                // Šablona
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
                
                // Detaily zakázky
                Section("Detaily zakázky") {
                    TextField("Název zakázky", text: $name)
                        .focused($isTextFieldFocused)
                    
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
                            .padding(.horizontal)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                        }
                    }
                    
                    DatePicker("Datum a čas", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .environment(\.locale, Locale(identifier: "cs_CZ"))
                    
                    HStack {
                        Text("Délka focení:")
                        Spacer()
                        Picker("Délka", selection: $duration) {
                            ForEach(durationOptions, id: \.self) { option in
                                if option == -1 {
                                    Text("Vlastní").tag(option)
                                } else {
                                    Text(formatDuration(option)).tag(option)
                                }
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: duration) { newValue in
                            showingCustomDuration = (newValue == -1)
                            if !showingCustomDuration {
                                customDuration = ""
                                customDurationMinutes = 0
                            }
                        }
                    }
                    
                    if showingCustomDuration {
                        HStack {
                            Text("Vlastní délka:")
                            Spacer()
                            TextField("Hodiny", text: $customDuration)
                                .keyboardType(.decimalPad)
                                .focused($isTextFieldFocused)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: customDuration) { newValue in
                                    if let hours = Double(newValue) {
                                        customDurationMinutes = Int(hours * 60)
                                    }
                                }
                            Text("h")
                        }
                    }
                }
                
                // Finanční údaje
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
                
                // Poznámky
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
                        
                        print("AddOrderForClientView: Saving order for existing client: \(client.name) (ID: \(client.id.uuidString.prefix(8)))")
                        
                        // Vytvořit zakázku s předem známým clientID
                        var newOrder = Order(
                            name: name,
                            clientName: client.name,
                            clientID: client.id,  // Klíčové - předat správné clientID
                            clientEmail: client.email,
                            clientPhone: client.phone,
                            clientICO: client.ico,
                            clientAddress: client.address,
                            location: location,
                            date: date,
                            duration: finalDuration,
                            price: priceValue,
                            deposit: depositValue
                        )
                        newOrder.notes = notes
                        
                        ordersViewModel.orders.append(newOrder)
                        ordersViewModel.saveOrders()
                        ordersViewModel.scheduleNotificationIfNeeded(for: newOrder)
                        
                        // Aktualizovat statistiky existujícího klienta
                        ordersViewModel.clientsViewModel?.updateClientStatsFromOrder(newOrder, isDeleting: false)
                        
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
                isTextFieldFocused = false
            }
            .onAppear {
                if deposit.isEmpty {
                    deposit = String(Int(defaultDeposit))
                }
            }
        }
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) h"
            } else {
                return "\(hours) h \(remainingMinutes) min"
            }
        }
    }
    
    private func applyTemplate(_ template: OrderTemplate) {
        name = template.name
        duration = template.duration
        price = String(Int(template.price))
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
    
    private func searchLocation(_ query: String) {
        guard !query.isEmpty else {
            locationSuggestions = []
            showingSuggestions = false
            return
        }
        
        showingSuggestions = !query.isEmpty
    }
}
