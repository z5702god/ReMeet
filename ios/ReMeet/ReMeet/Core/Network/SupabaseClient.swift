import Foundation
import Supabase
import Functions

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

// MARK: - Company Update (excludes computed fields)

private struct CompanyUpdate: Encodable {
    let name: String
    let industry: String?
    let website: String?
    let logoUrl: String?
    let description: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case name
        case industry
        case website
        case logoUrl = "logo_url"
        case description
        case updatedAt = "updated_at"
    }
}

// MARK: - Contact Update (excludes joined fields)

private struct ContactUpdate: Encodable {
    let fullName: String
    let title: String?
    let department: String?
    let companyId: UUID?
    let phone: String?
    let email: String?
    let website: String?
    let address: String?
    let linkedinUrl: String?
    let twitterUrl: String?
    let isFavorite: Bool
    let notes: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case title
        case department
        case companyId = "company_id"
        case phone
        case email
        case website
        case address
        case linkedinUrl = "linkedin_url"
        case twitterUrl = "twitter_url"
        case isFavorite = "is_favorite"
        case notes
        case updatedAt = "updated_at"
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

    /// Whether we're still checking for an existing session
    var isCheckingSession = true

    // MARK: - Initialization

    private init() {
        // Initialize Supabase client using config
        self.client = Supabase.SupabaseClient(
            supabaseURL: SupabaseConfig.supabaseURL,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )

        // Check existing session and setup listener
        Task {
            await checkExistingSession()
            await setupAuthStateListener()
        }
    }

    /// Check for existing session on app launch
    private func checkExistingSession() async {
        do {
            let session = try await client.auth.session
            self.isAuthenticated = true
            await loadCurrentUser(session.user.id)
            print("Restored existing session for user: \(session.user.id)")
        } catch {
            // No existing session or session expired
            self.isAuthenticated = false
            self.currentUser = nil
            print("No existing session: \(error.localizedDescription)")
        }
        self.isCheckingSession = false
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
            ],
            redirectTo: URL(string: "remeet://auth-callback")
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
        // Get current user ID
        guard let userId = currentUser?.id else {
            print("🗑️ Delete account: No current user")
            throw NSError(domain: "SupabaseClient", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }

        print("🗑️ Delete account: Starting deletion for user: \(userId)")

        // Get current session to ensure we have a valid token
        do {
            let session = try await client.auth.session
            print("🗑️ Delete account: Session valid, access token length: \(session.accessToken.count)")
        } catch {
            print("🗑️ Delete account: No valid session - \(error)")
            throw NSError(domain: "SupabaseClient", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "Session expired. Please sign in again."
            ])
        }

        // Use Supabase SDK to invoke the edge function
        do {
            let response = try await client.functions.invoke(
                "delete-user",
                options: FunctionInvokeOptions(
                    body: ["confirm": true]
                )
            )

            print("🗑️ Delete account: Response received")

            // Clear local state and sign out
            try? await client.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            print("🗑️ Delete account: Success!")

        } catch {
            print("🗑️ Delete account: Error - \(error)")
            throw NSError(domain: "SupabaseClient", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Failed to delete account: \(error.localizedDescription)"
            ])
        }
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
        // Only send updateable fields (exclude joined 'company' object)
        let updateData = ContactUpdate(
            fullName: contact.fullName,
            title: contact.title,
            department: contact.department,
            companyId: contact.companyId,
            phone: contact.phone,
            email: contact.email,
            website: contact.website,
            address: contact.address,
            linkedinUrl: contact.linkedinUrl,
            twitterUrl: contact.twitterUrl,
            isFavorite: contact.isFavorite,
            notes: contact.notes,
            updatedAt: Date()
        )

        try await client
            .from("contacts")
            .update(updateData)
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

        if let card = cards.first {
            print("🖼️ Business card found, imageUrl: \(card.imageUrl)")
        } else {
            print("🖼️ No business card found for id: \(contactId)")
        }

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

    // MARK: - Edge Function Warmup

    /// Pre-warm Edge Functions to avoid cold start delay
    func warmupEdgeFunctions() async {
        guard let session = try? await client.auth.session else { return }

        let functions = ["ocr-scan", "parse-card"]
        for name in functions {
            let functionURL = SupabaseConfig.supabaseURL
                .appendingPathComponent("functions")
                .appendingPathComponent("v1")
                .appendingPathComponent(name)

            var request = URLRequest(url: functionURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 10
            request.httpBody = try? JSONSerialization.data(withJSONObject: ["warmup": true])

            _ = try? await URLSession.shared.data(for: request)
        }
        print("🔥 Edge Functions warmed up")
    }

    // MARK: - Company Methods

    /// Create or find a company by name (with fuzzy matching)
    func findOrCreateCompany(name: String) async throws -> Company {
        // Step 1: Exact case-insensitive match
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

        // Step 2: Fuzzy match using pg_trgm similarity
        do {
            struct SimilarCompany: Codable {
                let id: UUID
                let name: String
                let similarity: Double
            }

            let result = try await client
                .rpc("find_similar_company", params: ["search_name": name])
                .execute()

            let similar = try JSONDecoder().decode([SimilarCompany].self, from: result.data)

            if let best = similar.first {
                print("🏢 Fuzzy matched '\(name)' → '\(best.name)' (similarity: \(best.similarity))")
                let matched: [Company] = try await client
                    .from("companies")
                    .select()
                    .eq("id", value: best.id.uuidString)
                    .limit(1)
                    .execute()
                    .value
                if let company = matched.first {
                    return company
                }
            }
        } catch {
            print("🏢 Fuzzy match failed, creating new: \(error.localizedDescription)")
        }

        // Step 3: Create new company
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

    /// Update company
    func updateCompany(_ company: Company) async throws {
        let update = CompanyUpdate(
            name: company.name,
            industry: company.industry,
            website: company.website,
            logoUrl: company.logoUrl,
            description: company.description,
            updatedAt: Date()
        )
        try await client
            .from("companies")
            .update(update)
            .eq("id", value: company.id.uuidString)
            .execute()
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
