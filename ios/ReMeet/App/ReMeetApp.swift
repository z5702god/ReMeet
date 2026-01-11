import SwiftUI

@main
struct ReMeetApp: App {

    @StateObject private var supabase = SupabaseClient.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supabase)
        }
    }
}
