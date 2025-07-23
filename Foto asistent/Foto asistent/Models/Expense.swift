import Foundation

struct Expense: Identifiable, Codable, Hashable {
    let id = UUID()
    var name: String
    var amount: Double
    var category: ExpenseCategory
    var date: Date
    var notes: String = ""
    var isRecurring: Bool = false
    
    init(name: String, amount: Double, category: ExpenseCategory, date: Date = Date(), notes: String = "", isRecurring: Bool = false) {
        self.name = name
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
        self.isRecurring = isRecurring
    }
}

enum ExpenseCategory: String, CaseIterable, Codable {
    case equipment = "Vybavení"
    case travel = "Cestovné"
    case software = "Software"
    case marketing = "Marketing"
    case education = "Vzdělání"
    case office = "Kancelář"
    case other = "Ostatní"
    
    var icon: String {
        switch self {
        case .equipment: return "camera"
        case .travel: return "car"
        case .software: return "desktopcomputer"
        case .marketing: return "megaphone"
        case .education: return "book"
        case .office: return "building"
        case .other: return "folder"
        }
    }
}
