import SwiftUI
import Combine
import Supabase

struct ChatView: View {

    @State private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Chat Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: AppSpacing.md) {
                                // Welcome Message
                                if viewModel.messages.isEmpty {
                                    welcomeView
                                }

                                // Messages with animation
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                        .transition(.asymmetric(
                                            insertion: .move(edge: message.isFromUser ? .trailing : .leading)
                                                .combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }
                                .animation(.easeOut(duration: 0.3), value: viewModel.messages.count)

                                // Loading indicator with animation
                                if viewModel.isLoading {
                                    HStack {
                                        ProgressView()
                                            .padding(.horizontal, AppSpacing.md)
                                        Text("Thinking...")
                                            .font(AppTypography.subheadline)
                                            .foregroundColor(AppColors.textSecondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, AppSpacing.md)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }

                                // Search Results with animation
                                if !viewModel.searchResults.isEmpty {
                                    SearchResultsView(
                                        contacts: viewModel.searchResults,
                                        onSelect: { contact in
                                            viewModel.selectedContact = contact
                                        }
                                    )
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                }
                            }
                            .padding(AppSpacing.md)
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            if let lastMessage = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    Divider()
                        .background(AppColors.divider)

                    // Input Area
                    inputArea
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.clearChat()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(AppColors.accentRed)
                    }
                    .disabled(viewModel.messages.isEmpty)
                }
            }
            .sheet(item: $viewModel.selectedContact) { contact in
                NavigationView {
                    ContactDetailView(contact: contact)
                }
            }
            .task {
                await viewModel.loadContacts()
            }
        }
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(AppColors.primaryGradient)

            Text("How can I help you?")
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)

            Text("Ask me about your contacts, meetings, or search by name, company, or event.")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)

            // Quick Suggestions
            VStack(spacing: AppSpacing.md) {
                Text("Try asking:")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

                ForEach(viewModel.suggestions, id: \.self) { suggestion in
                    Button {
                        messageText = suggestion
                        sendMessage()
                    } label: {
                        Text(suggestion)
                            .font(AppTypography.subheadline)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(AppColors.glassGradient)
                            .foregroundColor(AppColors.accentBlue)
                            .cornerRadius(AppCornerRadius.large)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                                    .stroke(AppColors.divider, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.top, AppSpacing.lg)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Input Area

    private var inputArea: some View {
        HStack(spacing: AppSpacing.sm) {
            TextField("Ask me anything...", text: $messageText)
                .textFieldStyle(.plain)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 12)
                .background(AppColors.divider)
                .cornerRadius(AppCornerRadius.full)
                .focused($isInputFocused)
                .onSubmit {
                    sendMessage()
                }

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        messageText.isEmpty
                            ? AnyShapeStyle(AppColors.textSecondary)
                            : AnyShapeStyle(AppColors.buttonGradient)
                    )
            }
            .disabled(messageText.isEmpty || viewModel.isLoading)
        }
        .padding(AppSpacing.md)
        .background(AppColors.background)
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let text = messageText
        messageText = ""
        isInputFocused = false

        Task {
            await viewModel.sendMessage(text)
        }
    }
}

// MARK: - Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date

    init(content: String, isFromUser: Bool) {
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = Date()
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }

            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: AppSpacing.xs) {
                Text(message.content)
                    .font(AppTypography.body)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(message.isFromUser ? AnyShapeStyle(AppColors.buttonGradient) : AnyShapeStyle(AppColors.divider))
                    .foregroundColor(message.isFromUser ? .white : AppColors.textPrimary)
                    .cornerRadius(18)
                    .shadow(color: message.isFromUser ? Color(hex: "4A9FFF").opacity(0.2) : Color.clear, radius: 8, x: 0, y: 4)

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: 280, alignment: message.isFromUser ? .trailing : .leading)

            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

// MARK: - Search Results View

private struct SearchResultsView: View {
    let contacts: [Contact]
    let onSelect: (Contact) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Found \(contacts.count) contact\(contacts.count == 1 ? "" : "s"):")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)

            ForEach(contacts) { contact in
                Button {
                    onSelect(contact)
                } label: {
                    SearchResultCard(contact: contact)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .stroke(AppColors.divider, lineWidth: 1)
        )
    }
}

