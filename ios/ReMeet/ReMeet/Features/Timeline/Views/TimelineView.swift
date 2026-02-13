import SwiftUI

struct TimelineView: View {

    @State private var viewModel = TimelineViewModel()
    @State private var contentOpacity: Double = 0

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

    // MARK: - Grouped Timeline Scroll View

    private var timelineScrollView: some View {
        let grouped = viewModel.contactsGroupedByDay

        return ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(grouped, id: \.date) { group in
                    Section {
                        ForEach(group.contacts) { contact in
                            NavigationLink {
                                ContactDetailView(contact: contact)
                            } label: {
                                TimelineContactRow(contact: contact)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        TimelineDateHeader(
                            date: group.date,
                            count: group.contacts.count,
                            isToday: viewModel.isToday(group.date)
                        )
                    }
                }
            }
            .opacity(contentOpacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    contentOpacity = 1.0
                }
            }
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
        .background(AppColors.background)
    }
}

// MARK: - Timeline Date Header (Pinned Section Header)

struct TimelineDateHeader: View {

    let date: Date
    let count: Int
    let isToday: Bool

    private let calendar = Calendar.current

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.sm) {
            // Day number badge
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(isToday ? .white : AppColors.textPrimary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isToday ? AppColors.accentBlue : Color.clear)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(dayOfWeekString)
                    .font(AppTypography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isToday ? AppColors.accentBlue : AppColors.textPrimary)

                Text(fullDateString)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Text("\(count)")
                .font(AppTypography.caption)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(AppColors.divider)
                .clipShape(Capsule())
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.background.opacity(0.95))
        .background(.ultraThinMaterial)
    }

    private var dayOfWeekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Timeline Contact Row (Full-Width Card)

struct TimelineContactRow: View {

    let contact: Contact

    var body: some View {
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

            // Time added
            Text(timeString)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.large)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: contact.createdAt)
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
