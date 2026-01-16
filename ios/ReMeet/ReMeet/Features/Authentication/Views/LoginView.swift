import SwiftUI

struct LoginView: View {

    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = AuthViewModel()
    @State private var showRegister = false
    @State private var showForgotPassword = false
    @State private var logoScale: CGFloat = 0.8
    @State private var formOpacity: Double = 0

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient - uses DesignSystem
                AppColors.authGradient(colorScheme: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        Spacer(minLength: 60)

                        // Logo and title with animation
                        VStack(spacing: AppSpacing.md) {
                            ReMeetLogo(size: 140, showText: true)
                                .scaleEffect(logoScale)

                            Text("Never forget a connection")
                                .font(AppTypography.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.bottom, 40)
                        .onAppear {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                logoScale = 1.0
                            }
                        }

                        // Login form with fade-in animation
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

                            // Password field with show/hide toggle
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Password")
                                    .font(AppTypography.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                SecureTextFieldWithToggle(
                                    placeholder: "Enter password",
                                    text: $viewModel.password,
                                    icon: "lock"
                                )
                            }

                            // Forgot password button
                            Button {
                                showForgotPassword = true
                            } label: {
                                Text("Forgot Password?")
                                    .font(AppTypography.footnote)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)

                            // Login button with loading state
                            LoadingButton(
                                title: "Sign In",
                                isLoading: viewModel.isLoading,
                                isEnabled: viewModel.canLogin
                            ) {
                                Task {
                                    await viewModel.signIn()
                                }
                            }
                            .padding(.top, AppSpacing.sm)

                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 1)

                                Text("OR")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, AppSpacing.sm)

                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, AppSpacing.sm)

                            // Sign up button
                            Button {
                                HapticManager.shared.lightImpact()
                                showRegister = true
                            } label: {
                                HStack {
                                    Text("Don't have an account?")
                                        .foregroundColor(.white.opacity(0.9))
                                    Text("Sign Up")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(AppCornerRadius.medium)
                            }
                            .accessibleButton(label: "Sign up for a new account")
                        }
                        .padding(.horizontal, 30)
                        .opacity(formOpacity)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                                formOpacity = 1.0
                            }
                        }

                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {
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

// MARK: - Custom TextField Style

struct ReMeetTextFieldStyle: TextFieldStyle {
    let icon: String
    @Environment(\.colorScheme) private var colorScheme

    func _body(configuration: TextField<Self._Label>) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)

            configuration
                .foregroundColor(.white)
        }
        .padding()
        .background(colorScheme == .dark ? AppColors.inputBackground : Color.white.opacity(0.2))
        .cornerRadius(AppCornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                .stroke(colorScheme == .dark ? AppColors.inputBorder : Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .preferredColorScheme(.light)
            LoginView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif
