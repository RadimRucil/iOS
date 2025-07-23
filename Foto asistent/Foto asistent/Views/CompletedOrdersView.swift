import SwiftUI

struct CompletedOrdersView: View {
    @EnvironmentObject var viewModel: OrdersViewModel
    @State private var selectedOrder: Order?
    @AppStorage("showTotalEarnings") private var showTotalEarnings = true
    
    var completedOrders: [Order] {
        viewModel.orders.filter { order in
            order.status == .completed || order.status == .delivered || order.status == .cancelled
        }.sorted { $0.date > $1.date }
    }
    
    var totalEarnings: Double {
        completedOrders.reduce(0) { total, order in
            var orderEarnings = 0.0
            
            // Přidat zálohu pokud je zaplacená
            if order.deposit > 0 && order.isDepositPaid {
                orderEarnings += order.deposit
            }
            
            // Přidat doplacení pokud je zaplacené
            if order.remainingAmount > 0 && order.isFinalPaymentPaid {
                orderEarnings += order.remainingAmount
            }
            
            // Pokud není záloha ale celá částka je zaplacená (pro případ bez zálohy)
            if order.deposit == 0 && order.isFinalPaymentPaid {
                orderEarnings += order.price
            }
            
            return total + orderEarnings
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if !completedOrders.isEmpty && showTotalEarnings {
                    VStack(spacing: 6) {
                        Text("Celkové tržby")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(totalEarnings)) Kč")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                
                List {
                    ForEach(completedOrders) { order in
                        OrderRowView(order: order, showWeather: false) {
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
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Uskutečněné zakázky")
            .sheet(item: $selectedOrder) { order in
                OrderDetailView(order: order, viewModel: viewModel)
            }
        }
    }
    
    private func deleteOrder(at offsets: IndexSet) {
        // Převést offsety z filtrovaného seznamu na offsety v originálním seznamu
        let ordersToDelete = offsets.map { completedOrders[$0] }
        
        for order in ordersToDelete {
            viewModel.deleteOrder(order)
        }
    }
}
