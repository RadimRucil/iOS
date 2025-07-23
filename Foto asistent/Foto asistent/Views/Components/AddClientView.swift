import SwiftUI

struct AddClientView: View {
    @ObservedObject var viewModel: ClientsViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var ico = ""
    @State private var address = ""
    @State private var notes = ""
    
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
                }
                
                Section("Poznámky") {
                    TextField("Poznámky ke klientovi", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
                }
            }
            .navigationTitle("Nový klient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zrušit") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Uložit") {
                        let client = Client(name: name, email: email, phone: phone, ico: ico, address: address, notes: notes)
                        viewModel.addClient(client)
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
    }
}
