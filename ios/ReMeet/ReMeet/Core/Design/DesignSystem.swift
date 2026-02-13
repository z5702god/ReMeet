import SwiftUI
import UIKit

// MARK: - Haptic Feedback Manager

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private init() {}

    /// Light impact - for selections, toggles
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact - for button taps, confirmations
    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact - for significant actions
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Success feedback - for completed actions
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning feedback - for warnings
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error feedback - for errors
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Selection changed - for picker/segment changes
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - App Colors

enum AppColors {
    // Primary gradient (blue → purple glow)
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "4A9FFF"), Color(hex: "8B7FFF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Header gradient (deep navy)
    static let headerGradient = LinearGradient(
        colors: [Color(hex: "0A0E27"), Color(hex: "1A1F3A")],
        startPoint: .top,
        endPoint: .bottom
    )

    // Accent colors for categories
    static let accentBlue = Color(hex: "4A9FFF")
    static let accentGreen = Color(hex: "10B981")
    static let accentOrange = Color(hex: "FDCB6E")
    static let accentRed = Color(hex: "D63031")
    static let accentPurple = Color(hex: "8B7FFF")
    static let accentPink = Color(hex: "FF8FA3")

    // Adaptive colors for Light/Dark mode using dynamic provider
    static let background = Color(light: Color(hex: "F5F6FA"), dark: Color(hex: "0A0E27"))
    static let cardBackground = Color(light: .white, dark: Color.white.opacity(0.03))
    static let textPrimary = Color(light: Color(hex: "2D3436"), dark: .white)
    static let textSecondary = Color(light: Color(hex: "636E72"), dark: Color(hex: "B8C5E0"))
    static let textTertiary = Color(light: Color(hex: "8E8E93"), dark: Color(hex: "7B8CAE"))
    static let divider = Color(light: Color(hex: "DFE6E9"), dark: Color.white.opacity(0.06))
    static let searchBackground = Color(light: Color(hex: "ECEEF1"), dark: Color.white.opacity(0.06))
    static let inputBackground = Color(light: Color.white.opacity(0.2), dark: Color.white.opacity(0.03))
    static let inputBorder = Color(light: Color.white.opacity(0.3), dark: Color(hex: "2A3555"))
    static let overlayBackground = Color(light: .white, dark: Color(hex: "1E2749"))

    // Glassmorphic card gradient (for elevated cards)
    static let glassGradient = LinearGradient(
        colors: [Color(hex: "4A9FFF").opacity(0.08), Color(hex: "8B5CF6").opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Glow shadow colors
    static let glowBlue = Color(hex: "4A9FFF").opacity(0.12)
    static let glowPurple = Color(hex: "8B7FFF").opacity(0.12)

    // Auth screen gradient colors
    static let authGradientStart = Color(light: Color(hex: "4A9FFF").opacity(0.8), dark: Color(hex: "0A0E27"))
    static let authGradientEnd = Color(light: Color(hex: "8B7FFF").opacity(0.9), dark: Color(hex: "141B3C"))

    // Auth screen adaptive gradient
    static func authGradient(colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(hex: "0A0E27"), Color(hex: "141B3C")]
                : [Color(hex: "4A9FFF").opacity(0.8), Color(hex: "8B7FFF").opacity(0.9)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Screen background gradient
    static let screenGradient = LinearGradient(
        colors: [Color(hex: "0A0E27"), Color(hex: "1A1F3A")],
        startPoint: .top,
        endPoint: .bottom
    )

    // Avatar gradient colors (vibrant pairs matching design)
    static let avatarGradients: [[Color]] = [
        [Color(hex: "4A9FFF"), Color(hex: "8B5CF6")],
        [Color(hex: "EC4899"), Color(hex: "F97316")],
        [Color(hex: "10B981"), Color(hex: "06B6D4")],
        [Color(hex: "8B7FFF"), Color(hex: "EC4899")],
        [Color(hex: "F97316"), Color(hex: "FDCB6E")],
        [Color(hex: "06B6D4"), Color(hex: "4A9FFF")]
    ]

    static func avatarGradient(for name: String) -> LinearGradient {
        let index = abs(name.hashValue) % avatarGradients.count
        return LinearGradient(
            colors: avatarGradients[index],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Button gradient (blue → purple)
    static let buttonGradient = LinearGradient(
        colors: [Color(hex: "4A9FFF"), Color(hex: "8B5CF6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Green button gradient
    static let greenButtonGradient = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "06B6D4")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
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

// MARK: - Animated Button (Scale on Tap)

struct AnimatedButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label

    @State private var isPressed = false

    var body: some View {
        label()
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        action()
                    }
            )
    }
}

// MARK: - Card Style Modifier

struct CardStyle: ViewModifier {
    var padding: CGFloat = AppSpacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.cardBackground)
            .cornerRadius(AppCornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.large)
                    .stroke(AppColors.divider, lineWidth: 1)
            )
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
            Text(title.uppercased())
                .font(AppTypography.footnote)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textSecondary)
                .tracking(0.5)

            Spacer()

            if let action = action, let label = actionLabel {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text(label)
                            .font(AppTypography.subheadline)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
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
                .background(AppColors.buttonGradient)
                .clipShape(Circle())
                .shadow(color: Color(hex: "4A9FFF").opacity(0.4), radius: 16, x: 0, y: 4)
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
                .font(.system(size: size * 0.4, weight: .bold))
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
                    .background(AppColors.buttonGradient)
                    .cornerRadius(AppCornerRadius.large)
                    .shadow(color: Color(hex: "4A9FFF").opacity(0.3), radius: 16, x: 0, y: 4)
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
                .font(AppTypography.callout)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, 12)
        .background(AppColors.searchBackground)
        .cornerRadius(AppCornerRadius.full)
    }
}

// MARK: - Toast Notification

enum ToastStyle {
    case success
    case error
    case warning
    case info

    var backgroundColor: Color {
        switch self {
        case .success: return AppColors.accentGreen
        case .error: return AppColors.accentRed
        case .warning: return AppColors.accentOrange
        case .info: return AppColors.accentBlue
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct ToastView: View {
    let message: String
    let style: ToastStyle

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: style.icon)
                .font(.system(size: 20, weight: .semibold))

            Text(message)
                .font(AppTypography.subheadline)
                .lineLimit(2)

            Spacer()
        }
        .foregroundColor(.white)
        .padding(AppSpacing.md)
        .background(style.backgroundColor)
        .cornerRadius(AppCornerRadius.medium)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        .padding(.horizontal, AppSpacing.md)
    }
}

@Observable
@MainActor
final class ToastManager {
    static let shared = ToastManager()

    var currentToast: (message: String, style: ToastStyle)?
    var isShowing = false

    private init() {}

    func show(_ message: String, style: ToastStyle = .info, duration: Double = 3.0) {
        currentToast = (message, style)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isShowing = true
        }

        // Haptic feedback based on style
        switch style {
        case .success: HapticManager.shared.success()
        case .error: HapticManager.shared.error()
        case .warning: HapticManager.shared.warning()
        case .info: HapticManager.shared.lightImpact()
        }

        Task {
            try? await Task.sleep(for: .seconds(duration))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    isShowing = false
                }
            }
        }
    }
}

