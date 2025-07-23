import SwiftUI

struct ClientRowView: View {
    let client: Client
    let onTap: () -> Void
    @EnvironmentObject var ordersViewModel: OrdersViewModel
    @EnvironmentObject var clientsViewModel: ClientsViewModel
    
    private var unpaidAmount: Double {
        clientsViewModel.getUnpaidAmount(for: client, from: ordersViewModel.orders)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Avatar
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(client.name.prefix(2).uppercased())
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(client.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if !client.email.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "envelope")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(client.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        if !client.phone.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "phone")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(client.phone)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        if !client.address.isEmpty && client.email.isEmpty && client.phone.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "location")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(client.address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(client.totalOrders)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("zakázek")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if client.totalSpent > 0 {
                            Text("\(Int(client.totalSpent).formatted(.number.locale(Locale(identifier: "cs_CZ")))) Kč")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        
                        if unpaidAmount > 0 {
                            Text("\(Int(unpaidAmount).formatted(.number.locale(Locale(identifier: "cs_CZ")))) Kč")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}
