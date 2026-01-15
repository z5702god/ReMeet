import SwiftUI

struct TimelineView: View {

    @State private var viewModel = TimelineViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Month selector header
                    MonthSelectorView(
                        monthString: viewModel.selectedMonthString,
                        onPrevious: { viewModel.previousMonth() },
                        onNext: { viewModel.nextMonth() },
                        onToday: { viewModel.goToCurrentMonth() }
                    )

                    Divider()
                        .background(AppColors.divider)

                    // Content
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading...")
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                    } else if viewModel.contactsForSelectedMonth.isEmpty {
                        emptyStateView
                    } else {
                        timelineScrollView
                    }
                }
            }
            .navigationTitle("Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadContacts()
            }
            .task {
                await viewModel.loadContacts()
            }
        }
    }

    // MARK: - Timeline Scroll View

    private var timelineScrollView: some View {
        let monthContacts = viewModel.contactsForSelectedMonth

        return ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(monthContacts.indices, id: \.self) { index in
                    let contact = monthContacts[index]
                    let isLast = index == monthContacts.count - 1
                    let isFirstOfDay = isFirstContactOfDay(at: index, in: monthContacts)

                    NavigationLink {
                        ContactDetailView(contact: contact)
                    } label: {
                        TimelineRowView(
                            contact: contact,
                            showDate: isFirstOfDay,
                            isLast: isLast,
                            isToday: viewModel.isToday(contact.createdAt)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, AppSpacing.md)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "rectangle.stack")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))

            Text("No Cards This Month")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textSecondary)

            Text("Business cards added in \(viewModel.selectedMonthString) will appear here")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Helper

    private func isFirstContactOfDay(at index: Int, in contacts: [Contact]) -> Bool {
        guard index > 0, index < contacts.count else { return true }
        let contact = contacts[index]
        let previousContact = contacts[index - 1]
        return !Calendar.current.isDate(contact.createdAt, inSameDayAs: previousContact.createdAt)
    }
}

// MARK: - Month Selector View

struct MonthSelectorView: View {

    let monthString: String
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.accentBlue)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Button(action: onToday) {
                Text(monthString)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.accentBlue)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.cardBackground)
    }
}

// MARK: - Timeline Row View

struct TimelineRowView: View {

    let contact: Contact
    let showDate: Bool
    let isLast: Bool
    let isToday: Bool

    private let calendar = Calendar.current

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left: Date column
            dateColumn
                .frame(width: 50)

            // Middle: Timeline line with dot
            timelineColumn
                .frame(width: 30)

            // Right: Contact card
            contactCard
                .padding(.trailing, AppSpacing.md)

            Spacer(minLength: 0)
        }
        .padding(.leading, AppSpacing.md)
    }

    // MARK: - Date Column

    private var dateColumn: some View {
        VStack {
            if showDate {
                Text("\(calendar.component(.day, from: contact.createdAt))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(isToday ? AppColors.accentBlue : AppColors.textPrimary)

                Text(weekdayString)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(height: 80, alignment: .top)
        .padding(.top, AppSpacing.xs)
    }

    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: contact.createdAt)
    }

    // MARK: - Timeline Column

    private var timelineColumn: some View {
        VStack(spacing: 0) {
            // Dot
            Circle()
                .fill(isToday ? AppColors.accentBlue : AppColors.textSecondary.opacity(0.5))
                .frame(width: 12, height: 12)
                .padding(.top, AppSpacing.sm)

            // Vertical line
            if !isLast {
                Rectangle()
                    .fill(AppColors.divider)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
    }

    // MARK: - Contact Card

    private var contactCard: some View {
        HStack(spacing: AppSpacing.md) {
            // Avatar
            AvatarView(name: contact.fullName, size: 44)

            // Info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(contact.fullName)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                if let titleWithCompany = contact.titleWithCompany {
                    Text(titleWithCompany)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.medium)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        .frame(minHeight: 70)
    }
}

// MARK: - Preview

#if DEBUG
struct TimelineView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimelineView()
                .preferredColorScheme(.light)
            TimelineView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif
