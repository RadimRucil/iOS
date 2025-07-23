import Foundation

struct Order: Identifiable, Codable {
    let id: UUID // UUID předávaný jako parametr pro lepší kontrolu
    var name: String
    var clientName: String
    var clientID: UUID? // Nové pole pro propojení s klientem
    var clientEmail: String = ""
    var clientPhone: String = ""
    var clientICO: String = ""
    var clientAddress: String = ""
    var location: String
    var date: Date
    var duration: Int = 60 // v minutách
    var price: Double
    var deposit: Double = 0
    var isDepositPaid: Bool = false
    var isFinalPaymentPaid: Bool = false
    var status: OrderStatus
    var photoCount: Int = 0
    var notes: String = ""

    var remainingAmount: Double {
        return price - deposit
    }

    var formattedDuration: String {
        let hours = duration / 60
        let minutes = duration % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)min"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)min"
        }
    }

    init(id: UUID = UUID(), name: String, clientName: String = "", clientID: UUID? = nil, clientEmail: String = "", clientPhone: String = "", clientICO: String = "", clientAddress: String = "", location: String = "", date: Date, duration: Int = 60, price: Double, deposit: Double = 0, status: OrderStatus = .planned) {
        self.id = id
        self.name = name
        self.clientName = clientName
        self.clientID = clientID
        self.clientEmail = clientEmail
        self.clientPhone = clientPhone
        self.clientICO = clientICO
        self.clientAddress = clientAddress
        self.location = location
        self.date = date
        self.duration = duration
        self.price = price
        self.deposit = deposit
        self.isDepositPaid = false
        self.isFinalPaymentPaid = false
        self.status = status
    }
}

enum OrderStatus: String, CaseIterable, Codable {
    case planned = "Plánováno"
    case inProgress = "Probíhá"
    case completed = "Dokončeno"
    case delivered = "Dodáno"
    case cancelled = "Zrušeno"
}
