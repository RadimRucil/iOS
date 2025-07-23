import SwiftUI

@main
struct FotoAsistentApp: App {
    @StateObject private var expensesViewModel = ExpensesViewModel()
    @StateObject private var ordersViewModel = OrdersViewModel()
    @StateObject private var clientsViewModel = ClientsViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(expensesViewModel)
                .environmentObject(ordersViewModel)
                .environmentObject(clientsViewModel)
                .onAppear {
                    // Propojit ViewModely
                    ordersViewModel.setClientsViewModel(clientsViewModel)
                }
        }
    }
}

