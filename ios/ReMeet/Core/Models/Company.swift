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
}

// MARK: - Sample Data

#if DEBUG
extension Company {
    static let sample = Company(
        id: UUID(),
        name: "Anthropic",
        industry: "AI Research",
        website: "https://anthropic.com",
        logoUrl: nil,
        description: "AI safety and research company",
        createdAt: Date(),
        updatedAt: Date(),
        contactCount: 5,
        lastInteraction: Date()
    )
}
#endif
