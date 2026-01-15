import Foundation

/// User model matching the public.users table
struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    var fullName: String?
    var avatarUrl: String?
    var preferences: [String: String]?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case preferences
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Computed Properties

extension User {
    /// Display name (fallback to email if no full name)
    var displayName: String {
        fullName ?? email
    }

    /// First name extracted from full name
    var firstName: String? {
        fullName?.components(separatedBy: " ").first
    }
}
