import Foundation
import SwiftUI

/// ViewModel for meeting context input
@MainActor
class MeetingContextViewModel: ObservableObject {

    // MARK: - Form Fields

    @Published var meetingDate = Date()
    @Published var locationName = ""
    @Published var locationAddress = ""
    @Published var eventName = ""
    @Published var occasionType: OccasionType = .networking
    @Published var relationshipType: RelationshipType = .contact
    @Published var notes = ""
    @Published var followUpRequired = false
    @Published var followUpDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()

    // MARK: - State

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didSaveSuccessfully = false

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared

    // MARK: - Validation

    var isFormValid: Bool {
        // Meeting context is optional, so always valid
        true
    }

    // MARK: - Save Methods

    func saveMeetingContext(forContactId contactId: UUID) async throws -> MeetingContext {
        guard let userId = supabase.currentUser?.id else {
            throw NSError(domain: "MeetingContext", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }

        let context = MeetingContext(
            id: UUID(),
            userId: userId,
            contactId: contactId,
            meetingDate: meetingDate,
            meetingTime: meetingDate,
            locationName: locationName.isEmpty ? nil : locationName.trimmingCharacters(in: .whitespaces),
            locationAddress: locationAddress.isEmpty ? nil : locationAddress.trimmingCharacters(in: .whitespaces),
            locationLat: nil,
            locationLng: nil,
            eventName: eventName.isEmpty ? nil : eventName.trimmingCharacters(in: .whitespaces),
            occasionType: occasionType.rawValue,
            relationshipType: relationshipType.rawValue,
            conversationTopics: nil,
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
            aiSummary: nil,
            aiExtractedMetadata: nil,
            followUpRequired: followUpRequired,
            followUpDate: followUpRequired ? followUpDate : nil,
            followUpNotes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        return try await supabase.createMeetingContext(context)
    }

    // MARK: - Reset

    func reset() {
        meetingDate = Date()
        locationName = ""
        locationAddress = ""
        eventName = ""
        occasionType = .networking
        relationshipType = .contact
        notes = ""
        followUpRequired = false
        followUpDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        errorMessage = nil
        didSaveSuccessfully = false
    }
}

// MARK: - Occasion Types

enum OccasionType: String, CaseIterable, Identifiable {
    case networking = "networking"
    case conference = "conference"
    case meeting = "meeting"
    case social = "social"
    case referral = "referral"
    case coldOutreach = "cold_outreach"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .networking: return "Networking Event"
        case .conference: return "Conference"
        case .meeting: return "Business Meeting"
        case .social: return "Social Event"
        case .referral: return "Referral"
        case .coldOutreach: return "Cold Outreach"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .networking: return "person.3"
        case .conference: return "building.columns"
        case .meeting: return "briefcase"
        case .social: return "cup.and.saucer"
        case .referral: return "arrow.triangle.branch"
        case .coldOutreach: return "envelope"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Relationship Types

enum RelationshipType: String, CaseIterable, Identifiable {
    case client = "client"
    case prospect = "prospect"
    case partner = "partner"
    case investor = "investor"
    case vendor = "vendor"
    case colleague = "colleague"
    case mentor = "mentor"
    case contact = "contact"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .client: return "Client"
        case .prospect: return "Prospect"
        case .partner: return "Partner"
        case .investor: return "Investor"
        case .vendor: return "Vendor"
        case .colleague: return "Colleague"
        case .mentor: return "Mentor"
        case .contact: return "Contact"
        case .other: return "Other"
        }
    }

    var color: Color {
        switch self {
        case .client: return .green
        case .prospect: return .blue
        case .partner: return .purple
        case .investor: return .orange
        case .vendor: return .teal
        case .colleague: return .indigo
        case .mentor: return .pink
        case .contact: return .gray
        case .other: return .gray
        }
    }
}
