import SwiftUI

struct HomeView: View {

    @Environment(SupabaseManager.self) var supabase
    @State private var viewModel = HomeViewModel()
    @State private var showProfile = false
    @State private var showAddContact = false
    @State private var contentOpacity: Double = 0

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppColors.background.ignoresSafeArea()

                if viewModel.isLoading {
                    // Skeleton loading state
                    ScrollView {
                        VStack(spacing: AppSpacing.md) {
                            ForEach(0..<5, id: \.self) { _ in
                                SkeletonContactRow()
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.lg)
                    }
                } else if viewModel.contacts.isEmpty {
                    EmptyStateView(
                        icon: "rectangle.stack.badge.plus",
                        title: "No Business Cards Yet",
                        message: "Tap the camera icon to scan your first business card",
                        buttonTitle: "Scan Card",
                        buttonAction: { }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header
                            headerSection

                            // Search
                            SearchBarView(text: $viewModel.searchQuery, placeholder: "Search contacts...")
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.bottom, AppSpacing.md)

                            // Favorites Section
                            if !viewModel.favoriteContacts.isEmpty {
                                favoritesSection
                            }

                            // Recent Section
                            if !viewModel.recentContacts.isEmpty {
                                recentSection
                            }

                            // All Contacts Section
                            allContactsSection

                            // Bottom spacing for FAB
                            Spacer(minLength: 100)
                        }
                        .opacity(contentOpacity)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.4)) {
                                contentOpacity = 1.0
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.loadContacts()
                    }
                }

                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton(icon: "plus") {
                            HapticManager.shared.mediumImpact()
                            showAddContact = true
                        }
                        .accessibleButton(label: "Add new contact", hint: "Opens form to add a new contact")
                        .padding(.trailing, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.lg)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        // Mini logo
                        ReMeetLogo(size: 32, showText: false)

                        Text("Re:Meet")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.primaryGradient)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.lightImpact()
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppColors.primaryGradient)
                    }
                    .accessibleButton(label: "Profile settings")
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showAddContact) {
                AddContactView {
                    Task {
                        await viewModel.loadContacts()
                    }
                }
            }
            .task(id: supabase.currentUser?.id) {
                // Load contacts when user is loaded (not just authenticated)
                // currentUser is loaded after isAuthenticated is set, so we need to wait for it
                if supabase.currentUser != nil {
                    await viewModel.loadContacts()
                }
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Welcome back!")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)

            Text("\(viewModel.contacts.count) contacts")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Favorites Section

    @ViewBuilder
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Favorites")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(viewModel.favoriteContacts) { contact in
                        NavigationLink {
                            ContactDetailView(contact: contact, onDelete: {
                                Task { await viewModel.loadContacts() }
                            })
                        } label: {
                            FavoriteContactCard(contact: contact)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
            }
        }
        .padding(.bottom, AppSpacing.lg)
    }

    // MARK: - Recent Section

    @ViewBuilder

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Recently Added")

            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.recentContacts.prefix(3)) { contact in
                    NavigationLink {
                        ContactDetailView(contact: contact, onDelete: {
                            Task { await viewModel.loadContacts() }
                        })
                    } label: {
                        ContactRowCard(
                            contact: contact,
                            onFavorite: {
                                Task { await viewModel.toggleFavorite(contact) }
                            },
                            onDelete: {
                                Task { await viewModel.deleteContact(contact) }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .padding(.bottom, AppSpacing.lg)
    }

    // MARK: - All Contacts Section

    @ViewBuilder

    private var allContactsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: viewModel.searchQuery.isEmpty ? "All Contacts" : "Search Results")

            VStack(spacing: AppSpacing.sm) {
                ForEach(viewModel.filteredContacts) { contact in
                    NavigationLink {
                        ContactDetailView(contact: contact, onDelete: {
                            Task { await viewModel.loadContacts() }
                        })
                    } label: {
                        ContactRowCard(
                            contact: contact,
                            onFavorite: {
                                Task { await viewModel.toggleFavorite(contact) }
                            },
                            onDelete: {
                                Task { await viewModel.deleteContact(contact) }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .animation(.easeInOut(duration: 0.25), value: viewModel.filteredContacts.count)
        }
    }
}

// MARK: - Favorite Contact Card

struct FavoriteContactCard: View {
    let contact: Contact

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            AvatarView(name: contact.fullName, size: 60)

            VStack(spacing: 2) {
                Text(contact.fullName.components(separatedBy: " ").first ?? contact.fullName)
                    .font(AppTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                if let company = contact.company?.name {
                    Text(company)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(width: 90)
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.sm)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Contact Row Card

struct ContactRowCard: View {
    let contact: Contact
    var onFavorite: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Avatar
            AvatarView(name: contact.fullName, size: 50)

            // Contact Info
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.fullName)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                if let title = contact.titleWithCompany {
                    Text(title)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Favorite indicator
            if contact.isFavorite {
                Image(systemName: "star.fill")
                    .font(.subheadline)
                    .foregroundColor(AppColors.accentOrange)
            }

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Contact Row View (Legacy support)

struct ContactRowView: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            AvatarView(name: contact.fullName, size: 50)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(contact.fullName)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                if let title = contact.titleWithCompany {
                    Text(title)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if contact.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(AppColors.accentOrange)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Profile View

struct ProfileView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(SupabaseManager.self) var supabase
    @State private var showPrivacyPolicy = false
    @State private var showDeleteAccount = false

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Profile Header
                        if let user = supabase.currentUser {
                            VStack(spacing: AppSpacing.md) {
                                AvatarView(
                                    name: user.displayName,
                                    size: 100
                                )

                                VStack(spacing: AppSpacing.xs) {
                                    Text(user.displayName)
                                        .font(AppTypography.title2)
                                        .foregroundColor(AppColors.textPrimary)

                                    Text(user.email)
                                        .font(AppTypography.subheadline)
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            .padding(.vertical, AppSpacing.xl)
                        }

                        // Account Section
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Account")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, AppSpacing.md)

                            VStack(spacing: 1) {
                                Button {
                                    showPrivacyPolicy = true
                                } label: {
                                    ProfileMenuItem(
                                        icon: "lock.fill",
                                        title: "Privacy Policy",
                                        iconColor: AppColors.accentGreen
                                    )
                                }
                            }
                            .cardStyle(padding: 0)
                            .padding(.horizontal, AppSpacing.md)
                        }

                        // Danger Zone Section
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Danger Zone")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, AppSpacing.md)

                            VStack(spacing: 1) {
                                Button {
                                    showDeleteAccount = true
                                } label: {
                                    ProfileMenuItem(
                                        icon: "trash.fill",
                                        title: "Delete Account",
                                        iconColor: AppColors.accentRed
                                    )
                                }
                            }
                            .cardStyle(padding: 0)
                            .padding(.horizontal, AppSpacing.md)
                        }

                        // Sign Out
                        Button {
                            Task {
                                try? await supabase.signOut()
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                    .foregroundColor(AppColors.accentRed)
                                Text("Sign Out")
                                    .foregroundColor(AppColors.accentRed)
                                Spacer()
                            }
                            .padding(AppSpacing.md)
                        }
                        .cardStyle(padding: 0)
                        .padding(.horizontal, AppSpacing.md)

                        // Version
                        Text("Version 1.0.0")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.top, AppSpacing.lg)
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
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showDeleteAccount) {
                DeleteAccountView()
                    .environment(supabase)
            }
        }
    }
}

// MARK: - Profile Menu Item

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    var iconColor: Color = AppColors.accentBlue

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(iconColor)
                .frame(width: 28)

            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
    }
}

// MARK: - Preview

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(SupabaseManager.shared)
    }
}
#endif
