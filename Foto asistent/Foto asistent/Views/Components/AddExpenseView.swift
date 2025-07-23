import SwiftUI

struct AddExpenseView: View {
    @ObservedObject var viewModel: ExpensesViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var name = ""
    @State private var amount = ""
    @State private var category: ExpenseCategory = .other
    @State private var date = Date()
    @State private var notes = ""
    @State private var isRecurring = false
    
    var amountValue: Double {
        Double(amount) ?? 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Základní údaje") {
                    TextField("Název výdaje", text: $name)
                        .focused($isTextFieldFocused)
                    
                    HStack {
                        Text("Částka:")
                            .foregroundColor(.primary)
                        Spacer()
                        TextField("0", text: $amount)
                            .keyboardType(.numberPad)
                            .focused($isTextFieldFocused)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                        Text("Kč")
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Kategorie", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    
                    DatePicker("Datum", selection: $date, displayedComponents: .date)
                }
                
                Section("Poznámky") {
                    TextField("Poznámky k výdaji", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
                }
                
                Section {
                    Toggle("Opakující se výdaj", isOn: $isRecurring)
                }
            }
            .navigationTitle("Nový výdaj")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Zrušit") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Uložit") {
                        let expense = Expense(
                            name: name,
                            amount: amountValue,
                            category: category,
                            date: date,
                            notes: notes,
                            isRecurring: isRecurring
                        )
                        viewModel.addExpense(expense)
                        
                        // Přidáme extra notifikaci změny pro jistotu
                        DispatchQueue.main.async {
                            viewModel.objectWillChange.send()
                        }
                        
                        dismiss()
                    }
                    .disabled(name.isEmpty || amountValue <= 0)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Hotovo") {
                        isTextFieldFocused = false
                    }
                }
            }
        }
    }
}
