import SwiftUI
import UIKit

// MARK: - App Colors

enum AppColors {
    // Primary gradient (Monday.com style purple)
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Header gradient (dark purple)
    static let headerGradient = LinearGradient(
        colors: [Color(hex: "2D3436"), Color(hex: "636E72")],
        startPoint: .top,
        endPoint: .bottom
    )

    // Accent colors for categories
    static let accentBlue = Color(hex: "0984E3")
    static let accentGreen = Color(hex: "00B894")
    static let accentOrange = Color(hex: "FDCB6E")
    static let accentRed = Color(hex: "D63031")
    static let accentPurple = Color(hex: "6C5CE7")
    static let accentPink = Color(hex: "E84393")

    // Adaptive colors for Light/Dark mode using dynamic provider
    static let background = Color(light: Color(hex: "F5F6FA"), dark: Color(hex: "1A1A2E"))
    static let cardBackground = Color(light: .white, dark: Color(hex: "2D2D44"))
    static let textPrimary = Color(light: Color(hex: "2D3436"), dark: .white)
    static let textSecondary = Color(light: Color(hex: "636E72"), dark: Color(hex: "A0A0B0"))
    static let divider = Color(light: Color(hex: "DFE6E9"), dark: Color(hex: "3D3D5C"))
    static let searchBackground = Color(light: Color(hex: "ECEEF1"), dark: Color(hex: "3D3D5C"))
    static let inputBackground = Color(light: Color.white.opacity(0.2), dark: Color(hex: "3D3D5C"))
    static let inputBorder = Color(light: Color.white.opacity(0.3), dark: Color(hex: "4D4D6C"))

    // Auth screen gradient colors
    static let authGradientStart = Color(light: Color(hex: "A29BFE").opacity(0.8), dark: Color(hex: "1A1A2E"))
    static let authGradientEnd = Color(light: Color(hex: "6C5CE7").opacity(0.9), dark: Color(hex: "2D2D44"))

    // Auth screen adaptive gradient
    static func authGradient(colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(hex: "1A1A2E"), Color(hex: "2D2D44")]
                : [Color(hex: "A29BFE").opacity(0.8), Color(hex: "6C5CE7").opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Avatar gradient colors
    static let avatarGradients: [[Color]] = [
        [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
        [Color(hex: "0984E3"), Color(hex: "74B9FF")],
        [Color(hex: "00B894"), Color(hex: "55EFC4")],
        [Color(hex: "FDCB6E"), Color(hex: "FFEAA7")],
        [Color(hex: "E84393"), Color(hex: "FD79A8")],
        [Color(hex: "D63031"), Color(hex: "FF7675")]
    ]

    static func avatarGradient(for name: String) -> LinearGradient {
        let index = abs(name.hashValue) % avatarGradients.count
        return LinearGradient(
            colors: avatarGradients[index],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Create a color that adapts to light/dark mode
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - App Typography

enum AppTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let title1 = Font.system(size: 28, weight: .bold)
    static let title2 = Font.system(size: 22, weight: .bold)
    static let title3 = Font.system(size: 20, weight: .semibold)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let callout = Font.system(size: 16, weight: .regular)
    static let subheadline = Font.system(size: 15, weight: .regular)
    static let footnote = Font.system(size: 13, weight: .regular)
    static let caption = Font.system(size: 12, weight: .regular)
}

// MARK: - App Spacing

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - App Corner Radius

enum AppCornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 9999
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    var padding: CGFloat = AppSpacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.medium)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

extension View {
    func cardStyle(padding: CGFloat = AppSpacing.md) -> some View {
        modifier(CardStyle(padding: padding))
    }
}

// MARK: - Section Header Style

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)?
    var actionLabel: String?

    var body: some View {
        HStack {
            Text(title)
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            if let action = action, let label = actionLabel {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(label)
                            .font(AppTypography.subheadline)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundColor(AppColors.accentBlue)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(AppColors.accentBlue)
                .clipShape(Circle())
                .shadow(color: AppColors.accentBlue.opacity(0.4), radius: 10, x: 0, y: 4)
        }
    }
}

// MARK: - Avatar View

struct AvatarView: View {
    let name: String
    let size: CGFloat
    var imageURL: String?

    init(name: String, size: CGFloat = 50, imageURL: String? = nil) {
        self.name = name
        self.size = size
        self.imageURL = imageURL
    }

    private var initials: String {
        let components = name.components(separatedBy: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.avatarGradient(for: name))
                .frame(width: size, height: size)

            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String?
    var buttonAction: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundStyle(AppColors.primaryGradient)

            VStack(spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)

                Text(message)
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }

            if let buttonTitle = buttonTitle, let action = buttonAction {
                Button(action: action) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "camera.fill")
                        Text(buttonTitle)
                    }
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.accentBlue)
                    .cornerRadius(AppCornerRadius.large)
                }
                .padding(.top, AppSpacing.md)
            }
        }
        .padding(AppSpacing.xl)
    }
}

// MARK: - Search Bar

struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "Search..."

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textSecondary)

            TextField(placeholder, text: $text)
                .font(AppTypography.body)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.searchBackground)
        .cornerRadius(AppCornerRadius.medium)
    }
}
