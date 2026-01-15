import Foundation

/// Contact model matching the public.contacts table
struct Contact: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var cardId: UUID?
    var companyId: UUID?

    // Contact information
    var fullName: String
    var title: String?
    var department: String?
    var phone: String?
    var email: String?
    var website: String?
    var address: String?

    // Social media
    var linkedinUrl: String?
    var twitterUrl: String?

    // OCR and verification
    var ocrConfidenceScore: Double?
    var isVerified: Bool

    // Favorite
    var isFavorite: Bool

    // Tags and notes
    var tags: [String]?
    var notes: String?

    // Timestamps
    let createdAt: Date
    var updatedAt: Date
    var lastContactedAt: Date?

    // Related data (from joins)
    var company: Company?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case cardId = "card_id"
        case companyId = "company_id"
        case fullName = "full_name"
        case title
        case department
        case phone
        case email
        case website
        case address
        case linkedinUrl = "linkedin_url"
        case twitterUrl = "twitter_url"
        case ocrConfidenceScore = "ocr_confidence_score"
        case isVerified = "is_verified"
        case isFavorite = "is_favorite"
        case tags
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastContactedAt = "last_contacted_at"
        case company
    }
}

// MARK: - Computed Properties

extension Contact {
    /// Company name (if available)
    var companyName: String? {
        company?.name
    }

    /// Full title with company
    var titleWithCompany: String? {
        guard let title = title else { return companyName }
        guard let company = companyName else { return title }
        return "\(title) at \(company)"
    }

    /// Initials for avatar
    var initials: String {
        let components = fullName.components(separatedBy: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined()
    }
}

// MARK: - Sample Data

#if DEBUG
extension Contact {
    static let sample = Contact(
        id: UUID(),
        userId: UUID(),
        cardId: nil,
        companyId: nil,
        fullName: "John Doe",
        title: "Product Manager",
        department: "Product",
        phone: "+1 234 567 8900",
        email: "john.doe@example.com",
        website: "https://example.com",
        address: "123 Main St, San Francisco, CA",
        linkedinUrl: nil,
        twitterUrl: nil,
        ocrConfidenceScore: 0.95,
        isVerified: true,
        isFavorite: false,
        tags: ["client", "tech"],
        notes: "Met at TechCrunch 2024",
        createdAt: Date(),
        updatedAt: Date(),
        lastContactedAt: nil,
        company: Company.sample
    )
}
#endif
