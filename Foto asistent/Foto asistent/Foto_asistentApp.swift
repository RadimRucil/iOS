//
//  Foto_asistentApp.swift
//  Foto asistent
//
//  Created by Radim Ručil on 14.07.2025.
//

import SwiftUI
import UserNotifications

struct Foto_asistentApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = "system"
    @StateObject private var expensesViewModel = ExpensesViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(expensesViewModel)
                .onAppear {
                    applyAppearanceMode()
                    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
                }
        }
    }
    
    private func applyAppearanceMode() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        switch appearanceMode {
        case "light":
            window.overrideUserInterfaceStyle = .light
        case "dark":
            window.overrideUserInterfaceStyle = .dark
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}

