import SwiftUI

struct EditCompanyView: View {

    let company: Company
    var onSave: ((Company) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var industry: String = ""
    @State private var website: String = ""
    @State private var companyDescription: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let supabase = SupabaseManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        formSection(title: "Company Name") {
                            formTextField(icon: "building.2", placeholder: "Company Name", text: $name)
                                .textContentType(.organizationName)
                                .autocapitalization(.words)
                        }

                        formSection(title: "Details") {
                            VStack(spacing: AppSpacing.md) {
                                formTextField(icon: "building", placeholder: "Industry", text: $industry)

                                formTextField(icon: "globe", placeholder: "Website", text: $website)
                                    .textContentType(.URL)
                                    .keyboardType(.URL)
                                    .autocapitalization(.none)
                            }
                        }

                        formSection(title: "About") {
                            TextEditor(text: $companyDescription)
                                .frame(minHeight: 80)
                                .padding(AppSpacing.sm)
                                .scrollContentBackground(.hidden)
                                .background(AppColors.cardBackground)
                                .cornerRadius(AppCornerRadius.large)
                                .foregroundColor(AppColors.textPrimary)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.accentRed)
                                .padding(.horizontal, AppSpacing.md)
                        }
                    }
                    .padding(AppSpacing.md)
                }
            }
            .navigationTitle("Edit Company")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await saveCompany() }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.accentBlue)
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView("Saving...")
                                .padding(AppSpacing.lg)
                                .background(AppColors.overlayBackground)
                                .cornerRadius(AppCornerRadius.large)
                        }
                }
            }
        }
        .onAppear {
            loadCompanyData()
        }
    }

    // MARK: - Load Data

    private func loadCompanyData() {
        name = company.name
        industry = company.industry ?? ""
        website = company.website ?? ""
        companyDescription = company.description ?? ""
    }

    // MARK: - Save

    private func saveCompany() async {
        isSaving = true
        errorMessage = nil

        do {
            var updatedCompany = company
            updatedCompany.name = name
            updatedCompany.industry = industry.isEmpty ? nil : industry
            updatedCompany.website = website.isEmpty ? nil : website
            updatedCompany.description = companyDescription.isEmpty ? nil : companyDescription
            updatedCompany.updatedAt = Date()

            try await supabase.updateCompany(updatedCompany)

            onSave?(updatedCompany)
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }

        isSaving = false
    }

    // MARK: - Form Components

    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textSecondary)

            content()
        }
    }

    private func formTextField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(AppColors.accentBlue)
                .frame(width: 24)

            TextField(placeholder, text: text)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.large)
    }
}
