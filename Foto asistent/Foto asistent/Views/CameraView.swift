import SwiftUI

struct CameraView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "camera")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                
                Text("Fotoaparát")
                    .font(.title2)
                    .padding()
                
                Text("Funkce fotoaparátu bude implementována později")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Fotoaparát")
        }
    }
}
