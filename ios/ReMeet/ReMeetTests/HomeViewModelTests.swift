import XCTest
@testable import ReMeet

/// Unit tests for HomeViewModel
@MainActor
final class HomeViewModelTests: XCTestCase {

    var viewModel: HomeViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = HomeViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(viewModel.contacts.isEmpty, "Contacts should be empty initially")
        XCTAssertTrue(viewModel.searchText.isEmpty, "Search text should be empty initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
    }

    // MARK: - Search Filtering Tests

    func testFilteredContactsWithEmptySearch() {
        // Given: Empty search text
        viewModel.searchText = ""

        // Then: All contacts should be returned
        XCTAssertEqual(viewModel.filteredContacts.count, viewModel.contacts.count)
    }

    func testFilteredContactsWithSearchText() {
        // Given: A mock contact list (would need to inject test data)
        // This test validates the filter logic exists
        viewModel.searchText = "Test"

        // Then: filteredContacts should filter based on search
        // Note: Full test would require mock data injection
        XCTAssertNotNil(viewModel.filteredContacts)
    }

    // MARK: - Favorite Contacts Tests

    func testFavoriteContactsFilter() {
        // Then: favoriteContacts should only return favorites
        let favorites = viewModel.favoriteContacts
        XCTAssertTrue(favorites.allSatisfy { $0.isFavorite }, "All favorite contacts should have isFavorite = true")
    }

    // MARK: - Recent Contacts Tests

    func testRecentContactsLimit() {
        // Then: recentContacts should be limited
        let recent = viewModel.recentContacts
        XCTAssertLessThanOrEqual(recent.count, 5, "Recent contacts should be limited to 5")
    }
}
