import Foundation
import Supabase

// MARK: - RPC Parameters

nonisolated struct MeetingTimelineParams: Encodable, Sendable {
    let userUuid: String
    let startDate: String?
    let endDate: String?

    enum CodingKeys: String, CodingKey {
        case userUuid = "user_uuid"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

/// Shared Supabase client instance
/// Handles all communication with Supabase backend
@Observable
@MainActor
final class SupabaseManager {

    // MARK: - Singleton

    static let shared = SupabaseManager()

    // MARK: - Properties

    /// Supabase client instance
    let client: Supabase.SupabaseClient

    /// Current authenticated user
    var currentUser: User?

    /// Authentication state
    var isAuthenticated = false

    // MARK: - Initialization

    private init() {
        // Initialize Supabase client using config
        self.client = Supabase.SupabaseClient(
            supabaseURL: SupabaseConfig.supabaseURL,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )

        // Setup auth state listener
        Task {
            await setupAuthStateListener()
        }
    }

    // MARK: - Authentication State

    /// Setup authentication state change listener
    private func setupAuthStateListener() async {
        // Listen for auth state changes
        for await (event, session) in client.auth.authStateChanges {
            switch event {
            case .signedIn:
                self.isAuthenticated = true
                if let session = session {
                    await loadCurrentUser(session.user.id)
                }

            case .signedOut:
                self.isAuthenticated = false
                self.currentUser = nil

            case .userUpdated:
                if let session = session {
                    await loadCurrentUser(session.user.id)
                }

            default:
                break
            }
        }
    }

    /// Load current user from database
    private func loadCurrentUser(_ userId: UUID) async {
        do {
            let user: User = try await client
                .from("users")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value

            self.currentUser = user
        } catch {
            print("Error loading user: \(error)")
        }
    }

    // MARK: - Authentication Methods

    /// Sign up with email and password
    func signUp(email: String, password: String, fullName: String) async throws -> AuthResponse {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: [
                "full_name": .string(fullName)
            ]
        )
        return response
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> Session {
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )
        return session
    }

    /// Sign out current user
    func signOut() async throws {
        try await client.auth.signOut()
    }

    /// Send password reset email
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    /// Update user password
    func updatePassword(newPassword: String) async throws {
        try await client.auth.update(user: UserAttributes(password: newPassword))
    }

    /// Delete user account and all associated data
    /// Uses Edge Function to ensure complete deletion including auth.users
    func deleteUserAccount() async throws {
        // Get current session for authentication
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "SupabaseClient", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }

        // Call Edge Function to delete account
        let functionURL = SupabaseConfig.supabaseURL
            .appendingPathComponent("functions")
            .appendingPathComponent("v1")
            .appendingPathComponent("delete-user")

        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SupabaseClient", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Invalid server response"
            ])
        }

        if httpResponse.statusCode == 401 {
            throw NSError(domain: "SupabaseClient", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "Authentication required"
            ])
        }

        guard httpResponse.statusCode == 200 else {
            // Try to parse error message from response
            if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorResponse["error"] as? String {
                throw NSError(domain: "SupabaseClient", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: errorMessage
                ])
            }
            throw NSError(domain: "SupabaseClient", code: httpResponse.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Failed to delete account"
            ])
        }

        // Clear local state
        self.currentUser = nil
        self.isAuthenticated = false
    }

    // MARK: - Storage Methods

    /// Upload business card image
    func uploadBusinessCard(
        image: Data,
        fileName: String
    ) async throws -> String {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseClient", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }

        // File path: {user_id}/{filename}
        let filePath = "\(userId.uuidString)/\(fileName)"

        // Upload to storage
        try await client.storage
            .from(SupabaseConfig.businessCardsBucket)
            .upload(
                filePath,
                data: image,
                options: FileOptions(
                    contentType: "image/jpeg"
                )
            )

        // Get public URL
        let url = try client.storage
            .from(SupabaseConfig.businessCardsBucket)
            .getPublicURL(path: filePath)

        return url.absoluteString
    }

    /// Delete business card image
    func deleteBusinessCard(filePath: String) async throws {
        try await client.storage
            .from(SupabaseConfig.businessCardsBucket)
            .remove(paths: [filePath])
    }

    // MARK: - Database Methods

    /// Fetch all contacts for current user
    func fetchContacts() async throws -> [Contact] {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseClient", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }

        let contacts: [Contact] = try await client
            .from("contacts")
            .select("""
                *,
                company:companies(*)
            """)
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return contacts
    }

    /// Search contacts
    func searchContacts(query: String) async throws -> [Contact] {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseClient", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }

        // Use the search_contacts function we created in SQL
        let result = try await client
            .rpc("search_contacts", params: [
                "search_query": query,
                "user_uuid": userId.uuidString
            ])
            .execute()

        return try JSONDecoder().decode([Contact].self, from: result.data)
    }

    /// Fetch companies grouped by contact count
    func fetchCompanies() async throws -> [Company] {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseClient", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }

        // Use the get_company_stats function
        let result = try await client
            .rpc("get_company_stats", params: [
                "user_uuid": userId.uuidString
            ])
            .execute()

        return try JSONDecoder().decode([Company].self, from: result.data)
    }

    /// Fetch meeting timeline
    func fetchMeetingTimeline(
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> [MeetingContext] {
        guard let userId = currentUser?.id else {
            throw NSError(domain: "SupabaseClient", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }

        let formatter = ISO8601DateFormatter()
        let params = MeetingTimelineParams(
            userUuid: userId.uuidString,
            startDate: startDate.map { formatter.string(from: $0) },
            endDate: endDate.map { formatter.string(from: $0) }
        )

        let result = try await client
            .rpc("get_meeting_timeline", params: params)
            .execute()

        return try JSONDecoder().decode([MeetingContext].self, from: result.data)
    }

    /// Insert new contact
    func createContact(_ contact: Contact) async throws -> Contact {
        let created: Contact = try await client
            .from("contacts")
            .insert(contact)
            .select()
            .single()
            .execute()
            .value

        return created
    }

    /// Update existing contact
    func updateContact(_ contact: Contact) async throws {
        try await client
            .from("contacts")
            .update(contact)
            .eq("id", value: contact.id.uuidString)
            .execute()
    }

    /// Delete contact
    func deleteContact(id: UUID) async throws {
        try await client
            .from("contacts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Business Card Methods

    /// Create a new business card record
    func createBusinessCard(_ card: BusinessCard) async throws -> BusinessCard {
        let created: BusinessCard = try await client
            .from("business_cards")
            .insert(card)
            .select()
            .single()
            .execute()
            .value

        return created
    }

    /// Fetch business card by contact ID
    func fetchBusinessCard(forContactId contactId: UUID) async throws -> BusinessCard? {
        let cards: [BusinessCard] = try await client
            .from("business_cards")
            .select()
            .eq("id", value: contactId.uuidString)
            .limit(1)
            .execute()
            .value

        return cards.first
    }

    // MARK: - Meeting Context Methods

    /// Create a new meeting context
    func createMeetingContext(_ context: MeetingContext) async throws -> MeetingContext {
        let created: MeetingContext = try await client
            .from("meeting_contexts")
            .insert(context)
            .select()
            .single()
            .execute()
            .value

        return created
    }

    /// Fetch meeting contexts for a contact
    func fetchMeetingContexts(forContactId contactId: UUID) async throws -> [MeetingContext] {
        let contexts: [MeetingContext] = try await client
            .from("meeting_contexts")
            .select()
            .eq("contact_id", value: contactId.uuidString)
            .order("meeting_date", ascending: false)
            .execute()
            .value

        return contexts
    }

    /// Update meeting context
    func updateMeetingContext(_ context: MeetingContext) async throws {
        try await client
            .from("meeting_contexts")
            .update(context)
            .eq("id", value: context.id.uuidString)
            .execute()
    }

    // MARK: - Company Methods

    /// Create or find a company by name
    func findOrCreateCompany(name: String) async throws -> Company {
        // First, try to find existing company
        let existingCompanies: [Company] = try await client
            .from("companies")
            .select()
            .ilike("name", pattern: name)
            .limit(1)
            .execute()
            .value

        if let existing = existingCompanies.first {
            return existing
        }

        // Create new company
        let newCompany = Company(
            id: UUID(),
            name: name,
            industry: nil,
            logoUrl: nil,
            website: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let created: Company = try await client
            .from("companies")
            .insert(newCompany)
            .select()
            .single()
            .execute()
            .value

        return created
    }

    /// Search companies by name
    func searchCompanies(query: String) async throws -> [Company] {
        let companies: [Company] = try await client
            .from("companies")
            .select()
            .ilike("name", pattern: "%\(query)%")
            .limit(10)
            .execute()
            .value

        return companies
    }
}

// MARK: - Error Handling

extension SupabaseManager {
    /// Convert Supabase error to user-friendly message
    static func errorMessage(from error: Error) -> String {
        // TODO: Parse specific Supabase errors
        return error.localizedDescription
    }
}

// MARK: - Type Alias for backward compatibility
typealias SupabaseClient = SupabaseManager
