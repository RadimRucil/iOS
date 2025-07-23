import SwiftUI
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    var completion: UIActivityViewController.CompletionWithItemsHandler? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.completionWithItemsHandler = completion
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {
        // Není potřeba aktualizovat
    }
}

extension View {
    func shareSheet(isPresented: Binding<Bool>, items: [Any], completion: UIActivityViewController.CompletionWithItemsHandler? = nil) -> some View {
        self.sheet(isPresented: isPresented) {
            ActivityViewController(
                activityItems: items,
                completion: completion
            )
            .edgesIgnoringSafeArea(.all)
        }
    }
}
