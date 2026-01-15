import SwiftUI

struct ContactDetailView: View {

    let contact: Contact

    @State private var businessCard: BusinessCard?
    @State private var meetingContexts: [MeetingContext] = []
    @State private var isLoading = true
    @State private var showAddMeetingContext = false

    private let supabase = SupabaseManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                                .frame(height: 180)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }

                // Header with avatar
                VStack(spacing: 16) {
                    if businessCard == nil {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(contact.initials)
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }

                    Text(contact.fullName)
                        .font(.title)
                        .fontWeight(.bold)

                    if let title = contact.titleWithCompany {
                        Text(title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Favorite badge
                    if contact.isFavorite {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Favorite")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, businessCard == nil ? 20 : 0)

                // Quick Actions
                HStack(spacing: 20) {
                    if let phone = contact.phone {
                        QuickActionButton(
                            icon: "phone.fill",
                            label: "Call",
                            color: .green
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
                            color: .blue
                        ) {
                            if let url = URL(string: "mailto:\(email)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }

                    QuickActionButton(
                        icon: "plus.circle.fill",
                        label: "Context",
                        color: .purple
                    ) {
                        showAddMeetingContext = true
                    }
                }
                .padding(.horizontal)

                // Contact information
                VStack(spacing: 16) {
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
                .padding(.horizontal)

                // Meeting Contexts
                if !meetingContexts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meeting History")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        ForEach(meetingContexts) { context in
                            MeetingContextCard(context: context)
                        }
                    }
                }

                // Notes
                if let notes = contact.notes {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text(notes)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                // Tags
                if let tags = contact.tags, !tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // OCR Status (if pending)
                if let card = businessCard, card.ocrStatus != .completed {
                    VStack(spacing: 8) {
                        HStack {
                            if card.ocrStatus == .processing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("OCR Status: \(card.ocrStatus.rawValue.capitalized)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70, height: 70)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Meeting Context Card

struct MeetingContextCard: View {
    let context: MeetingContext

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if let occasionType = context.occasionType {
                    let type = OccasionType(rawValue: occasionType) ?? .other
                    Image(systemName: type.icon)
                        .foregroundColor(.blue)
                }

                if let eventName = context.eventName {
                    Text(eventName)
                        .font(.headline)
                } else if let occasionType = context.occasionType {
                    let type = OccasionType(rawValue: occasionType) ?? .other
                    Text(type.displayName)
                        .font(.headline)
                }

                Spacer()

                if let date = context.meetingDate {
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Location
            if let location = context.locationName {
                HStack {
                    Image(systemName: "mappin")
                        .foregroundColor(.gray)
                        .font(.caption)
                    Text(location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            // Relationship
            if let relationshipType = context.relationshipType {
                let type = RelationshipType(rawValue: relationshipType) ?? .contact
                Text(type.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(type.color.opacity(0.2))
                    .foregroundColor(type.color)
                    .cornerRadius(8)
            }

            // Notes
            if let notes = context.notes {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Follow-up indicator
            if context.followUpRequired {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Follow-up needed")
                        .font(.caption)
                        .foregroundColor(.orange)
                    if let followUpDate = context.followUpDate {
                        Text("by \(followUpDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Contact Info Row

struct ContactInfoRow: View {

    let icon: String
    let label: String
    let value: String
    var isLink: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isLink {
                    Link(value, destination: linkURL)
                        .font(.body)
                } else {
                    Text(value)
                        .font(.body)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
        NavigationView {
            ContactDetailView(contact: .sample)
        }
    }
}
#endif