// MARK: - Search Result Card

private struct SearchResultCard: View {
    let contact: Contact

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Avatar
            AvatarView(name: contact.fullName, size: 44)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.fullName)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                if let title = contact.title {
                    Text(title)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                if let company = contact.company?.name {
                    Text(company)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.textSecondary)
                .font(.caption)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.large)
    }
}

// MARK: - Chat API Response Model

struct ChatAPIResponse: Codable {
    let success: Bool
    let responseText: String
    let contacts: [ChatContactResult]
    let contactCount: Int
    let intent: String?
    let suggestedActions: [String]?

    enum CodingKeys: String, CodingKey {
        case success
        case responseText = "response_text"
        case contacts
        case contactCount = "contact_count"
        case intent
        case suggestedActions = "suggested_actions"
    }
}

struct ChatContactResult: Codable, Identifiable {
    let id: UUID
    let fullName: String
    let title: String?
    let email: String?
    let phone: String?
    let companyName: String?
    let isFavorite: Bool?
    let meetingContext: ChatMeetingContext?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case title
        case email
        case phone
        case companyName = "company_name"
        case isFavorite = "is_favorite"
        case meetingContext = "meeting_context"
    }
}

struct ChatMeetingContext: Codable {
    let date: String?
    let location: String?
    let event: String?
    let occasionType: String?
    let relationshipType: String?

    enum CodingKeys: String, CodingKey {
        case date
        case location
        case event
        case occasionType = "occasion_type"
        case relationshipType = "relationship_type"
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var searchResults: [Contact] = []
    var chatResults: [ChatContactResult] = []
    var isLoading = false
    var selectedContact: Contact?
    var useAIBackend = true  // Toggle for AI vs local search

    private var contacts: [Contact] = []
    private let supabase = SupabaseManager.shared

    let suggestions = [
        "Who did I meet recently?",
        "上個月認識的人",
        "Find contacts from Google",
        "Who needs follow-up?"
    ]

    func loadContacts() async {
        do {
            contacts = try await supabase.fetchContacts()
        } catch {
            print("Failed to load contacts: \(error)")
        }
    }

    func sendMessage(_ text: String) async {
        // Add user message
        let userMessage = ChatMessage(content: text, isFromUser: true)
        messages.append(userMessage)

        // Clear previous results
        searchResults = []
        chatResults = []

        isLoading = true

        if useAIBackend {
            // Use n8n AI backend
            await sendToAIBackend(text)
        } else {
            // Fallback to local search
            try? await Task.sleep(nanoseconds: 500_000_000)
            let response = processQueryLocally(text)
            let aiMessage = ChatMessage(content: response, isFromUser: false)
            messages.append(aiMessage)
        }

        isLoading = false
    }

    // MARK: - AI Backend Integration

    private func sendToAIBackend(_ text: String) async {
        guard let userId = supabase.currentUser?.id else {
            let errorMessage = ChatMessage(content: "Please sign in to use AI search.", isFromUser: false)
            messages.append(errorMessage)
            return
        }

        let requestBody: [String: Any] = [
            "user_id": userId.uuidString,
            "message": text
        ]

        do {
            let response = try await callChatAPI(body: requestBody)

            print("🟡 API returned \(response.contacts.count) contacts")

            // Store chat results for display
            chatResults = response.contacts

            // Convert to Contact objects for compatibility with existing UI
            searchResults = response.contacts.compactMap { chatContact in
                print("🟠 Converting contact: \(chatContact.fullName)")
                return convertToContact(from: chatContact)
            }

            print("🟢 searchResults count: \(searchResults.count)")

            // Add AI response message (show count if contacts found)
            let responseText = searchResults.isEmpty
                ? response.responseText
                : response.responseText
            let aiMessage = ChatMessage(content: responseText, isFromUser: false)
            messages.append(aiMessage)

        } catch {
            print("AI backend error: \(error)")
            // Fallback to local search on error
            let response = processQueryLocally(text)
            let aiMessage = ChatMessage(content: response, isFromUser: false)
            messages.append(aiMessage)
        }
    }

