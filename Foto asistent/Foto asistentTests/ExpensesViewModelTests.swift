import XCTest
@testable import Foto_asistent

class ExpensesViewModelTests: XCTestCase {
    var viewModel: ExpensesViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = ExpensesViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testAddExpense() {
        let initialCount = viewModel.expenses.count
        let expense = Expense(name: "Test", amount: 100, category: .equipment, date: Date())
        
        viewModel.addExpense(expense)
        
        XCTAssertEqual(viewModel.expenses.count, initialCount + 1)
        XCTAssertEqual(viewModel.expenses.last?.name, "Test")
        XCTAssertEqual(viewModel.expenses.last?.amount, 100)
    }
}
