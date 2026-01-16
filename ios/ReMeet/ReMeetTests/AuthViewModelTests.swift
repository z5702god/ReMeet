import XCTest
@testable import ReMeet

/// Unit tests for AuthViewModel
@MainActor
final class AuthViewModelTests: XCTestCase {

    var viewModel: AuthViewModel!

    override func setUp() async throws {
        try await super.setUp()
        viewModel = AuthViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(viewModel.email.isEmpty, "Email should be empty initially")
        XCTAssertTrue(viewModel.password.isEmpty, "Password should be empty initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil initially")
    }

    // MARK: - Email Validation Tests

    func testValidEmail() {
        viewModel.email = "test@example.com"
        XCTAssertTrue(viewModel.isEmailValid, "Valid email should pass validation")
    }

    func testInvalidEmail() {
        viewModel.email = "invalid-email"
        XCTAssertFalse(viewModel.isEmailValid, "Invalid email should fail validation")
    }

    func testEmptyEmail() {
        viewModel.email = ""
        XCTAssertFalse(viewModel.isEmailValid, "Empty email should fail validation")
    }

    // MARK: - Password Validation Tests

    func testValidPassword() {
        viewModel.password = "password123"
        XCTAssertTrue(viewModel.isPasswordValid, "Password with 8+ characters should be valid")
    }

    func testShortPassword() {
        viewModel.password = "short"
        XCTAssertFalse(viewModel.isPasswordValid, "Password with less than 8 characters should be invalid")
    }

    func testEmptyPassword() {
        viewModel.password = ""
        XCTAssertFalse(viewModel.isPasswordValid, "Empty password should be invalid")
    }

    // MARK: - Form Validation Tests

    func testFormValidWithValidInputs() {
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        XCTAssertTrue(viewModel.isFormValid, "Form should be valid with valid email and password")
    }

    func testFormInvalidWithInvalidEmail() {
        viewModel.email = "invalid"
        viewModel.password = "password123"
        XCTAssertFalse(viewModel.isFormValid, "Form should be invalid with invalid email")
    }

    func testFormInvalidWithShortPassword() {
        viewModel.email = "test@example.com"
        viewModel.password = "short"
        XCTAssertFalse(viewModel.isFormValid, "Form should be invalid with short password")
    }
}
