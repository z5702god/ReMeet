import SwiftUI

struct HomeView: View {

    @EnvironmentObject var supabase: SupabaseClient
    @StateObject private var viewModel = HomeViewModel()
    @State private var showProfile = false

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if viewModel.contacts.isEmpty {
                    emptyStateView
                } else {
                    contactsListView
                }
            }
            .navigationTitle("Business Cards")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .refreshable {
                await viewModel.loadContacts()
            }
            .onAppear {
                Task {
                    await viewModel.loadContacts()
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("No Business Cards Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap the camera icon to scan your first business card")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                // Switch to camera tab
                // This would need to be coordinated with the parent TabView
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Scan Card")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Contacts List

    private var contactsListView: some View {
        List {
            // Search bar
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search contacts...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .listRowBackground(Color.clear)

            // Recent contacts
            if !viewModel.recentContacts.isEmpty {
                Section("Recent") {
                    ForEach(viewModel.recentContacts) { contact in
                        NavigationLink {
                            ContactDetailView(contact: contact)
                        } label: {
                            ContactRowView(contact: contact)
                        }
                    }
                }
            }

            // All contacts
            Section("All Contacts") {
                ForEach(viewModel.filteredContacts) { contact in
                    NavigationLink {
                        ContactDetailView(contact: contact)
                    } label: {
                        ContactRowView(contact: contact)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Contact Row View

struct ContactRowView: View {

    let contact: Contact

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(contact.initials)
                        .font(.headline)
                        .foregroundColor(.white)
                )

            // Contact info
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.fullName)
                    .font(.headline)

                if let title = contact.titleWithCompany {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Favorite star
            if contact.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Profile View

struct ProfileView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var supabase: SupabaseClient

    var body: some View {
        NavigationView {
            List {
                Section {
                    if let user = supabase.currentUser {
                        VStack(spacing: 12) {
                            // Avatar
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(user.firstName?.prefix(1).uppercased() ?? "U")
                                        .font(.largeTitle)
                                        .foregroundColor(.white)
                                )

                            Text(user.displayName)
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                }

                Section("Account") {
                    Button(role: .destructive) {
                        Task {
                            try? await supabase.signOut()
                            dismiss()
                        }
                    } label: {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(SupabaseClient.shared)
    }
}
#endif
