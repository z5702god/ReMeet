import Foundation

/// Meeting context model matching the public.meeting_contexts table
struct MeetingContext: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let contactId: UUID

    // Meeting details
    var meetingDate: Date?
    var meetingTime: Date?
    var locationName: String?
    var locationAddress: String?
    var locationLat: Double?
    var locationLng: Double?

    // Event/occasion
    var eventName: String?
    var occasionType: String?

    // Relationship
    var relationshipType: String?
    var conversationTopics: [String]?
    var notes: String?

    // AI insights
    var aiSummary: String?
    var aiExtractedMetadata: [String: Any]?

    // Follow-up
    var followUpRequired: Bool
    var followUpDate: Date?
    var followUpNotes: String?

    // Timestamps
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case contactId = "contact_id"
        case meetingDate = "meeting_date"
        case meetingTime = "meeting_time"
        case locationName = "location_name"
        case locationAddress = "location_address"
        case locationLat = "location_lat"
        case locationLng = "location_lng"
        case eventName = "event_name"
        case occasionType = "occasion_type"
        case relationshipType = "relationship_type"
        case conversationTopics = "conversation_topics"
        case notes
        case aiSummary = "ai_summary"
        case aiExtractedMetadata = "ai_extracted_metadata"
        case followUpRequired = "follow_up_required"
        case followUpDate = "follow_up_date"
        case followUpNotes = "follow_up_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        contactId = try container.decode(UUID.self, forKey: .contactId)
        meetingDate = try container.decodeIfPresent(Date.self, forKey: .meetingDate)
        meetingTime = try container.decodeIfPresent(Date.self, forKey: .meetingTime)
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        locationAddress = try container.decodeIfPresent(String.self, forKey: .locationAddress)
        locationLat = try container.decodeIfPresent(Double.self, forKey: .locationLat)
        locationLng = try container.decodeIfPresent(Double.self, forKey: .locationLng)
        eventName = try container.decodeIfPresent(String.self, forKey: .eventName)
        occasionType = try container.decodeIfPresent(String.self, forKey: .occasionType)
        relationshipType = try container.decodeIfPresent(String.self, forKey: .relationshipType)
        conversationTopics = try container.decodeIfPresent([String].self, forKey: .conversationTopics)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        aiSummary = try container.decodeIfPresent(String.self, forKey: .aiSummary)
        followUpRequired = try container.decode(Bool.self, forKey: .followUpRequired)
        followUpDate = try container.decodeIfPresent(Date.self, forKey: .followUpDate)
        followUpNotes = try container.decodeIfPresent(String.self, forKey: .followUpNotes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        // Decode JSON object
        if let metadata = try container.decodeIfPresent(Data.self, forKey: .aiExtractedMetadata) {
            aiExtractedMetadata = try? JSONSerialization.jsonObject(with: metadata) as? [String: Any]
        }
    }
}

// MARK: - Sample Data

#if DEBUG
extension MeetingContext {
    static let sample = MeetingContext(
        id: UUID(),
        userId: UUID(),
        contactId: UUID(),
        meetingDate: Date(),
        meetingTime: Date(),
        locationName: "Tech Summit 2024",
        locationAddress: "Moscone Center, San Francisco",
        locationLat: 37.7749,
        locationLng: -122.4194,
        eventName: "Tech Summit",
        occasionType: "conference",
        relationshipType: "client",
        conversationTopics: ["AI", "Product Development"],
        notes: "Great conversation about future collaboration",
        aiSummary: nil,
        aiExtractedMetadata: nil,
        followUpRequired: true,
        followUpDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
        followUpNotes: "Send product demo",
        createdAt: Date(),
        updatedAt: Date()
    )
}
#endif
