import SwiftUI

struct ClientsView: View {
    @EnvironmentObject var clientsViewModel: ClientsViewModel
    @EnvironmentObject var ordersViewModel: OrdersViewModel
    @State private var showingAddClient = false
    @State private var selectedClient: Client?
    @State private var searchText = ""
    
    var filteredClients: [Client] {
        if searchText.isEmpty {
            return clientsViewModel.clients.sorted { $0.name < $1.name }
        } else {
            return clientsViewModel.clients.filter { client in
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
                    ClientRowView(client: client) {
                        selectedClient = client
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                .onDelete(perform: deleteClients)
            }
            .listStyle(PlainListStyle())
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Klienti")
            .searchable(text: $searchText, prompt: "Hledat klienty")
            .toolbar {
                Button("Přidat") {
                    showingAddClient = true
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddClientView(viewModel: clientsViewModel)
            }
            .sheet(item: $selectedClient) { client in
                ClientDetailView(client: client, clientsViewModel: clientsViewModel, ordersViewModel: ordersViewModel)
            }
        }
    }
    
    private func deleteClients(at offsets: IndexSet) {
        let clientsToDelete = offsets.map { filteredClients[$0] }
        for client in clientsToDelete {
            clientsViewModel.deleteClient(client)
        }
    }
}