    private func callChatAPI(body: [String: Any]) async throws -> ChatAPIResponse {
        let url = SupabaseConfig.n8nChatAPIURL

        // Get JWT token from Supabase session for authentication
        guard let session = try? await supabase.client.auth.session else {
            throw URLError(.userAuthenticationRequired)
        }
        let accessToken = session.accessToken

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // Debug: Print raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔵 Chat API Response: \(jsonString)")
        }

        // Handle authentication errors
        if httpResponse.statusCode == 401 {
            throw URLError(.userAuthenticationRequired)
        }

        guard httpResponse.statusCode == 200 else {
            print("❌ Chat API Error: Status \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(ChatAPIResponse.self, from: data)
        print("🟢 Decoded \(apiResponse.contacts.count) contacts")
        return apiResponse
    }

    private func convertToContact(from chatContact: ChatContactResult) -> Contact? {
        // Create a Contact object from ChatContactResult for UI compatibility
        return Contact(
            id: chatContact.id,
            userId: supabase.currentUser?.id ?? UUID(),
            cardId: nil,
            companyId: nil,
            fullName: chatContact.fullName,
            title: chatContact.title,
            department: nil,
            phone: chatContact.phone,
            email: chatContact.email,
            website: nil,
            address: nil,
            linkedinUrl: nil,
            twitterUrl: nil,
            ocrConfidenceScore: nil,
            isVerified: true,
            isFavorite: chatContact.isFavorite ?? false,
            tags: nil,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date(),
            lastContactedAt: nil,
            company: chatContact.companyName != nil ? Company(
                id: UUID(),
                name: chatContact.companyName!,
                industry: nil,
                logoUrl: nil,
                website: nil,
                description: nil,
                createdAt: Date(),
                updatedAt: Date()
            ) : nil
        )
    }

    func clearChat() {
        messages = []
        searchResults = []
        chatResults = []
    }

    // MARK: - Local Search (Fallback)

    private func processQueryLocally(_ query: String) -> String {
        let lowercasedQuery = query.lowercased()

        // Check for name search
        if lowercasedQuery.contains("find") || lowercasedQuery.contains("search") ||
           lowercasedQuery.contains("who") || lowercasedQuery.contains("show") ||
           lowercasedQuery.contains("找") || lowercasedQuery.contains("搜") {

            let results = searchContactsLocally(query: query)

            if !results.isEmpty {
                searchResults = results
                return "I found \(results.count) matching contact\(results.count == 1 ? "" : "s"). Tap on any card to view details."
            }
        }

        // Check for recent contacts
        if lowercasedQuery.contains("recent") || lowercasedQuery.contains("lately") ||
           lowercasedQuery.contains("last") || lowercasedQuery.contains("最近") {
            let recentContacts = contacts
                .sorted { $0.createdAt > $1.createdAt }
                .prefix(5)

            if !recentContacts.isEmpty {
                searchResults = Array(recentContacts)
                return "Here are your \(recentContacts.count) most recent contacts."
            }
        }

        // Check for follow-up
        if lowercasedQuery.contains("follow") || lowercasedQuery.contains("remind") {
            return "Follow-up reminders are tracked in the Timeline view."
        }

        // General search as fallback
        let generalResults = searchContactsLocally(query: query)
        if !generalResults.isEmpty {
            searchResults = generalResults
            return "I found \(generalResults.count) result\(generalResults.count == 1 ? "" : "s") matching '\(query)'."
        }

        return "I couldn't find any contacts matching your query. Try searching by name or company."
    }

    private func searchContactsLocally(query: String) -> [Contact] {
        let searchTerms = query.lowercased()
            .replacingOccurrences(of: "find", with: "")
            .replacingOccurrences(of: "search", with: "")
            .replacingOccurrences(of: "show", with: "")
            .replacingOccurrences(of: "who", with: "")
            .replacingOccurrences(of: "me", with: "")
            .replacingOccurrences(of: "contacts", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard !searchTerms.isEmpty else { return [] }

        return contacts.filter { contact in
            contact.fullName.lowercased().contains(searchTerms) ||
            (contact.title?.lowercased().contains(searchTerms) ?? false) ||
            (contact.company?.name.lowercased().contains(searchTerms) ?? false) ||
            (contact.email?.lowercased().contains(searchTerms) ?? false)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ChatView()
                .preferredColorScheme(.light)
            ChatView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif
