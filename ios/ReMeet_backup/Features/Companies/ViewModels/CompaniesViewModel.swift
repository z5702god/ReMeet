import Foundation

/// ViewModel for Companies list view
@Observable
@MainActor
final class CompaniesViewModel {

    // MARK: - Properties

    var contacts: [Contact] = []
    var isLoading = false
    var errorMessage: String?
    var searchQuery = ""

    private let supabase = SupabaseManager.shared

    // MARK: - Computed Properties

    /// Companies with contact counts, sorted by contact count descending
    /// Extracts companies directly from contacts (via join)
    var companiesWithStats: [CompanyWithContacts] {
        // Group contacts by their company
        let contactsWithCompany = contacts.filter { $0.company != nil }
        let groupedByCompanyId = Dictionary(grouping: contactsWithCompany) { $0.companyId! }

        return groupedByCompanyId.compactMap { (companyId, companyContacts) -> CompanyWithContacts? in
            // Get company from first contact (all contacts in group have same company)
            guard let company = companyContacts.first?.company else { return nil }

            return CompanyWithContacts(
                company: company,
                contacts: companyContacts,
                lastInteraction: companyContacts.compactMap { $0.lastContactedAt }.max()
            )
        }.sorted { $0.contacts.count > $1.contacts.count }
    }

    /// Filtered companies based on search query
    var filteredCompanies: [CompanyWithContacts] {
        guard !searchQuery.isEmpty else { return companiesWithStats }

        return companiesWithStats.filter { companyWithContacts in
            companyWithContacts.company.name.localizedCaseInsensitiveContains(searchQuery) ||
            (companyWithContacts.company.industry?.localizedCaseInsensitiveContains(searchQuery) ?? false)
        }
    }

    /// Total number of companies with contacts
    var totalCompaniesCount: Int {
        companiesWithStats.count
    }

    /// Total number of contacts across all companies
    var totalContactsCount: Int {
        contacts.filter { $0.companyId != nil }.count
    }

    // MARK: - Data Loading

    /// Load all contacts (companies are extracted from contact joins)
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // fetchContacts already includes company data via join
            contacts = try await supabase.fetchContacts()
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            print("Companies error: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Company with Contacts Model

struct CompanyWithContacts: Identifiable {
    let company: Company
    let contacts: [Contact]
    let lastInteraction: Date?

    var id: UUID { company.id }

    var contactCount: Int { contacts.count }

    /// Get initials for company logo placeholder
    var initials: String {
        let words = company.name.components(separatedBy: " ")
        let initials = words.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
}
