import SwiftUI

struct PrivacyPolicyView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        // Last updated
                        Text("Last updated: January 2025")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)

                        // Introduction
                        policySection(
                            title: "Introduction",
                            content: """
                            Re:Meet ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.
                            """
                        )

                        // Information We Collect
                        policySection(
                            title: "Information We Collect",
                            content: """
                            We collect the following types of information:

                            • Account Information: Email address and name when you create an account.

                            • Business Card Data: Photos of business cards you scan, and contact information extracted from them (names, phone numbers, email addresses, job titles, company names).

                            • Meeting Context: Notes and context you add about when and where you met contacts.

                            • Device Information: Basic device identifiers for app functionality.
                            """
                        )

                        // How We Use Your Information
                        policySection(
                            title: "How We Use Your Information",
                            content: """
                            We use your information to:

                            • Provide and maintain the Re:Meet service
                            • Store and organize your business card contacts
                            • Enable search and retrieval of your contacts
                            • Improve our app and user experience
                            • Send important service notifications
                            """
                        )

                        // Data Storage
                        policySection(
                            title: "Data Storage & Security",
                            content: """
                            Your data is securely stored using Supabase, a trusted cloud infrastructure provider. We implement industry-standard security measures including:

                            • Encrypted data transmission (HTTPS/TLS)
                            • Secure authentication
                            • Regular security updates

                            Your business card images are stored in secure cloud storage and are only accessible to you.
                            """
                        )

                        // Data Sharing
                        policySection(
                            title: "Data Sharing",
                            content: """
                            We do not sell, trade, or rent your personal information to third parties. We may share data only:

                            • With your explicit consent
                            • To comply with legal obligations
                            • To protect our rights or safety
                            """
                        )

                        // Your Rights
                        policySection(
                            title: "Your Rights",
                            content: """
                            You have the right to:

                            • Access your personal data
                            • Correct inaccurate data
                            • Delete your account and all associated data
                            • Export your data
                            • Withdraw consent at any time

                            To exercise these rights, use the settings within the app or contact us.
                            """
                        )

                        // Data Retention
                        policySection(
                            title: "Data Retention",
                            content: """
                            We retain your data for as long as your account is active. When you delete your account, all your personal data, including business card images and contact information, will be permanently deleted within 30 days.
                            """
                        )

                        // Children's Privacy
                        policySection(
                            title: "Children's Privacy",
                            content: """
                            Re:Meet is not intended for use by children under 13. We do not knowingly collect personal information from children under 13.
                            """
                        )

                        // Changes
                        policySection(
                            title: "Changes to This Policy",
                            content: """
                            We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy in the app and updating the "Last updated" date.
                            """
                        )

                        // Contact
                        policySection(
                            title: "Contact Us",
                            content: """
                            If you have any questions about this Privacy Policy, please contact us through the app's Help & Support section.
                            """
                        )

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(AppSpacing.lg)
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Text(content)
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(4)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PrivacyPolicyView()
                .preferredColorScheme(.light)
            PrivacyPolicyView()
                .preferredColorScheme(.dark)
        }
    }
}
#endif
