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

                            // Password field
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Password")
                                    .font(AppTypography.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                SecureField("", text: $viewModel.password)
                                    .textFieldStyle(ReMeetTextFieldStyle(icon: "lock"))
                                    .textContentType(.password)
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

                            // Login button
                            Button {
                                Task {
                                    await viewModel.signIn()
                                }
                            } label: {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.accentPurple))
                                    } else {
                                        Text("Sign In")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(viewModel.canLogin ? 1.0 : 0.5))
                                .foregroundColor(AppColors.accentPurple)
                                .cornerRadius(AppCornerRadius.medium)
                            }
                            .disabled(!viewModel.canLogin || viewModel.isLoading)
                            .padding(.top, AppSpacing.sm)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.canLogin)

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
