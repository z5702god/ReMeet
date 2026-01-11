import SwiftUI

struct CameraView: View {

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)

                Text("Camera")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)

                Text("Scan business cards - Coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()
            }
            .navigationTitle("Scan Card")
        }
    }
}
