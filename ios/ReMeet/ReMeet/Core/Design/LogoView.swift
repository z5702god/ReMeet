import SwiftUI

/// Re:Meet Logo - Business card with reconnection arrow
struct ReMeetLogo: View {
    var size: CGFloat = 100
    var showText: Bool = true

    private var iconSize: CGFloat { size }
    private var cardWidth: CGFloat { iconSize * 0.65 }
    private var cardHeight: CGFloat { iconSize * 0.42 }

    var body: some View {
        VStack(spacing: size * 0.15) {
            // Icon
            ZStack {
                // Business Card
                RoundedRectangle(cornerRadius: iconSize * 0.06)
                    .fill(AppColors.primaryGradient)
                    .frame(width: cardWidth, height: cardHeight)
                    .shadow(color: Color(hex: "4A9FFF").opacity(0.3), radius: 4, x: 0, y: 2)

                // Card lines (text representation)
                VStack(alignment: .leading, spacing: cardHeight * 0.12) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: cardWidth * 0.5, height: cardHeight * 0.08)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.6))
                        .frame(width: cardWidth * 0.7, height: cardHeight * 0.06)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.4))
                        .frame(width: cardWidth * 0.45, height: cardHeight * 0.06)
                }
                .offset(x: -cardWidth * 0.1, y: 0)

                // Circular arrow (reconnection symbol)
                CircularArrow(size: iconSize * 0.35)
                    .offset(x: cardWidth * 0.35, y: -cardHeight * 0.25)
            }
            .frame(width: iconSize, height: iconSize * 0.7)

            // Text (optional)
            if showText {
                Text("Re:Meet")
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
}

/// Circular arrow component for the logo
struct CircularArrow: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            // Arc
            Circle()
                .trim(from: 0.15, to: 0.85)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "4A9FFF"), Color(hex: "8B7FFF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: size * 0.14, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(90))

            // Arrow head
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "4A9FFF"), Color(hex: "8B7FFF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.3, height: size * 0.35)
                .rotationEffect(.degrees(180))
                .offset(x: 0, y: size * 0.5)
        }
    }
}

/// Triangle shape for arrow head
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// App Icon version (square, no text)
struct ReMeetAppIcon: View {
    var size: CGFloat = 100

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "4A9FFF"), Color(hex: "8B7FFF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            // Logo content
            ReMeetLogo(size: size * 0.7, showText: false)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct LogoView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Logo on light background
            VStack {
                ReMeetLogo(size: 120)
                Text("Logo with Text")
                    .font(.caption)
            }
            .padding(40)
            .background(Color(hex: "0A0E27"))
            .cornerRadius(20)

            // App Icon
            VStack {
                ReMeetAppIcon(size: 100)
                Text("App Icon")
                    .font(.caption)
            }

            // Small sizes
            HStack(spacing: 20) {
                ReMeetAppIcon(size: 60)
                ReMeetAppIcon(size: 40)
                ReMeetAppIcon(size: 29)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
#endif
