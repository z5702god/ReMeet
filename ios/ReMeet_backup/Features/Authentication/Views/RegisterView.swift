import SwiftUI

struct RegisterView: View {

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

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // Header with animation
                        VStack(spacing: AppSpacing.md) {
                            ReMeetLogo(size: 100, showText: false)

                            Text("Create Account")
                                .font(AppTypography.largeTitle)
                                .foregroundColor(.white)

                            Text("Join Re:Meet and never forget a connection")
                                .font(AppTypography.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, AppSpacing.lg)
                        .scaleEffect(headerScale)
                        .onAppear {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                headerScale = 1.0
                            }
                        }

                        // Registration form with fade-in animation
                        VStack(spacing: AppSpacing.lg) {
                            // Full name field
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Full Name")
                                    .font(AppTypography.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                TextField("", text: $viewModel.fullName)
                                    .textFieldStyle(ReMeetTextFieldStyle(icon: "person"))
                                    .textContentType(.name)
                            }

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

                            // Password field
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                HStack {
                                    Text("Password")
                                        .font(AppTypography.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)

                                    Spacer()

                                    if !viewModel.password.isEmpty {
                                        Image(systemName: viewModel.isPasswordValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(viewModel.isPasswordValid ? AppColors.accentGreen : AppColors.accentRed)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }

                                SecureField("", text: $viewModel.password)
                                    .textFieldStyle(ReMeetTextFieldStyle(icon: "lock"))
                                    .textContentType(.newPassword)

                                if !viewModel.password.isEmpty && !viewModel.isPasswordValid {
                                    Text("At least 8 characters")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.accentRed.opacity(0.9))
                                        .transition(.opacity)
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: viewModel.isPasswordValid)

                            // Confirm password field
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                HStack {
                                    Text("Confirm Password")
                                        .font(AppTypography.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)

                                    Spacer()

                                    if !viewModel.confirmPassword.isEmpty {
                                        Image(systemName: viewModel.passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(viewModel.passwordsMatch ? AppColors.accentGreen : AppColors.accentRed)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }

                                SecureField("", text: $viewModel.confirmPassword)
                                    .textFieldStyle(ReMeetTextFieldStyle(icon: "lock"))
                                    .textContentType(.newPassword)

                                if !viewModel.confirmPassword.isEmpty && !viewModel.passwordsMatch {
                                    Text("Passwords do not match")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.accentRed.opacity(0.9))
                                        .transition(.opacity)
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: viewModel.passwordsMatch)

                            // Sign up button
                            Button {
                                Task {
                                    await viewModel.signUp()
                                }
                            } label: {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Create Account")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(viewModel.canRegister ? 1.0 : 0.5))
                                .foregroundColor(AppColors.accentPurple)
                                .cornerRadius(AppCornerRadius.medium)
                            }
                            .disabled(!viewModel.canRegister || viewModel.isLoading)
                            .padding(.top, AppSpacing.sm)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.canRegister)

                            // Terms and privacy
                            Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                                .font(AppTypography.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.horizontal, 30)
                        .opacity(formOpacity)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                                formOpacity = 1.0
                            }
                        }

                        Spacer()
                    }
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
                    if viewModel.errorMessage?.contains("Account created") == true {
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
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RegisterView()
                .preferredColorScheme(.light)
            RegisterView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif
