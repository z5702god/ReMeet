import Foundation
import SwiftUI

/// ViewModel for adding a new contact
@MainActor
class AddContactViewModel: ObservableObject {

    // MARK: - Form Fields

    @Published var fullName = ""
    @Published var title = ""
    @Published var companyName = ""
    @Published var phone = ""
    @Published var email = ""
    @Published var website = ""
    @Published var address = ""
    @Published var notes = ""

    // MARK: - Company Search

    @Published var companySuggestions: [Company] = []
    @Published var selectedCompany: Company?
    @Published var isSearchingCompanies = false

    // MARK: - State

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didSaveSuccessfully = false

    // MARK: - Dependencies

    private let supabase = SupabaseManager.shared

    // MARK: - Validation

    var isFormValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var formErrors: [String] {
        var errors: [String] = []

        if fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Name is required")
        }

        if !email.isEmpty && !isValidEmail(email) {
            errors.append("Invalid email format")
        }

        if !phone.isEmpty && !isValidPhone(phone) {
            errors.append("Invalid phone format")
        }

        return errors
    }

    // MARK: - Company Search

    func searchCompanies() async {
        let query = companyName.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else {
            companySuggestions = []
            return
        }

        isSearchingCompanies = true

        do {
            companySuggestions = try await supabase.searchCompanies(query: query)
        } catch {
            print("Error searching companies: \(error)")
            companySuggestions = []
        }

        isSearchingCompanies = false
    }

    func selectCompany(_ company: Company) {
        selectedCompany = company
        companyName = company.name
        companySuggestions = []
    }

    func clearCompanySelection() {
        selectedCompany = nil
    }

    // MARK: - Save Contact

    func saveContact() async {
        guard isFormValid else {
            errorMessage = formErrors.joined(separator: "\n")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Handle company
            var companyId: UUID?
            let trimmedCompanyName = companyName.trimmingCharacters(in: .whitespaces)

            if let selected = selectedCompany {
                companyId = selected.id
            } else if !trimmedCompanyName.isEmpty {
                // Create or find company
                let company = try await supabase.findOrCreateCompany(name: trimmedCompanyName)
                companyId = company.id
            }

            // Get current user
            guard let userId = supabase.currentUser?.id else {
                throw NSError(domain: "AddContact", code: 401, userInfo: [
                    NSLocalizedDescriptionKey: "User not authenticated"
                ])
            }

            // Create contact
            let contact = Contact(
                id: UUID(),
                userId: userId,
                cardId: nil,
                companyId: companyId,
                fullName: fullName.trimmingCharacters(in: .whitespaces),
                title: title.isEmpty ? nil : title.trimmingCharacters(in: .whitespaces),
                department: nil,
                phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespaces),
                email: email.isEmpty ? nil : email.trimmingCharacters(in: .whitespaces).lowercased(),
                website: website.isEmpty ? nil : website.trimmingCharacters(in: .whitespaces),
                address: address.isEmpty ? nil : address.trimmingCharacters(in: .whitespaces),
                linkedinUrl: nil,
                twitterUrl: nil,
                ocrConfidenceScore: nil,
                isVerified: true,
                isFavorite: false,
                tags: nil,
                notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
                createdAt: Date(),
                updatedAt: Date(),
                lastContactedAt: nil,
                company: nil
            )

            _ = try await supabase.createContact(contact)
            didSaveSuccessfully = true

        } catch {
            errorMessage = "Failed to save contact: \(error.localizedDescription)"
            print("Error saving contact: \(error)")
        }

        isLoading = false
    }

    // MARK: - Helpers

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = #"^[\d\s\-\+\(\)]{7,}$"#
        return phone.range(of: phoneRegex, options: .regularExpression) != nil
    }

    // MARK: - Reset

    func reset() {
        fullName = ""
        title = ""
        companyName = ""
        phone = ""
        email = ""
        website = ""
        address = ""
        notes = ""
        selectedCompany = nil
        companySuggestions = []
        errorMessage = nil
        didSaveSuccessfully = false
    }
}
