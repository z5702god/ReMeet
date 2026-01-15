import SwiftUI

struct CompanyDetailView: View {

    let companyWithContacts: CompanyWithContacts

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            List {
                // Company header
                Section {
                    companyHeader
                }
                .listRowBackground(Color.clear)

                // Company info
                if hasCompanyInfo {
                    Section("Company Info") {
                        if let industry = companyWithContacts.company.industry {
                            CompanyInfoRow(icon: "building", label: "Industry", value: industry)
                        }

                        if let website = companyWithContacts.company.website {
                            CompanyInfoRow(icon: "globe", label: "Website", value: website, isLink: true)
                        }

                        if let description = companyWithContacts.company.description {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text("About")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)

                                Text(description)
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .padding(.vertical, AppSpacing.xs)
                        }
                    }
                }

                // Contacts list
                Section("Contacts (\(companyWithContacts.contactCount))") {
                    ForEach(companyWithContacts.contacts) { contact in
                        NavigationLink {
                            ContactDetailView(contact: contact)
                        } label: {
                            CompanyContactRow(contact: contact)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(companyWithContacts.company.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Company Header

    private var companyHeader: some View {
        VStack(spacing: AppSpacing.md) {
            // Logo
            companyLogo

            // Name
            Text(companyWithContacts.company.name)
                .font(AppTypography.title2)
                .foregroundColor(AppColors.textPrimary)

            // Stats
            HStack(spacing: AppSpacing.xl) {
                VStack {
                    Text("\(companyWithContacts.contactCount)")
                        .font(AppTypography.title1)
                        .foregroundColor(AppColors.accentBlue)

                    Text("Contacts")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                if let lastInteraction = companyWithContacts.lastInteraction {
                    VStack {
                        Text(lastInteraction, format: .dateTime.month(.abbreviated).day())
                            .font(AppTypography.title3)
                            .foregroundColor(AppColors.accentGreen)

                        Text("Last Contact")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.md)
    }

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
                            .frame(width: 80, height: 80)
                            .cornerRadius(AppCornerRadius.large)
                    case .failure:
                        logoPlaceholder
                    @unknown default:
                        logoPlaceholder
                    }
                }
            } else {
                logoPlaceholder
            }
        }
    }

    private var logoPlaceholder: some View {
        RoundedRectangle(cornerRadius: AppCornerRadius.large)
            .fill(AppColors.avatarGradient(for: companyWithContacts.company.name))
            .frame(width: 80, height: 80)
            .overlay(
                Text(companyWithContacts.initials)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    private var hasCompanyInfo: Bool {
        companyWithContacts.company.industry != nil ||
        companyWithContacts.company.website != nil ||
        companyWithContacts.company.description != nil
    }
}

// MARK: - Company Info Row

struct CompanyInfoRow: View {

    let icon: String
    let label: String
    let value: String
    var isLink: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(AppColors.accentBlue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

                if isLink, let url = URL(string: value.hasPrefix("http") ? value : "https://\(value)") {
                    Link(value, destination: url)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.accentBlue)
                } else {
                    Text(value)
                        .font(AppTypography.body)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Company Contact Row

struct CompanyContactRow: View {

    let contact: Contact

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Avatar
            AvatarView(name: contact.fullName, size: 44)

            // Contact info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(contact.fullName)
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                if let title = contact.title {
                    Text(title)
                        .font(AppTypography.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            // Quick actions
            HStack(spacing: AppSpacing.md) {
                if let phone = contact.phone {
                    Button {
                        if let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "phone.fill")
                            .foregroundColor(AppColors.accentGreen)
                    }
                }

                if let email = contact.email {
                    Button {
                        if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(AppColors.accentBlue)
                    }
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Preview

#if DEBUG
struct CompanyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                CompanyDetailView(
                    companyWithContacts: CompanyWithContacts(
                        company: .sample,
                        contacts: [.sample],
                        lastInteraction: Date()
                    )
                )
            }
            .preferredColorScheme(.light)

            NavigationView {
                CompanyDetailView(
                    companyWithContacts: CompanyWithContacts(
                        company: .sample,
                        contacts: [.sample],
                        lastInteraction: Date()
                    )
                )
            }
            .preferredColorScheme(.dark)
        }
    }
}
#endif
