import Foundation
import MessageUI
import UIKit

class MessageService: NSObject, ObservableObject {
    @Published var showingMailComposer = false
    @Published var showingMessageComposer = false
    
    func sendEmail(to email: String, subject: String, body: String) {
        // Primárně použít URL scheme pro email (spolehlivější)
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailtoURL = "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)"
        
        if let url = URL(string: mailtoURL) {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback na MessageUI pokud URL scheme selže
                    DispatchQueue.main.async {
                        self.sendEmailWithMessageUI(to: email, subject: subject, body: body)
                    }
                }
            }
        } else {
            // Fallback na MessageUI
            sendEmailWithMessageUI(to: email, subject: subject, body: body)
        }
    }
    
    private func sendEmailWithMessageUI(to email: String, subject: String, body: String) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients([email])
            mailComposer.setSubject(subject)
            mailComposer.setMessageBody(body, isHTML: false)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(mailComposer, animated: true)
            }
        }
    }
    
    func sendSMS(to phoneNumber: String, message: String) {
        // Primárně použít URL scheme pro SMS (spolehlivější)
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let smsURL = "sms:\(phoneNumber)&body=\(encodedMessage)"
        
        if let url = URL(string: smsURL) {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback na MessageUI pokud URL scheme selže
                    DispatchQueue.main.async {
                        self.sendSMSWithMessageUI(to: phoneNumber, message: message)
                    }
                }
            }
        } else {
            // Fallback na MessageUI
            sendSMSWithMessageUI(to: phoneNumber, message: message)
        }
    }
    
    private func sendSMSWithMessageUI(to phoneNumber: String, message: String) {
        if MFMessageComposeViewController.canSendText() {
            let messageComposer = MFMessageComposeViewController()
            messageComposer.messageComposeDelegate = self
            messageComposer.recipients = [phoneNumber]
            messageComposer.body = message
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(messageComposer, animated: true)
            }
        }
    }
    
    func generateReminderMessage(for order: Order) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "cs_CZ")
        
        return """
        Dobrý den,
        
        připomínám Vám naše focení "\(order.name)" naplánované na \(dateFormatter.string(from: order.date)).
        
        Místo: \(order.location)
        Délka focení: \(order.formattedDuration)
        
        Těším se na spolupráci!
        
        S pozdravem,
        \(UserDefaults.standard.string(forKey: "businessName") ?? "")
        """
    }
    
    func generateReminderMessage(for client: Client) -> String {
        return """
        Dobrý den \(client.name),
        
        děkuji za Váš zájem o naše fotografické služby.
        
        V případě jakýchkoliv dotazů mě neváhejte kontaktovat.
        
        S pozdravem,
        \(UserDefaults.standard.string(forKey: "businessName") ?? "")
        \(UserDefaults.standard.string(forKey: "businessPhone") ?? "")
        """
    }
}

extension MessageService: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

extension MessageService: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}
