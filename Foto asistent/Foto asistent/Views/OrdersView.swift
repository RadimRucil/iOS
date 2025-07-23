import SwiftUI

struct OrdersView: View {
    @StateObject private var viewModel = OrdersViewModel()
    @State private var showingAddOrder = false
    @State private var selectedOrder: Order?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.orders) { order in
                        OrderRowView(order: order) {
                            selectedOrder = order
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Zakázky")
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
}
