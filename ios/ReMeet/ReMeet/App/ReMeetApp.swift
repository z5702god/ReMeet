import SwiftUI
import Firebase
import Supabase

@main
struct ReMeetApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(SupabaseClient.shared)
                .onOpenURL { url in
                    Task {
                        await handleDeepLink(url)
                    }
                }
        }
    }

    /// Handle deep links for authentication callbacks
    private func handleDeepLink(_ url: URL) async {
        // Handle Supabase auth callbacks (e.g., email confirmation, password reset)
        // URL format: remeet://auth-callback#access_token=...&refresh_token=...
        guard url.scheme == "remeet" else { return }

        do {
            try await SupabaseClient.shared.client.auth.session(from: url)
        } catch {
            print("Error handling deep link: \(error)")
        }
    }
}
