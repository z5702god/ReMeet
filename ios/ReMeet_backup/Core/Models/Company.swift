import Foundation

/// Company model matching the public.companies table
struct Company: Codable, Identifiable {
    let id: UUID
    var name: String
    var industry: String?
    var website: String?
    var logoUrl: String?
    var description: String?
    let createdAt: Date
    var updatedAt: Date

    // Statistics (from RPC functions)
    var contactCount: Int?
    var lastInteraction: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case industry
        case website
        case logoUrl = "logo_url"
        case description
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case contactCount = "contact_count"
        case lastInteraction = "last_interaction"
    }

    // Memberwise initializer
    init(
        id: UUID,
        name: String,
        industry: String? = nil,
        logoUrl: String? = nil,
        website: String? = nil,
        description: String? = nil,
        createdAt: Date,
        updatedAt: Date,
        contactCount: Int? = nil,
        lastInteraction: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.industry = industry
        self.logoUrl = logoUrl
        self.website = website
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.contactCount = contactCount
        self.lastInteraction = lastInteraction
    }
}

// MARK: - Sample Data

#if DEBUG
extension Company {
    static let sample = Company(
        id: UUID(),
        name: "Anthropic",
        industry: "AI Research",
        logoUrl: nil,
        website: "https://anthropic.com",
        description: "AI safety and research company",
        createdAt: Date(),
        updatedAt: Date(),
        contactCount: 5,
        lastInteraction: Date()
    )
}
#endif
