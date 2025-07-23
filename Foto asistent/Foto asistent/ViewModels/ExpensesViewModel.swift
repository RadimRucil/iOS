import Foundation

class ExpensesViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var error: AppError?

    private let userDefaults = UserDefaults.standard
    private let expensesKey = "SavedExpenses"

    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var expensesByCategory: [ExpenseCategory: Double] {
        Dictionary(grouping: expenses, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
    }

    init() {
        loadExpenses()
    }

    func addExpense(_ expense: Expense) {
        print("ExpensesViewModel: Adding expense: \(expense.name) - \(expense.amount) Kč")
        expenses.append(expense)
        saveExpenses()
        
        // Zajistit aktualizaci UI po určité době
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.objectWillChange.send()
        }
    }

    func updateExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            saveExpenses()
            objectWillChange.send() // Přidat notifikaci změny
        }
    }

    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
        saveExpenses()
        objectWillChange.send() // Přidat notifikaci změny
    }

    func deleteExpenses(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
        saveExpenses()
        objectWillChange.send() // Přidat notifikaci změny
    }

    private func saveExpenses() {
        do {
            let encoded = try JSONEncoder().encode(expenses)
            userDefaults.set(encoded, forKey: expensesKey)
            userDefaults.synchronize()
            objectWillChange.send()
        } catch {
            self.error = AppError.dataSaveFailed
            print("ExpensesViewModel: Failed to encode expenses: \(error)")
        }
    }

    private func loadExpenses() {
        guard let data = userDefaults.data(forKey: expensesKey),
              let decodedExpenses = try? JSONDecoder().decode([Expense].self, from: data) else {
            print("ExpensesViewModel: No saved expenses found or failed to decode")
            return
        }
        expenses = decodedExpenses
        print("ExpensesViewModel: Loaded \(expenses.count) expenses")
        objectWillChange.send() // Přidat notifikaci změny i při načítání
    }
}
