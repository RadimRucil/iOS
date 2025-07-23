import Foundation
import PDFKit
import UIKit

class PDFService {
    static let shared = PDFService()
    
    func generateInvoice(for order: Order, client: Client) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Foto Asistent",
            kCGPDFContextAuthor: UserDefaults.standard.string(forKey: "businessName") ?? "",
            kCGPDFContextTitle: "Faktura - \(order.name)"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            
            // Hlavička
            drawText("FAKTURA", at: CGPoint(x: 50, y: yPosition), fontSize: 24, isBold: true)
            yPosition += 50
            
            // Firemní údaje
            let businessName = UserDefaults.standard.string(forKey: "businessName") ?? ""
            let businessEmail = UserDefaults.standard.string(forKey: "businessEmail") ?? ""
            let businessPhone = UserDefaults.standard.string(forKey: "businessPhone") ?? ""
            let businessICO = UserDefaults.standard.string(forKey: "businessICO") ?? ""
            
            drawText("Dodavatel:", at: CGPoint(x: 50, y: yPosition), fontSize: 12, isBold: true)
            yPosition += 20
            drawText(businessName, at: CGPoint(x: 50, y: yPosition), fontSize: 10)
            yPosition += 15
            drawText("Email: \(businessEmail)", at: CGPoint(x: 50, y: yPosition), fontSize: 10)
            yPosition += 15
            drawText("Telefon: \(businessPhone)", at: CGPoint(x: 50, y: yPosition), fontSize: 10)
            if !businessICO.isEmpty {
                yPosition += 15
                drawText("IČO: \(businessICO)", at: CGPoint(x: 50, y: yPosition), fontSize: 10)
            }
            
            yPosition += 30
            
            // Údaje klienta
            drawText("Odběratel:", at: CGPoint(x: 300, y: yPosition - 95), fontSize: 12, isBold: true)
            drawText(client.name, at: CGPoint(x: 300, y: yPosition - 75), fontSize: 10)
            drawText(client.email, at: CGPoint(x: 300, y: yPosition - 60), fontSize: 10)
            drawText(client.phone, at: CGPoint(x: 300, y: yPosition - 45), fontSize: 10)
            
            // Detaily zakázky
            drawText("Detaily zakázky:", at: CGPoint(x: 50, y: yPosition), fontSize: 12, isBold: true)
            yPosition += 25
            drawText("Název: \(order.name)", at: CGPoint(x: 50, y: yPosition), fontSize: 10)
            yPosition += 15
            drawText("Datum: \(order.date.formatted(date: .abbreviated, time: .shortened))", at: CGPoint(x: 50, y: yPosition), fontSize: 10)
            yPosition += 15
            drawText("Lokalita: \(order.location)", at: CGPoint(x: 50, y: yPosition), fontSize: 10)
            
            yPosition += 40
            
            // Cena
            drawText("Cena za službu: \(Int(order.price)) Kč", at: CGPoint(x: 50, y: yPosition), fontSize: 14, isBold: true)
            if order.deposit > 0 {
                yPosition += 20
                let depositStatus = order.isDepositPaid ? "zaplacena" : "nezaplacena"
                drawText("Záloha (\(depositStatus)): \(Int(order.deposit)) Kč", at: CGPoint(x: 50, y: yPosition), fontSize: 12)
                yPosition += 20
                let finalPaymentStatus = order.isFinalPaymentPaid ? "zaplaceno" : "nezaplaceno"
                drawText("K doplacení (\(finalPaymentStatus)): \(Int(order.remainingAmount)) Kč", at: CGPoint(x: 50, y: yPosition), fontSize: 12, isBold: true)
            }
        }
        
        return data
    }
    
    private func drawText(_ text: String, at point: CGPoint, fontSize: CGFloat, isBold: Bool = false) {
        let font = isBold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
        let attributes = [NSAttributedString.Key.font: font]
        text.draw(at: point, withAttributes: attributes)
    }
}
