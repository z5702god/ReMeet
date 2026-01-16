import SwiftUI
import Firebase

@main
struct ReMeetApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(SupabaseClient.shared)
        }
    }
}
