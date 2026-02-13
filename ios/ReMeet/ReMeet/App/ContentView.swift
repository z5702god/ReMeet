import SwiftUI

struct ContentView: View {

    @Environment(SupabaseManager.self) var supabase

    var body: some View {
        Group {
            if supabase.isCheckingSession {
                // Show splash while checking session
                ZStack {
                    AppColors.background.ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.rectangle.stack.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(AppColors.primaryGradient)
                        Text("Re:Meet")
                            .font(.title.bold())
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            } else if supabase.isAuthenticated {
                // User is logged in - show main app
                MainTabView()
            } else {
                // User is not logged in - show login
                LoginView()
            }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home/Cards Tab
            HomeView()
                .tabItem {
                    Label("Cards", systemImage: "rectangle.stack")
                }
                .tag(0)

            // Companies Tab
            CompaniesListView()
                .tabItem {
                    Label("Companies", systemImage: "building.2")
                }
                .tag(1)

            // Scan Tab (Center, prominent)
            CameraView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(2)

            // Timeline Tab
            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "calendar")
                }
                .tag(3)

            // Chat Tab
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(4)
        }
        .tint(AppColors.accentBlue)
    }
}

// MARK: - Preview

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(SupabaseClient.shared)
    }
}
#endif
