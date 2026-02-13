import SwiftUI

struct EditContactView: View {

    let contact: Contact
    var onSave: ((Contact) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var fullName: String = ""
    @State private var title: String = ""
    @State private var companyName: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var website: String = ""
    @State private var address: String = ""
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let supabase = SupabaseManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Basic Info
                        formSection(title: "Basic Information") {
                            VStack(spacing: AppSpacing.md) {
                                formTextField(icon: "person", placeholder: "Full Name", text: $fullName)
                                    .textContentType(.name)
                                    .autocapitalization(.words)

                                formTextField(icon: "briefcase", placeholder: "Job Title", text: $title)
                                    .textContentType(.jobTitle)
                            }
                        }

                        // Company
                        formSection(title: "Company") {
                            formTextField(icon: "building.2", placeholder: "Company Name", text: $companyName)
                                .textContentType(.organizationName)
                        }

                        // Contact Info
                        formSection(title: "Contact Information") {
                            VStack(spacing: AppSpacing.md) {
                                formTextField(icon: "phone", placeholder: "Phone", text: $phone)
                                    .textContentType(.telephoneNumber)
                                    .keyboardType(.phonePad)

                                formTextField(icon: "envelope", placeholder: "Email", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)

                                formTextField(icon: "globe", placeholder: "Website", text: $website)
                                    .textContentType(.URL)
                                    .keyboardType(.URL)
                                    .autocapitalization(.none)

                                formTextField(icon: "mappin.circle", placeholder: "Address", text: $address)
                                    .textContentType(.fullStreetAddress)
                            }
                        }

                        // Notes
                        formSection(title: "Notes") {
                            TextEditor(text: $notes)
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
            .navigationTitle("Edit Contact")
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
                        Task { await saveContact() }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.accentBlue)
                    .disabled(fullName.isEmpty || isSaving)
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
            loadContactData()
        }
    }

    // MARK: - Load Data

    private func loadContactData() {
        fullName = contact.fullName
        title = contact.title ?? ""
        companyName = contact.company?.name ?? ""
        phone = contact.phone ?? ""
        email = contact.email ?? ""
        website = contact.website ?? ""
        address = contact.address ?? ""
        notes = contact.notes ?? ""
    }

    // MARK: - Save

    private func saveContact() async {
        isSaving = true
        errorMessage = nil

        do {
            // Update company if changed
            var updatedCompanyId = contact.companyId
            let originalCompanyName = contact.company?.name ?? ""

            if !companyName.isEmpty && companyName != originalCompanyName {
                let company = try await supabase.findOrCreateCompany(name: companyName)
                updatedCompanyId = company.id
            } else if companyName.isEmpty {
                updatedCompanyId = nil
            }

            // Build updated contact
            var updatedContact = contact
            updatedContact.fullName = fullName
            updatedContact.title = title.isEmpty ? nil : title
            updatedContact.companyId = updatedCompanyId
            updatedContact.phone = phone.isEmpty ? nil : phone
            updatedContact.email = email.isEmpty ? nil : email
            updatedContact.website = website.isEmpty ? nil : website
            updatedContact.address = address.isEmpty ? nil : address
            updatedContact.notes = notes.isEmpty ? nil : notes
            updatedContact.updatedAt = Date()

            try await supabase.updateContact(updatedContact)

            // Rebuild with company info for UI
            if let companyId = updatedCompanyId, !companyName.isEmpty {
                updatedContact.company = Company(
                    id: companyId,
                    name: companyName,
                    createdAt: contact.company?.createdAt ?? Date(),
                    updatedAt: Date()
                )
            } else {
                updatedContact.company = nil
            }

            onSave?(updatedContact)
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
