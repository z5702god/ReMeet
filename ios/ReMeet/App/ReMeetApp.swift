import SwiftUI

@main
struct ReMeetApp: App {

    @State private var supabase = SupabaseClient.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(supabase)
        }
    }
}
