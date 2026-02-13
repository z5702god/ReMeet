import SwiftUI

struct CompaniesListView: View {

    @State private var viewModel = CompaniesViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Content
                    if viewModel.isLoading {
                        // Skeleton loading state
                        List {
                            ForEach(0..<5, id: \.self) { _ in
                                SkeletonCompanyRow()
                                    .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    } else if viewModel.companiesWithStats.isEmpty {
                        emptyStateView
                    } else {
                        companiesListView
                    }
                }
            }
            .navigationTitle("Companies")
            .refreshable {
                await viewModel.loadData()
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Companies List

    private var companiesListView: some View {
        List {
            // Search bar
            Section {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)

                    TextField("Search companies...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)

                    if !viewModel.searchQuery.isEmpty {
                        Button {
                            viewModel.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColors.divider)
                .cornerRadius(AppCornerRadius.full)
            }
            .listRowBackground(Color.clear)

            // Stats header
            Section {
                HStack {
                    StatBadge(
                        icon: "building.2",
                        value: "\(viewModel.totalCompaniesCount)",
                        label: "Companies"
                    )

                    Spacer()

                    StatBadge(
                        icon: "person.2",
                        value: "\(viewModel.totalContactsCount)",
                        label: "Contacts"
                    )
                }
                .padding(.vertical, AppSpacing.sm)
            }
            .listRowBackground(Color.clear)

            // Companies list
            Section {
                ForEach(viewModel.filteredCompanies) { companyWithContacts in
                    NavigationLink {
                        CompanyDetailView(companyWithContacts: companyWithContacts)
                    } label: {
                        CompanyRowView(companyWithContacts: companyWithContacts)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))

            Text("No Companies Yet")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textSecondary)

            Text("Companies will appear here when you add contacts with company information")
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {

    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(AppColors.accentBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Text(label)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Company Row View

struct CompanyRowView: View {

    let companyWithContacts: CompanyWithContacts

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Company logo/initials
            companyLogo

            // Company info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(companyWithContacts.company.name)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                if let industry = companyWithContacts.company.industry {
                    Text(industry)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }

                // Contact count badge
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "person.2")
                        .font(.caption)
                        .foregroundColor(AppColors.accentBlue)

                    Text("\(companyWithContacts.contactCount) contact\(companyWithContacts.contactCount == 1 ? "" : "s")")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            // Contact avatars stack
            contactAvatarsStack
        }
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: - Company Logo

    private var companyLogo: some View {
        Group {
            if let logoUrl = companyWithContacts.company.logoUrl,
               let url = URL(string: logoUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        logoPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        logoPlaceholder
                    @unknown default:
                        logoPlaceholder
                    }
                }
                .frame(width: 50, height: 50)
                .cornerRadius(AppCornerRadius.small)
            } else {
                logoPlaceholder
            }
        }
    }

    private var logoPlaceholder: some View {
        RoundedRectangle(cornerRadius: AppCornerRadius.small)
            .fill(AppColors.avatarGradient(for: companyWithContacts.company.name))
            .frame(width: 50, height: 50)
            .overlay(
                Text(companyWithContacts.initials)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            )
    }

    // MARK: - Contact Avatars Stack

    private var contactAvatarsStack: some View {
        HStack(spacing: -8) {
            ForEach(companyWithContacts.contacts.prefix(3)) { contact in
                Circle()
                    .fill(AppColors.avatarGradient(for: contact.fullName))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(contact.initials)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(AppColors.background, lineWidth: 2)
                    )
            }

            if companyWithContacts.contactCount > 3 {
                Circle()
                    .fill(AppColors.divider)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text("+\(companyWithContacts.contactCount - 3)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                    )
                    .overlay(
                        Circle()
                            .stroke(AppColors.background, lineWidth: 2)
                    )
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CompaniesListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CompaniesListView()
                .preferredColorScheme(.light)
            CompaniesListView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif
