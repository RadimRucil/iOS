import SwiftUI

struct ExpensesView: View {
    @EnvironmentObject var viewModel: ExpensesViewModel
    @State private var showingAddExpense = false
    
    var body: some View {
        NavigationView {
            List {
                // Kontrola, že používáme správný způsob zobrazení seznamu
                ForEach(viewModel.expenses) { expense in
                    HStack {
                        Image(systemName: expense.category.icon)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(expense.name)
                                .font(.headline)
                            Text(expense.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(expense.amount)) Kč")
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
                .onDelete(perform: viewModel.deleteExpenses)
            }
            .navigationTitle("Výdaje")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddExpense = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(viewModel: viewModel)
            }
            // Přidat tento refresh modifier pro explicitní obnovení při návratu z AddExpenseView
            .onAppear {
                viewModel.objectWillChange.send()
            }
        }
    }
}
