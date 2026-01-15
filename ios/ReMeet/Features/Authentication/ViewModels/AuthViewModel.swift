import Foundation
import SwiftUI

/// Authentication view model
/// Handles user authentication logic
@Observable
@MainActor
final class AuthViewModel {

    // MARK: - Form Properties

    var email = ""
    var password = ""
    var fullName = ""
    var confirmPassword = ""

    var isLoading = false
    var errorMessage: String?
    var showError = false

    // MARK: - Dependencies

    private let supabase = SupabaseClient.shared

    // MARK: - Computed Properties

    /// Validates email format using regex pattern
    /// Requires: local@domain.tld format with valid characters
    var isEmailValid: Bool {
        guard !email.isEmpty else { return false }

        // RFC 5322 simplified email regex
        let emailPattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)

        return emailPredicate.evaluate(with: email)
    }

    /// Validates password strength
    /// Requires: minimum 8 characters, at least one uppercase, one lowercase, one number
    var isPasswordValid: Bool {
        guard password.count >= 8 else { return false }

        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil

        return hasUppercase && hasLowercase && hasNumber
    }

    /// User-friendly password requirement description
    var passwordRequirements: String {
        "Password must be at least 8 characters with uppercase, lowercase, and a number"
    }

    var passwordsMatch: Bool {
        password == confirmPassword
    }

    var canLogin: Bool {
        isEmailValid && !password.isEmpty
    }

    var canRegister: Bool {
        isEmailValid && isPasswordValid && passwordsMatch && !fullName.isEmpty
    }

    // MARK: - Authentication Methods

    /// Sign in with email and password
    func signIn() async {
        guard canLogin else {
            showError(message: "Please enter a valid email and password")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await supabase.signIn(email: email, password: password)
            // Success - auth state listener will handle navigation
        } catch {
            showError(message: "Login failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Sign up with email, password, and full name
    func signUp() async {
        guard canRegister else {
            if !isEmailValid {
                showError(message: "Please enter a valid email address")
            } else if !isPasswordValid {
                showError(message: passwordRequirements)
            } else if !passwordsMatch {
                showError(message: "Passwords do not match")
            } else if fullName.isEmpty {
                showError(message: "Please enter your full name")
            }
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await supabase.signUp(
                email: email,
                password: password,
                fullName: fullName
            )

            // Show success message
            showError(message: "Account created! Please check your email to verify your account.")

            // Clear form
            clearForm()
        } catch {
            showError(message: "Sign up failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Sign out current user
    func signOut() async {
        isLoading = true

        do {
            try await supabase.signOut()
        } catch {
            showError(message: "Sign out failed: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// Send password reset email
    func resetPassword() async {
        guard isEmailValid else {
            showError(message: "Please enter a valid email address")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.resetPassword(email: email)
            showError(message: "Password reset email sent! Check your inbox.")
        } catch {
            showError(message: "Failed to send reset email: \(error.localizedDescription)")
        }

        isLoading = false
    }

    // MARK: - Helper Methods

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }

    func clearForm() {
        email = ""
        password = ""
        fullName = ""
        confirmPassword = ""
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }
}
