import Foundation
import SwiftUI

/// Home view model
/// Manages contacts list and search
@Observable
@MainActor
final class HomeViewModel {

    // MARK: - Properties

    var contacts: [Contact] = []
    var searchQuery = ""
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let supabase = SupabaseClient.shared

    // MARK: - Computed Properties

    /// Contacts filtered by search query
    var filteredContacts: [Contact] {
        if searchQuery.isEmpty {
            return contacts
        }

        return contacts.filter { contact in
            contact.fullName.localizedCaseInsensitiveContains(searchQuery) ||
            contact.companyName?.localizedCaseInsensitiveContains(searchQuery) == true ||
            contact.email?.localizedCaseInsensitiveContains(searchQuery) == true
        }
    }

    /// Recent contacts (last 7 days)
    var recentContacts: [Contact] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return contacts.filter { contact in
            contact.createdAt > weekAgo
        }.prefix(5).map { $0 }
    }

    /// Favorite contacts
    var favoriteContacts: [Contact] {
        contacts.filter { $0.isFavorite }
    }

    // MARK: - Methods

    /// Load all contacts
    func loadContacts() async {
        isLoading = true
        errorMessage = nil

        do {
            contacts = try await supabase.fetchContacts()
        } catch {
            errorMessage = "Failed to load contacts: \(error.localizedDescription)"
            print("Error loading contacts: \(error)")
        }

        isLoading = false
    }

    /// Search contacts using full-text search
    func searchContacts() async {
        guard !searchQuery.isEmpty else {
            await loadContacts()
            return
        }

        isLoading = true

        do {
            contacts = try await supabase.searchContacts(query: searchQuery)
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            print("Error searching contacts: \(error)")
        }

        isLoading = false
    }

    /// Delete contact
    func deleteContact(_ contact: Contact) async {
        do {
            try await supabase.deleteContact(id: contact.id)
            contacts.removeAll { $0.id == contact.id }
        } catch {
            errorMessage = "Failed to delete contact: \(error.localizedDescription)"
            print("Error deleting contact: \(error)")
        }
    }

    /// Toggle favorite status
    func toggleFavorite(_ contact: Contact) async {
        var updatedContact = contact
        updatedContact.isFavorite.toggle()

        do {
            try await supabase.updateContact(updatedContact)

            // Update local copy
            if let index = contacts.firstIndex(where: { $0.id == contact.id }) {
                contacts[index] = updatedContact
            }
        } catch {
            errorMessage = "Failed to update contact: \(error.localizedDescription)"
            print("Error updating contact: \(error)")
        }
    }
}
