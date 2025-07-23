import SwiftUI

struct ClientSelectionView: View {
    let clients: [Client]
    @Binding var selectedClient: Client?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredClients: [Client] {
        if searchText.isEmpty {
            return clients.sorted { $0.name < $1.name }
        } else {
            return clients.filter { client in
                client.name.localizedCaseInsensitiveContains(searchText) ||
                client.email.localizedCaseInsensitiveContains(searchText) ||
                client.phone.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.name < $1.name }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredClients) { client in
                    Button(action: {
                        selectedClient = client
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(client.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                if !client.email.isEmpty {
                                    Text(client.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if !client.phone.isEmpty {
                                    Text(client.phone)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedClient?.id == client.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Vybrat klienta")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Hledat klienty")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zrušit") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Nový klient") {
                        selectedClient = nil
                        dismiss()
                    }
                }
            }
        }
    }
}
