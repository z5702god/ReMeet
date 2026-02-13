import SwiftUI

struct AddContactView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = AddContactViewModel()
    @State private var formOpacity: Double = 0

    // Optional: callback when contact is saved
    var onSave: (() -> Void)?

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Basic Info Section
                        formSection(title: "Basic Information") {
                            VStack(spacing: AppSpacing.md) {
                                formTextField(
                                    icon: "person",
                                    placeholder: "Full Name *",
                                    text: $viewModel.fullName
                                )
                                .textContentType(.name)
                                .autocapitalization(.words)

                                formTextField(
                                    icon: "briefcase",
                                    placeholder: "Job Title",
                                    text: $viewModel.title
                                )
                                .textContentType(.jobTitle)
                            }
                        }

                        // Company Section
                        formSection(title: "Company") {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                formTextField(
                                    icon: "building.2",
                                    placeholder: "Company Name",
                                    text: $viewModel.companyName
                                )
                                .textContentType(.organizationName)
                                .onChange(of: viewModel.companyName) { _, _ in
                                    viewModel.clearCompanySelection()
                                    Task {
                                        await viewModel.searchCompanies()
                                    }
                                }

                                if viewModel.isSearchingCompanies {
                                    HStack(spacing: AppSpacing.sm) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Searching...")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    .padding(.leading, AppSpacing.sm)
                                }

                                // Company suggestions with animation
                                if !viewModel.companySuggestions.isEmpty {
                                    ScrollView {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(viewModel.companySuggestions) { company in
                                            Button {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    viewModel.selectCompany(company)
                                                }
                                                HapticManager.shared.lightImpact()
                                            } label: {
                                                HStack(spacing: AppSpacing.sm) {
                                                    Image(systemName: "building.2")
                                                        .foregroundColor(AppColors.accentBlue)
                                                        .frame(width: 24)
                                                    Text(company.name)
                                                        .font(AppTypography.body)
                                                        .foregroundColor(AppColors.textPrimary)
                                                    Spacer()
                                                    if viewModel.selectedCompany?.id == company.id {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundColor(AppColors.accentGreen)
                                                            .transition(.scale.combined(with: .opacity))
                                                    }
                                                }
                                                .padding(.vertical, AppSpacing.sm)
                                                .padding(.horizontal, AppSpacing.md)
                                            }

                                            if company.id != viewModel.companySuggestions.last?.id {
                                                Divider()
                                                    .background(AppColors.divider)
                                                    .padding(.leading, 40)
                                            }
                                        }
                                    }
                                    .background(AppColors.cardBackground)
                                    .cornerRadius(AppCornerRadius.large)
                                    }
                                    .frame(maxHeight: 200)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }

                                if viewModel.selectedCompany != nil {
                                    HStack(spacing: AppSpacing.xs) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppColors.accentGreen)
                                        Text("Company selected")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    .padding(.leading, AppSpacing.sm)
                                    .transition(.opacity)
                                }
                            }
                        }

                        // Contact Details Section
                        formSection(title: "Contact Details") {
                            VStack(spacing: AppSpacing.md) {
                                formTextField(
                                    icon: "phone",
                                    placeholder: "Phone",
                                    text: $viewModel.phone
                                )
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)

                                formTextField(
                                    icon: "envelope",
                                    placeholder: "Email",
                                    text: $viewModel.email
                                )
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)

                                formTextField(
                                    icon: "globe",
                                    placeholder: "Website",
                                    text: $viewModel.website
                                )
                                .textContentType(.URL)
                                .keyboardType(.URL)
                                .autocapitalization(.none)

                                formTextField(
                                    icon: "location",
                                    placeholder: "Address",
                                    text: $viewModel.address,
                                    axis: .vertical
                                )
                                .textContentType(.fullStreetAddress)
                                .lineLimit(2...4)
                            }
                        }

                        // Notes Section
                        formSection(title: "Notes") {
                            TextEditor(text: $viewModel.notes)
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)
                                .frame(minHeight: 100)
                                .padding(AppSpacing.sm)
                                .scrollContentBackground(.hidden)
                                .background(AppColors.cardBackground)
                                .cornerRadius(AppCornerRadius.large)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppCornerRadius.large)
                                        .stroke(AppColors.divider, lineWidth: 1)
                                )
                        }

                        // Error Display
                        if let error = viewModel.errorMessage {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppColors.accentRed)
                                Text(error)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.accentRed)
                            }
                            .padding(AppSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.accentRed.opacity(0.1))
                            .cornerRadius(AppCornerRadius.medium)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(AppSpacing.md)
                }
                .opacity(formOpacity)
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.saveContact()
                        }
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.isFormValid && !viewModel.isLoading ? AppColors.accentBlue : AppColors.textSecondary)
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: AppSpacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Saving...")
                            .font(AppTypography.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(AppSpacing.xl)
                    .background(AppColors.overlayBackground)
                    .cornerRadius(AppCornerRadius.large)
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                }
            }
            .onChange(of: viewModel.didSaveSuccessfully) { _, success in
                if success {
                    HapticManager.shared.success()
                    onSave?()
                    dismiss()
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    formOpacity = 1.0
                }
            }
        }
    }

    // MARK: - Form Components

    @ViewBuilder
    private func formSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 0) {
                content()
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .stroke(AppColors.divider, lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func formTextField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        axis: Axis = .horizontal
    ) -> some View {
        HStack(alignment: axis == .vertical ? .top : .center, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 24)
                .padding(.top, axis == .vertical ? 12 : 0)

            if axis == .vertical {
                TextField(placeholder, text: text, axis: .vertical)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
            } else {
                TextField(placeholder, text: text)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.large)
    }
}

// MARK: - Preview

#if DEBUG
struct AddContactView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AddContactView()
                .preferredColorScheme(.light)
            AddContactView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif
