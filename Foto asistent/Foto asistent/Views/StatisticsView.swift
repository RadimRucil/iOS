import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var ordersViewModel: OrdersViewModel
    @StateObject private var expensesViewModel = ExpensesViewModel()
    @State private var selectedYear: Int? = Calendar.current.component(.year, from: Date())
    @State private var showingExpenses = false
    
    var availableYears: [Int] {
        let orders = ordersViewModel.orders
        let years = Set(orders.map { Calendar.current.component(.year, from: $0.date) })
        return Array(years).sorted().reversed()
    }
    
    var monthlyRevenue: [MonthlyData] {
        let calendar = Calendar.current
        let ordersForPeriod: [Order]
        
        if let selectedYear = selectedYear {
            ordersForPeriod = ordersViewModel.orders.filter { order in
                calendar.component(.year, from: order.date) == selectedYear &&
                (order.status == .completed || order.status == .delivered)
            }
        } else {
            ordersForPeriod = ordersViewModel.orders.filter { $0.status == .completed || $0.status == .delivered }
        }
        
        if let selectedYear = selectedYear {
            // Vytvoř data pro všech 12 měsíců vybraného roku
            var monthlyData: [MonthlyData] = []
            for month in 1...12 {
                let ordersForMonth = ordersForPeriod.filter { order in
                    calendar.component(.month, from: order.date) == month
                }
                
                let revenue = ordersForMonth.reduce(0.0) { total, order in
                    return total + calculatePaidAmount(for: order)
                }
                
                let monthDate = calendar.date(from: DateComponents(year: selectedYear, month: month, day: 1)) ?? Date()
                monthlyData.append(MonthlyData(month: monthDate, revenue: revenue))
            }
            return monthlyData
        } else {
            // Pro celé období - skupuj podle roku a měsíce
            let grouped = Dictionary(grouping: ordersForPeriod) { order in
                calendar.dateInterval(of: .month, for: order.date)?.start ?? order.date
            }
            
            return grouped.map { date, orders in
                let revenue = orders.reduce(0.0) { total, order in
                    return total + calculatePaidAmount(for: order)
                }
                return MonthlyData(month: date, revenue: revenue)
            }.sorted { $0.month < $1.month }
        }
    }
    
    var actualRevenue: Double {
        if let selectedYear = selectedYear {
            return ordersViewModel.orders.filter { order in
                Calendar.current.component(.year, from: order.date) == selectedYear
            }.reduce(0) { total, order in
                return total + calculatePaidAmount(for: order)
            }
        } else {
            return ordersViewModel.orders.reduce(0) { total, order in
                return total + calculatePaidAmount(for: order)
            }
        }
    }
    
    var totalRevenue: Double {
        ordersViewModel.orders.filter { $0.status == .completed || $0.status == .delivered }
            .reduce(0) { total, order in
                return total + calculatePaidAmount(for: order)
            }
    }
    
    var totalExpenses: Double {
        if let selectedYear = selectedYear {
            return expensesViewModel.expenses
                .filter { Calendar.current.component(.year, from: $0.date) == selectedYear }
                .reduce(0) { $0 + $1.amount }
        } else {
            return expensesViewModel.totalExpenses
        }
    }
    
    var netProfit: Double {
        actualRevenue - totalExpenses
    }
    
    private func calculatePaidAmount(for order: Order) -> Double {
        var paidAmount = 0.0
        
        // Přidat zálohu pokud je zaplacená
        if order.deposit > 0 && order.isDepositPaid {
            paidAmount += order.deposit
        }
        
        // Přidat doplacení pokud je zaplacené
        if order.remainingAmount > 0 && order.isFinalPaymentPaid {
            paidAmount += order.remainingAmount
        }
        
        // Pokud není záloha ale celá částka je zaplacená (pro případ bez zálohy)
        if order.deposit == 0 && order.isFinalPaymentPaid {
            paidAmount += order.price
        }
        
        return paidAmount
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Výběr období
                    HStack {
                        Text("Výběr období:")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Picker("Období", selection: $selectedYear) {
                            Text("Celé období").tag(nil as Int?)
                            ForEach(availableYears, id: \.self) { year in
                                Text(String(year)).tag(year as Int?)
                            }
                        }
                        .pickerStyle(.menu)
                        .accentColor(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Přehled základních čísel
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(title: "Skutečné tržby", value: "\(Int(actualRevenue).formatted(.number.locale(Locale(identifier: "cs_CZ")))) Kč", color: .green)
                        
                        Button(action: { showingExpenses = true }) {
                            StatCard(title: "Celkové výdaje", value: "\(Int(totalExpenses).formatted(.number.locale(Locale(identifier: "cs_CZ")))) Kč", color: .red)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        StatCard(title: "Čistý zisk", value: "\(Int(netProfit).formatted(.number.locale(Locale(identifier: "cs_CZ")))) Kč", color: netProfit >= 0 ? .blue : .orange)
                        StatCard(title: "Počet zakázek", value: "\(filteredOrdersCount)", color: .purple)
                    }
                    
                    // Graf skutečných tržeb
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedYear != nil ? "Měsíční tržby" : "Tržby podle období")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if #available(iOS 16.0, *) {
                            Chart(monthlyRevenue) { data in
                                BarMark(
                                    x: .value("Období", data.month, unit: selectedYear != nil ? .month : .month),
                                    y: .value("Tržby", data.revenue)
                                )
                                .foregroundStyle(.blue)
                            }
                            .chartXAxis {
                                if selectedYear != nil {
                                    AxisMarks(values: .stride(by: .month)) { value in
                                        if let date = value.as(Date.self) {
                                            AxisValueLabel {
                                                Text(monthAbbreviation(for: date))
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                } else {
                                    AxisMarks(values: .stride(by: .month)) { value in
                                        if let date = value.as(Date.self) {
                                            AxisValueLabel {
                                                Text(date.formatted(.dateTime.month().year()))
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                            .padding(.horizontal)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    Text("Grafy vyžadují iOS 16+")
                                        .foregroundColor(.secondary)
                                )
                                .padding(.horizontal)
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Statistiky")
            .sheet(isPresented: $showingExpenses) {
                ExpensesView()
                    .environmentObject(expensesViewModel)
            }
            .onAppear {
                if availableYears.isEmpty {
                    selectedYear = Calendar.current.component(.year, from: Date())
                } else if let currentSelection = selectedYear, !availableYears.contains(currentSelection) {
                    selectedYear = availableYears.first
                }
            }
        }
    }
    
    private var filteredOrdersCount: String {
        if let selectedYear = selectedYear {
            let count = ordersViewModel.orders.filter { order in
                Calendar.current.component(.year, from: order.date) == selectedYear
            }.count
            return "\(count)"
        } else {
            return "\(ordersViewModel.orders.count)"
        }
    }
    
    private var filteredExpensesCount: Int {
        if let selectedYear = selectedYear {
            return expensesViewModel.expenses.filter { expense in
                Calendar.current.component(.year, from: expense.date) == selectedYear
            }.count
        } else {
            return expensesViewModel.expenses.count
        }
    }
    
    private func monthAbbreviation(for date: Date) -> String {
        let month = Calendar.current.component(.month, from: date)
        
        switch month {
        case 1: return "Led"
        case 2: return "Úno"
        case 3: return "Bře"
        case 4: return "Dub"
        case 5: return "Kvě"
        case 6: return "Čer"
        case 7: return "Čvc"
        case 8: return "Srp"
        case 9: return "Zář"
        case 10: return "Říj"
        case 11: return "Lis"
        case 12: return "Pro"
        default: return "---"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct MonthlyData: Identifiable {
    let id = UUID()
    let month: Date
    let revenue: Double
}
