import SwiftUI

struct DeleteAccountView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(SupabaseManager.self) var supabase
    @State private var confirmText = ""
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let confirmationWord = "DELETE"

    var canDelete: Bool {
        confirmText.uppercased() == confirmationWord
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Warning Icon
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.accentRed)
                            .padding(.top, AppSpacing.xl)

                        // Title
                        Text("Delete Account")
                            .font(AppTypography.title1)
                            .foregroundColor(AppColors.textPrimary)

                        // Warning Message
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("This action is permanent and cannot be undone.")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.accentRed)

                            Text("Deleting your account will:")
                                .font(AppTypography.body)
                                .foregroundColor(AppColors.textPrimary)

                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                warningItem("Remove all your saved contacts")
                                warningItem("Delete all business card images")
                                warningItem("Erase all meeting notes and context")
                                warningItem("Remove your account information")
                            }
                        }
                        .padding(AppSpacing.lg)
                        .background(AppColors.accentRed.opacity(0.1))
                        .cornerRadius(AppCornerRadius.medium)
                        .padding(.horizontal, AppSpacing.md)

                        // Confirmation Input
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("To confirm, type \"\(confirmationWord)\" below:")
                                .font(AppTypography.subheadline)
                                .foregroundColor(AppColors.textSecondary)

                            TextField("", text: $confirmText)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(AppCornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                        .stroke(
                                            confirmText.isEmpty ? AppColors.divider :
                                                (canDelete ? AppColors.accentRed : AppColors.accentOrange),
                                            lineWidth: 1
                                        )
                                )
                                .autocapitalization(.allCharacters)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        // Delete Button
                        Button {
                            Task {
                                await deleteAccount()
                            }
                        } label: {
                            HStack {
                                if isDeleting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "trash.fill")
                                    Text("Delete My Account")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canDelete ? AppColors.accentRed : AppColors.accentRed.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(AppCornerRadius.medium)
                            .fontWeight(.semibold)
                        }
                        .disabled(!canDelete || isDeleting)
                        .padding(.horizontal, AppSpacing.lg)

                        // Cancel hint
                        Text("Changed your mind? Tap Cancel to go back safely.")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xl)

                        Spacer(minLength: AppSpacing.xxl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func warningItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(AppColors.accentRed)
                .font(.caption)

            Text(text)
                .font(AppTypography.subheadline)
                .foregroundColor(AppColors.textPrimary)
        }
    }

    private func deleteAccount() async {
        isDeleting = true

        do {
            try await supabase.deleteUserAccount()
            dismiss()
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
            showError = true
        }

        isDeleting = false
    }
}

// MARK: - Preview

#if DEBUG
struct DeleteAccountView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DeleteAccountView()
                .environment(SupabaseManager.shared)
                .preferredColorScheme(.light)
            DeleteAccountView()
                .environment(SupabaseManager.shared)
                .preferredColorScheme(.dark)
        }
    }
}
#endif