struct ToastContainerModifier: ViewModifier {
    @State private var toastManager = ToastManager.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if toastManager.isShowing, let toast = toastManager.currentToast {
                    ToastView(message: toast.message, style: toast.style)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 50)
                        .zIndex(999)
                }
            }
    }
}

extension View {
    func withToast() -> some View {
        modifier(ToastContainerModifier())
    }
}

// MARK: - Skeleton Loading View

struct SkeletonView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.03), Color.white.opacity(0.08), Color.white.opacity(0.03)]
                            : [Color.black.opacity(0.04), Color.black.opacity(0.08), Color.black.opacity(0.04)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
        }
        .background(colorScheme == .dark ? AppColors.divider : Color.black.opacity(0.04))
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct SkeletonContactRow: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Avatar skeleton
            Circle()
                .fill(AppColors.divider)
                .frame(width: 50, height: 50)
                .overlay(SkeletonView().clipShape(Circle()))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Name skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.divider)
                    .frame(width: 120, height: 16)
                    .overlay(SkeletonView().cornerRadius(4))

                // Company skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.divider)
                    .frame(width: 80, height: 12)
                    .overlay(SkeletonView().cornerRadius(4))
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.large)
    }
}

struct SkeletonCompanyRow: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Logo skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.divider)
                .frame(width: 50, height: 50)
                .overlay(SkeletonView().cornerRadius(12))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Company name
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.divider)
                    .frame(width: 140, height: 16)
                    .overlay(SkeletonView().cornerRadius(4))

                // Industry
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.divider)
                    .frame(width: 100, height: 12)
                    .overlay(SkeletonView().cornerRadius(4))
            }

            Spacer()

            // Contact count
            RoundedRectangle(cornerRadius: 4)
                .fill(AppColors.divider)
                .frame(width: 30, height: 14)
                .overlay(SkeletonView().cornerRadius(4))
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .cornerRadius(AppCornerRadius.large)
    }
}

// MARK: - Secure Text Field with Toggle

struct SecureTextFieldWithToggle: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    @State private var isSecure = true

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(.password)
            } else {
                TextField(placeholder, text: $text)
                    .textContentType(.password)
            }

            Button {
                isSecure.toggle()
                HapticManager.shared.lightImpact()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(.white.opacity(0.8))
            }
            .accessibilityLabel(isSecure ? "Show password" : "Hide password")
        }
        .padding(AppSpacing.md)
        .background(Color.white.opacity(0.06))
        .cornerRadius(AppCornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.large)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Inline Error Message

struct InlineErrorView: View {
    let message: String

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14))
            Text(message)
                .font(AppTypography.caption)
        }
        .foregroundColor(AppColors.accentRed)
        .padding(.horizontal, AppSpacing.sm)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Loading Button

struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                HapticManager.shared.mediumImpact()
                action()
            }
        }) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(isEnabled && !isLoading ? Color.white : Color.white.opacity(0.35))
            .foregroundColor(Color(hex: "0A0E27"))
            .cornerRadius(AppCornerRadius.large)
        }
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(isLoading ? "Loading, please wait" : title)
        .accessibilityHint(isEnabled ? "Double tap to \(title.lowercased())" : "Button disabled")
    }
}

// MARK: - Accessibility Extensions

extension View {
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Double tap to activate")
            .accessibilityAddTraits(.isButton)
    }

    func accessibleImage(label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isImage)
    }
}
