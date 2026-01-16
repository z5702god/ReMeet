import SwiftUI

struct ContactDetailView: View {

    let contact: Contact
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var businessCard: BusinessCard?
    @State private var meetingContexts: [MeetingContext] = []
    @State private var isLoading = true
    @State private var showAddMeetingContext = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var headerOpacity: Double = 0
    @State private var contentOpacity: Double = 0

    private let supabase = SupabaseManager.shared

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Business Card Image (if available)
                    if let card = businessCard, let url = URL(string: card.imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 180)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(AppCornerRadius.medium)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(AppColors.textSecondary)
                                    .frame(height: 180)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.md)
                    }

                    // Header with avatar
                    VStack(spacing: AppSpacing.md) {
                        if businessCard == nil {
                            AvatarView(name: contact.fullName, size: 100)
                        }

                        Text(contact.fullName)
                            .font(AppTypography.title1)
                            .foregroundColor(AppColors.textPrimary)

                        if let title = contact.titleWithCompany {
                            Text(title)
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }

                        // Favorite badge
                        if contact.isFavorite {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(AppColors.accentOrange)
                                Text("Favorite")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(AppColors.accentOrange.opacity(0.15))
                            .cornerRadius(AppCornerRadius.small)
                        }
                    }
                    .padding(.top, businessCard == nil ? AppSpacing.lg : 0)
                    .opacity(headerOpacity)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.4)) {
                            headerOpacity = 1.0
                        }
                    }

                    // Quick Actions
                    HStack(spacing: AppSpacing.lg) {
                        if let phone = contact.phone {
                            QuickActionButton(
                                icon: "phone.fill",
                                label: "Call",
                                color: AppColors.accentGreen
                            ) {
                                if let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }

                        if let email = contact.email {
                            QuickActionButton(
                                icon: "envelope.fill",
                                label: "Email",
                                color: AppColors.accentBlue
                            ) {
                                if let url = URL(string: "mailto:\(email)") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }

                        QuickActionButton(
                            icon: "plus.circle.fill",
                            label: "Context",
                            color: AppColors.accentPurple
                        ) {
                            showAddMeetingContext = true
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .opacity(contentOpacity)

                    // Contact information
                    VStack(spacing: AppSpacing.md) {
                        if let phone = contact.phone {
                            ContactInfoRow(icon: "phone.fill", label: "Phone", value: phone, isLink: true)
                        }

                        if let email = contact.email {
                            ContactInfoRow(icon: "envelope.fill", label: "Email", value: email, isLink: true)
                        }

                        if let website = contact.website {
                            ContactInfoRow(icon: "globe", label: "Website", value: website, isLink: true)
                        }

                        if let address = contact.address {
                            ContactInfoRow(icon: "mappin.circle.fill", label: "Address", value: address)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .opacity(contentOpacity)

                    // Meeting Contexts
                    if !meetingContexts.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Meeting History")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, AppSpacing.md)

                            ForEach(meetingContexts) { context in
                                MeetingContextCard(context: context)
                            }
                        }
                        .opacity(contentOpacity)
                    }

                    // Notes
                    if let notes = contact.notes {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Notes")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textSecondary)

                            Text(notes)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.md)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.cardBackground)
                                .cornerRadius(AppCornerRadius.medium)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .opacity(contentOpacity)
                    }

                    // Tags
                    if let tags = contact.tags, !tags.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Tags")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textSecondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppSpacing.sm) {
                                    ForEach(tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(AppTypography.caption)
                                            .padding(.horizontal, AppSpacing.md)
                                            .padding(.vertical, AppSpacing.sm)
                                            .background(AppColors.accentBlue.opacity(0.15))
                                            .foregroundColor(AppColors.accentBlue)
                                            .cornerRadius(AppCornerRadius.large)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .opacity(contentOpacity)
                    }

                    // OCR Status (if pending)
                    if let card = businessCard, card.ocrStatus != .completed {
                        VStack(spacing: AppSpacing.sm) {
                            HStack {
                                if card.ocrStatus == .processing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                Text("OCR Status: \(card.ocrStatus.rawValue.capitalized)")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(AppSpacing.md)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.cardBackground)
                        .cornerRadius(AppCornerRadius.medium)
                        .padding(.horizontal, AppSpacing.md)
                        .opacity(contentOpacity)
                    }

                    Spacer(minLength: 40)
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                        contentOpacity = 1.0
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        HapticManager.shared.warning()
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Contact", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppColors.accentPurple)
                }
                .accessibleButton(label: "More options")
            }
        }
        .task {
            await loadData()
        }
        .sheet(isPresented: $showAddMeetingContext) {
            MeetingContextView(contactId: contact.id) {
                Task {
                    await loadMeetingContexts()
                }
            }
        }
        .alert("Delete Contact", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteContact()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(contact.fullName)? This action cannot be undone.")
        }
        .overlay {
            if isDeleting {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView("Deleting...")
                            .padding(AppSpacing.lg)
                            .background(AppColors.cardBackground)
                            .cornerRadius(AppCornerRadius.medium)
                    }
            }
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        await loadBusinessCard()
        await loadMeetingContexts()
        isLoading = false
    }

    private func loadBusinessCard() async {
        guard let cardId = contact.cardId else { return }

        do {
            businessCard = try await supabase.fetchBusinessCard(forContactId: cardId)
        } catch {
            print("Error loading business card: \(error)")
        }
    }

    private func loadMeetingContexts() async {
        do {
            meetingContexts = try await supabase.fetchMeetingContexts(forContactId: contact.id)
        } catch {
            print("Error loading meeting contexts: \(error)")
        }
    }

    // MARK: - Delete

    private func deleteContact() async {
        isDeleting = true

        do {
            try await supabase.deleteContact(id: contact.id)
            isDeleting = false
            onDelete?()
            dismiss()
        } catch {
            isDeleting = false
            print("Error deleting contact: \(error)")
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.mediumImpact()
            action()
        } label: {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(label)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(width: 70, height: 70)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.medium)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibleButton(label: label)
    }
}

