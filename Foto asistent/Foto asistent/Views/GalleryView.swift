import SwiftUI

struct GalleryView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                
                Text("Galerie")
                    .font(.title2)
                    .padding()
                
                Text("Galerie fotografií bude implementována později")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Galerie")
        }
    }
}
