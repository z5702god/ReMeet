import SwiftUI

struct ChatView: View {

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Image(systemName: "message.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)

                Text("AI Chat")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)

                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .navigationTitle("Chat")
        }
    }
}
