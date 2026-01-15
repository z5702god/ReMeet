import SwiftUI
import Firebase

@main
struct ReMeetApp: App {

    @State private var supabase = SupabaseClient.shared

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(supabase)
        }
    }
}
