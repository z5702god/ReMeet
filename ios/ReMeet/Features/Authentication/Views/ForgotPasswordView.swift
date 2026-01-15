import SwiftUI

struct ForgotPasswordView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = AuthViewModel()
    @State private var headerScale: CGFloat = 0.9
    @State private var formOpacity: Double = 0

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient - uses DesignSystem
                AppColors.authGradient(colorScheme: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: AppSpacing.xl) {
                    Spacer()

                    // Header with animation
                    VStack(spacing: AppSpacing.md) {
                        ReMeetLogo(size: 100, showText: false)

                        Text("Reset Password")
                            .font(AppTypography.largeTitle)
                            .foregroundColor(.white)

                        Text("Enter your email address and we'll send you a link to reset your password")
                            .font(AppTypography.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .scaleEffect(headerScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            headerScale = 1.0
                        }
                    }

                    // Form with fade-in animation
                    VStack(spacing: AppSpacing.lg) {
                        // Email field
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Email")
                                .font(AppTypography.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            TextField("", text: $viewModel.email)
                                .textFieldStyle(ReMeetTextFieldStyle(icon: "envelope"))
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }

                        // Send reset link button
                        Button {
                            Task {
                                await viewModel.resetPassword()
                            }
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentPurple))
                                } else {
                                    Text("Send Reset Link")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(viewModel.isEmailValid ? 1.0 : 0.5))
                            .foregroundColor(AppColors.accentPurple)
                            .cornerRadius(AppCornerRadius.medium)
                        }
                        .disabled(!viewModel.isEmailValid || viewModel.isLoading)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isEmailValid)
                    }
                    .padding(.horizontal, 30)
                    .opacity(formOpacity)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                            formOpacity = 1.0
                        }
                    }

                    Spacer()
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                    }
                }
            }
            .alert("Message", isPresented: $viewModel.showError) {
                Button("OK") {
                    if viewModel.errorMessage?.contains("sent") == true {
                        dismiss()
                    }
                    viewModel.clearError()
                }
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForgotPasswordView()
                .preferredColorScheme(.light)
            ForgotPasswordView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif
