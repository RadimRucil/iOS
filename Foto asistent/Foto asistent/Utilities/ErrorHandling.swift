import Foundation
import SwiftUI

// Přidání nového typu chyby pro práci s daty klientů
enum AppError: Error, Identifiable {
    case dataLoadFailed
    case dataSaveFailed
    case notificationFailed(String)
    case locationSearchFailed(String)
    case fileOperationFailed(String)
    case networkFailed(String)
    case clientOperationFailed(String)
    case unknown(String)
    
    var id: String {
        switch self {
        case .dataLoadFailed: return "dataLoadFailed"
        case .dataSaveFailed: return "dataSaveFailed"
        case .notificationFailed(let message): return "notificationFailed-\(message)"
        case .locationSearchFailed(let message): return "locationSearchFailed-\(message)"
        case .fileOperationFailed(let message): return "fileOperationFailed-\(message)"
        case .networkFailed(let message): return "networkFailed-\(message)"
        case .clientOperationFailed(let message): return "clientOperationFailed-\(message)"
        case .unknown(let message): return "unknown-\(message)"
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .dataLoadFailed:
            return "Nepodařilo se načíst data. Zkuste aplikaci restartovat."
        case .dataSaveFailed:
            return "Nepodařilo se uložit data. Zkontrolujte volné místo v zařízení."
        case .notificationFailed(let message):
            return "Chyba při práci s upozorněními: \(message)"
        case .locationSearchFailed(let message):
            return "Chyba při vyhledávání lokace: \(message)"
        case .fileOperationFailed(let message):
            return "Chyba při práci se soubory: \(message)"
        case .networkFailed(let message):
            return "Chyba připojení k síti: \(message)"
        case .clientOperationFailed(let message):
            return "Chyba při práci s klientem: \(message)"
        case .unknown(let message):
            return "Neznámá chyba: \(message)"
        }
    }
    
    var icon: String {
        switch self {
        case .dataLoadFailed, .dataSaveFailed:
            return "externaldrive.badge.exclamationmark"
        case .notificationFailed:
            return "bell.badge.exclamationmark"
        case .locationSearchFailed:
            return "map.exclamationmark"
        case .fileOperationFailed:
            return "doc.badge.exclamationmark"
        case .networkFailed:
            return "wifi.exclamationmark"
        case .clientOperationFailed:
            return "person.badge.exclamationmark"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }
}

struct ErrorAlert: ViewModifier {
    @Binding var error: AppError?
    var onDismiss: (() -> Void)? = nil
    
    func body(content: Content) -> some View {
        content
            .alert(item: $error) { error in
                Alert(
                    title: Text("Chyba"),
                    message: Text(error.localizedDescription),
                    dismissButton: .default(Text("OK")) {
                        self.error = nil
                        onDismiss?()
                    }
                )
            }
    }
}

extension View {
    func errorAlert(error: Binding<AppError?>, onDismiss: (() -> Void)? = nil) -> some View {
        self.modifier(ErrorAlert(error: error, onDismiss: onDismiss))
    }
}
