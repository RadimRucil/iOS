import SwiftUI

struct UpcomingOrdersView: View {
    @EnvironmentObject var viewModel: OrdersViewModel
    @State private var showingAddOrder = false
    @State private var selectedOrder: Order?
    
    var upcomingOrders: [Order] {
        viewModel.orders.filter { order in
            order.status == .planned || order.status == .inProgress
        }.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(upcomingOrders) { order in
                    OrderRowView(order: order, showWeather: true) {
                        selectedOrder = order
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }
                .onDelete(perform: deleteOrder)
            }
            .listStyle(PlainListStyle())
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Nadcházející zakázky")
            .toolbar {
                Button("Přidat") {
                    showingAddOrder = true
                }
            }
            .sheet(isPresented: $showingAddOrder) {
                AddOrderView(viewModel: viewModel)
            }
            .sheet(item: $selectedOrder) { order in
                OrderDetailView(order: order, viewModel: viewModel)
            }
        }
    }
    
    private func deleteOrder(at offsets: IndexSet) {
        // Převést offsety z filtrovaného seznamu na offsety v originálním seznamu
        let ordersToDelete = offsets.map { upcomingOrders[$0] }
        
        for order in ordersToDelete {
            viewModel.deleteOrder(order)
        }
    }
}
