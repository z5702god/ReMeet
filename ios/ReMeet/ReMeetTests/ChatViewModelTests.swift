import XCTest
@testable import ReMeet

/// Unit tests for ChatViewModel
@MainActor
final class ChatViewModelTests: XCTestCase {

    var viewModel: ChatViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = ChatViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(viewModel.messages.isEmpty, "Messages should be empty initially")
        XCTAssertTrue(viewModel.searchResults.isEmpty, "Search results should be empty initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.selectedContact, "No contact should be selected initially")
    }

    // MARK: - Message Tests

    func testClearChat() {
        // Given: Some messages exist
        // When: Clear chat is called
        viewModel.clearChat()

        // Then: Messages should be empty
        XCTAssertTrue(viewModel.messages.isEmpty, "Messages should be cleared")
        XCTAssertTrue(viewModel.searchResults.isEmpty, "Search results should be cleared")
    }

    // MARK: - Suggestions Tests

    func testSuggestionsNotEmpty() {
        XCTAssertFalse(viewModel.suggestions.isEmpty, "Should have predefined suggestions")
    }

    func testSuggestionsContainExpectedQueries() {
        let suggestions = viewModel.suggestions
        XCTAssertTrue(suggestions.count >= 2, "Should have at least 2 suggestions")
    }

    // MARK: - AI Backend Toggle Tests

    func testUseAIBackendDefault() {
        XCTAssertTrue(viewModel.useAIBackend, "AI backend should be enabled by default")
    }
}
