import XCTest
@testable import Foto_asistent

class OrdersViewModelTests: XCTestCase {
    var viewModel: OrdersViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = OrdersViewModel()
    }
    
    func testAddOrder() {
        // Test přidání zakázky
        let initialCount = viewModel.orders.count
        viewModel.addOrder(name: "Test Order", clientName: "John Doe", location: "Prague", date: Date(), price: 1000)
        XCTAssertEqual(viewModel.orders.count, initialCount + 1)
    }
    
    // Další testy...
}