// MARK: - Meeting Context Card

struct MeetingContextCard: View {
    let context: MeetingContext

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                if let occasionType = context.occasionType {
                    let type = OccasionType(rawValue: occasionType) ?? .other
                    Image(systemName: type.icon)
                        .foregroundColor(AppColors.accentBlue)
                }

                if let eventName = context.eventName {
                    Text(eventName)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                } else if let occasionType = context.occasionType {
                    let type = OccasionType(rawValue: occasionType) ?? .other
                    Text(type.displayName)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                }

                Spacer()

                if let date = context.meetingDate {
                    Text(date, style: .date)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            // Location
            if let location = context.locationName {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "mappin")
                        .foregroundColor(AppColors.textSecondary)
                        .font(.caption)
                    Text(location)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            // Relationship
            if let relationshipType = context.relationshipType {
                let type = RelationshipType(rawValue: relationshipType) ?? .contact
                Text(type.displayName)
                    .font(AppTypography.caption)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(type.color.opacity(0.2))
                    .foregroundColor(type.color)
                    .cornerRadius(AppCornerRadius.small)
            }

            // Notes
            if let notes = context.notes {
                Text(notes)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
            }

            // Follow-up indicator
            if context.followUpRequired {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(AppColors.accentOrange)
                        .font(.caption)
                    Text("Follow-up needed")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.accentOrange)
                    if let followUpDate = context.followUpDate {
                        Text("by \(followUpDate, style: .date)")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - Contact Info Row

struct ContactInfoRow: View {

    let icon: String
    let label: String
    let value: String
    var isLink: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(AppColors.accentBlue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

                if isLink {
                    Link(value, destination: linkURL)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                } else {
                    Text(value)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                }
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }

    private var linkURL: URL {
        if label == "Phone" {
            return URL(string: "tel:\(value.replacingOccurrences(of: " ", with: ""))")!
        } else if label == "Email" {
            return URL(string: "mailto:\(value)")!
        } else {
            return URL(string: value) ?? URL(string: "https://\(value)")!
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ContactDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                ContactDetailView(contact: .sample, onDelete: nil)
            }
            .preferredColorScheme(.light)

            NavigationView {
                ContactDetailView(contact: .sample, onDelete: nil)
            }
            .preferredColorScheme(.dark)
        }
    }
}
#endif
