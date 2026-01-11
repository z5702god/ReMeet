import SwiftUI

struct RegisterView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(.white)

                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Join Re:Meet and never forget a connection")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)

                        // Registration form
                        VStack(spacing: 20) {
                            // Full name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                TextField("", text: $viewModel.fullName)
                                    .textFieldStyle(ReMeetTextFieldStyle(icon: "person"))
                                    .textContentType(.name)
                            }

                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                TextField("", text: $viewModel.email)
                                    .textFieldStyle(ReMeetTextFieldStyle(icon: "envelope"))
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }

                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Password")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)

                                    Spacer()

                                    if !viewModel.password.isEmpty {
                                        Image(systemName: viewModel.isPasswordValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(viewModel.isPasswordValid ? .green : .red)
                                    }
                                }

                                SecureField("", text: $viewModel.password)
                                    .textFieldStyle(ReMeetTextFieldStyle(icon: "lock"))
                                    .textContentType(.newPassword)

                                if !viewModel.password.isEmpty && !viewModel.isPasswordValid {
                                    Text("At least 8 characters")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }

                            // Confirm password field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Confirm Password")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)

                                    Spacer()

                                    if !viewModel.confirmPassword.isEmpty {
                                        Image(systemName: viewModel.passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundColor(viewModel.passwordsMatch ? .green : .red)
                                    }
                                }

                                SecureField("", text: $viewModel.confirmPassword)
                                    .textFieldStyle(ReMeetTextFieldStyle(icon: "lock"))
                                    .textContentType(.newPassword)

                                if !viewModel.confirmPassword.isEmpty && !viewModel.passwordsMatch {
                                    Text("Passwords do not match")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }

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
                                .foregroundColor(.purple)
                                .cornerRadius(12)
                            }
                            .disabled(!viewModel.canRegister || viewModel.isLoading)
                            .padding(.top, 10)

                            // Terms and privacy
                            Text("By signing up, you agree to our Terms of Service and Privacy Policy")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.horizontal, 30)

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
        RegisterView()
    }
}
#endif
