import SwiftUI

struct OrderRowView: View {
    let order: Order
    let onTap: () -> Void
    let showWeather: Bool
    @StateObject private var weatherService = WeatherService()
    
    init(order: Order, showWeather: Bool = false, onTap: @escaping () -> Void) {
        self.order = order
        self.showWeather = showWeather
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Barevný indikátor na levé straně
                    Rectangle()
                        .fill(statusColor(order.status))
                        .frame(width: 4)
                        .cornerRadius(2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(order.name)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .frame(maxWidth: 170, alignment: .leading)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    Text("\(order.date.formatted(date: .abbreviated, time: .omitted)) \(order.date.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .fontWeight(.medium)
                                }
                                
                                if !order.clientName.isEmpty {
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        Text(order.clientName)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .frame(maxWidth: 170, alignment: .leading)
                                    }
                                }
                                
                                if !order.location.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "location.fill")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        Text(order.location)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                    .frame(maxWidth: 170, alignment: .leading)
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Text(order.formattedDuration)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Weather info - pouze pro nadcházející zakázky
                                if showWeather && !order.location.isEmpty, let weather = weatherService.weatherData {
                                    HStack(spacing: 4) {
                                        Image(systemName: weather.icon)
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        Text("\(Int(weather.temperature))°C")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("pro \(order.date.formatted(.dateTime.day().month().year()))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .environment(\.locale, Locale(identifier: "cs_CZ"))
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                // Štítek stavu
                                Text(order.status.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(statusColor(order.status).opacity(0.1))
                                    .foregroundColor(statusColor(order.status))
                                    .cornerRadius(4)
                                
                                Spacer()
                                
                                // Informace o ceně
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(Int(order.price)) Kč")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    if order.deposit > 0 {
                                        HStack(spacing: 4) {
                                            Text("Záloha:")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text("\(Int(order.deposit)) Kč")
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(order.isDepositPaid ? .green : .red)
                                            if order.isDepositPaid {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.caption2)
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        
                                        if order.remainingAmount > 0 {
                                            HStack(spacing: 4) {
                                                Text("Zbývá:")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text("\(Int(order.remainingAmount)) Kč")
                                                    .font(.caption2)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(order.isFinalPaymentPaid ? .green : .red)
                                                if order.isFinalPaymentPaid {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.caption2)
                                                        .foregroundColor(.green)
                                                }
                                            }
                                        } else if order.isDepositPaid || order.isFinalPaymentPaid {
                                            Text("Zaplaceno")
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.trailing, 8)
                }
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
        .padding(.vertical, 2)
        .onAppear {
            if showWeather && !order.location.isEmpty {
                weatherService.fetchWeather(for: order.location, date: order.date)
            }
        }
    }
    
    private func statusColor(_ status: OrderStatus) -> Color {
        switch status {
        case .planned: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .delivered: return .purple
        case .cancelled: return .red
        }
    }
}
