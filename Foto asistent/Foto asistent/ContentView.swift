//
//  ContentView.swift
//  Foto asistent
//
//  Created by Radim Ručil on 14.07.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var ordersViewModel = OrdersViewModel()
    @StateObject private var clientsViewModel = ClientsViewModel()
    @StateObject private var expensesViewModel = ExpensesViewModel()
    
    var body: some View {
        TabView {
            UpcomingOrdersView()
                .environmentObject(ordersViewModel)
                .tabItem {
                    Image(systemName: "calendar.badge.clock")
                    Text("Nadcházející")
                }
            
            CompletedOrdersView()
                .environmentObject(ordersViewModel)
                .tabItem {
                    Image(systemName: "checkmark.circle")
                    Text("Uskutečněné")
                }
            
            ClientsView()
                .environmentObject(clientsViewModel)
                .environmentObject(ordersViewModel)
                .tabItem {
                    Image(systemName: "person.2")
                    Text("Klienti")
                }
            
            StatisticsView()
                .environmentObject(ordersViewModel)
                .environmentObject(expensesViewModel)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Statistiky")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Nastavení")
                }
        }
        .environment(\.locale, Locale(identifier: "cs_CZ"))
        .onAppear {
            // Propojit view modely pro synchronizaci
            ordersViewModel.setClientsViewModel(clientsViewModel)
            print("ContentView: ViewModels connected")
        }
    }
}

#Preview {
    ContentView()
}
