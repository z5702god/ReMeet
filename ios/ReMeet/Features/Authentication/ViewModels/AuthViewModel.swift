import Foundation
import SwiftUI

/// Authentication view model
/// Handles user authentication logic
@MainActor
class AuthViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var confirmPassword = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Dependencies

    private let supabase = SupabaseClient.shared

    // MARK: - Computed Properties

    var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    var isPasswordValid: Bool {
        password.count >= 8
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
                showError(message: "Password must be at least 8 characters")
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
