import Foundation

/// Meeting context model matching the public.meeting_contexts table
struct MeetingContext: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let contactId: UUID

    // Meeting details
    var meetingDate: Date?
    var meetingTime: String?  // PostgreSQL time type expects "HH:mm:ss" format
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

        // Handle PostgreSQL date format (YYYY-MM-DD)
        if let dateString = try container.decodeIfPresent(String.self, forKey: .meetingDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            meetingDate = formatter.date(from: dateString)
        } else {
            meetingDate = nil
        }

        meetingTime = try container.decodeIfPresent(String.self, forKey: .meetingTime)
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

        // Handle PostgreSQL date format for followUpDate
        if let dateString = try container.decodeIfPresent(String.self, forKey: .followUpDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            followUpDate = formatter.date(from: dateString)
        } else {
            followUpDate = nil
        }

        followUpNotes = try container.decodeIfPresent(String.self, forKey: .followUpNotes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        // Skip aiExtractedMetadata decoding - JSONB from Supabase is not compatible with Data type
        // This field is not currently used in the app
        aiExtractedMetadata = nil
    }

    // Memberwise initializer for creating new instances
    init(
        id: UUID,
        userId: UUID,
        contactId: UUID,
        meetingDate: Date?,
        meetingTime: String?,
        locationName: String?,
        locationAddress: String?,
        locationLat: Double?,
        locationLng: Double?,
        eventName: String?,
        occasionType: String?,
        relationshipType: String?,
        conversationTopics: [String]?,
        notes: String?,
        aiSummary: String?,
        aiExtractedMetadata: [String: Any]?,
        followUpRequired: Bool,
        followUpDate: Date?,
        followUpNotes: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.contactId = contactId
        self.meetingDate = meetingDate
        self.meetingTime = meetingTime
        self.locationName = locationName
        self.locationAddress = locationAddress
        self.locationLat = locationLat
        self.locationLng = locationLng
        self.eventName = eventName
        self.occasionType = occasionType
        self.relationshipType = relationshipType
        self.conversationTopics = conversationTopics
        self.notes = notes
        self.aiSummary = aiSummary
        self.aiExtractedMetadata = aiExtractedMetadata
        self.followUpRequired = followUpRequired
        self.followUpDate = followUpDate
        self.followUpNotes = followUpNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom encode implementation
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(contactId, forKey: .contactId)

        // Encode meetingDate as string (PostgreSQL date format)
        if let date = meetingDate {
            try container.encode(dateFormatter.string(from: date), forKey: .meetingDate)
        }

        try container.encodeIfPresent(meetingTime, forKey: .meetingTime)
        try container.encodeIfPresent(locationName, forKey: .locationName)
        try container.encodeIfPresent(locationAddress, forKey: .locationAddress)
        try container.encodeIfPresent(locationLat, forKey: .locationLat)
        try container.encodeIfPresent(locationLng, forKey: .locationLng)
        try container.encodeIfPresent(eventName, forKey: .eventName)
        try container.encodeIfPresent(occasionType, forKey: .occasionType)
        try container.encodeIfPresent(relationshipType, forKey: .relationshipType)
        try container.encodeIfPresent(conversationTopics, forKey: .conversationTopics)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(aiSummary, forKey: .aiSummary)
        try container.encode(followUpRequired, forKey: .followUpRequired)

        // Encode followUpDate as string (PostgreSQL date format)
        if let date = followUpDate {
            try container.encode(dateFormatter.string(from: date), forKey: .followUpDate)
        }

        try container.encodeIfPresent(followUpNotes, forKey: .followUpNotes)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)

        // Skip aiExtractedMetadata encoding - not used in the app
        // If needed in the future, use a proper JSONB-compatible encoding
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
        meetingTime: "14:30:00",
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
