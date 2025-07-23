import Foundation

struct Client: Identifiable, Codable {
    let id = UUID()
    var name: String
    var email: String
    var phone: String
    var ico: String = ""
    var address: String
    var notes: String
    var createdDate: Date
    var totalOrders: Int
    var totalSpent: Double
    
    init(name: String, email: String = "", phone: String = "", ico: String = "", address: String = "", notes: String = "") {
        self.name = name
        self.email = email
        self.phone = phone
        self.ico = ico
        self.address = address
        self.notes = notes
        self.createdDate = Date()
        self.totalOrders = 0
        self.totalSpent = 0
    }
}
