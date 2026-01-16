import Foundation

/// ViewModel for Timeline view - displays contacts by creation date
@Observable
@MainActor
final class TimelineViewModel {

    // MARK: - Properties

    var contacts: [Contact] = []
    var isLoading = false
    var errorMessage: String?

    // Month navigation
    var selectedMonth: Date = Date()

    private let supabase = SupabaseManager.shared
    private let calendar = Calendar.current

    // MARK: - Computed Properties

    /// Month string for header display
    var selectedMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    /// Contacts filtered by selected month, sorted by date descending
    var contactsForSelectedMonth: [Contact] {
        contacts.filter { contact in
            calendar.isDate(contact.createdAt, equalTo: selectedMonth, toGranularity: .month)
        }.sorted { $0.createdAt > $1.createdAt }
    }

    /// Get unique dates (days) that have contacts in the selected month
    var datesWithContacts: [Date] {
        let grouped = Dictionary(grouping: contactsForSelectedMonth) { contact in
            calendar.startOfDay(for: contact.createdAt)
        }
        return grouped.keys.sorted(by: >)
    }

    /// Group contacts by day for the selected month
    var contactsGroupedByDay: [(date: Date, contacts: [Contact])] {
        let grouped = Dictionary(grouping: contactsForSelectedMonth) { contact in
            calendar.startOfDay(for: contact.createdAt)
        }
        return grouped.map { (date: $0.key, contacts: $0.value) }
            .sorted { $0.date > $1.date }
    }

    /// Check if there are any contacts in the selected month
    var hasContactsInMonth: Bool {
        !contactsForSelectedMonth.isEmpty
    }

    /// Get all months that have contacts (for navigation hints)
    var monthsWithContacts: Set<Date> {
        Set(contacts.map { contact in
            calendar.date(from: calendar.dateComponents([.year, .month], from: contact.createdAt))!
        })
    }

    // MARK: - Data Loading

    /// Load all contacts from database
    func loadContacts() async {
        isLoading = true
        errorMessage = nil

        do {
            contacts = try await supabase.fetchContacts()
        } catch {
            errorMessage = "Failed to load contacts: \(error.localizedDescription)"
            print("Timeline error: \(error)")
        }

        isLoading = false
    }

    // MARK: - Month Navigation

    func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }

    func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }

    func goToCurrentMonth() {
        selectedMonth = Date()
    }

    /// Check if the selected month has contacts
    func selectedMonthHasContacts() -> Bool {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        return monthsWithContacts.contains(monthStart)
    }

    // MARK: - Helper Methods

    /// Get day number from a date
    func dayNumber(from date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    /// Check if a date is today
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
}
