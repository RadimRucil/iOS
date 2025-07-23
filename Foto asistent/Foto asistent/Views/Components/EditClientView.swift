import SwiftUI
import MapKit

struct EditClientView: View {
    let originalClient: Client
    @ObservedObject var viewModel: ClientsViewModel
    let onClientUpdated: (Client) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var ico: String
    @State private var address: String
    @State private var notes: String
    @State private var addressSuggestions: [MKLocalSearchCompletion] = []
    @State private var showingAddressSuggestions = false
    @StateObject private var locationCoordinator = LocationSearchCoordinator()
    
    init(client: Client, viewModel: ClientsViewModel, onClientUpdated: @escaping (Client) -> Void) {
        self.originalClient = client
        self.viewModel = viewModel
        self.onClientUpdated = onClientUpdated
        
        _name = State(initialValue: client.name)
        _email = State(initialValue: client.email)
        _phone = State(initialValue: client.phone)
        _ico = State(initialValue: client.ico)
        _address = State(initialValue: client.address)
        _notes = State(initialValue: client.notes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Základní údaje") {
                    TextField("Jméno a příjmení", text: $name)
                        .focused($isTextFieldFocused)
                    
                    TextField("E-mail", text: $email)
                        .keyboardType(.emailAddress)
                        .focused($isTextFieldFocused)
                    
                    TextField("Telefon", text: $phone)
                        .keyboardType(.phonePad)
                        .focused($isTextFieldFocused)
                    
                    TextField("IČO", text: $ico)
                        .keyboardType(.numberPad)
                        .focused($isTextFieldFocused)
                    
                    TextField("Adresa", text: $address)
                        .focused($isTextFieldFocused)
                        .onChange(of: address) { newValue in
                            handleAddressChange(newValue)
                        }
                    
                    if showingAddressSuggestions && !addressSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(addressSuggestions.prefix(5), id: \.self) { suggestion in
                                Button(action: {
                                    selectAddress(suggestion)
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
                }
                
                Section("Poznámky") {
                    TextField("Poznámky ke klientovi", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
                }
            }
            .navigationTitle("Upravit klienta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zrušit") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Uložit") {
                        updateClient()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
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
        }
        .onAppear {
            locationCoordinator.setupCompleter()
        }
    }
    
    private func updateClient() {
        var updatedClient = originalClient
        updatedClient.name = name
        updatedClient.email = email
        updatedClient.phone = phone
        updatedClient.ico = ico
        updatedClient.address = address
        updatedClient.notes = notes
        
        viewModel.updateClient(updatedClient)
        onClientUpdated(updatedClient)
    }
    
    private func handleAddressChange(_ newValue: String) {
        let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedValue.isEmpty {
            searchAddress(trimmedValue)
        } else {
            addressSuggestions = []
            showingAddressSuggestions = false
        }
    }
    
    private func searchAddress(_ query: String) {
        guard !query.isEmpty else {
            addressSuggestions = []
            showingAddressSuggestions = false
            return
        }
        
        locationCoordinator.search(query: query)
        showingAddressSuggestions = true
    }
    
    private func selectAddress(_ suggestion: MKLocalSearchCompletion) {
        address = suggestion.title + (suggestion.subtitle.isEmpty ? "" : ", " + suggestion.subtitle)
        showingAddressSuggestions = false
        addressSuggestions = []
    }
}
