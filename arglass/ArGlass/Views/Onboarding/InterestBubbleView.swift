import SwiftUI
import UIKit

struct InterestBubbleView: View {
    let interest: Interest
    let isSelected: Bool
    let canSelect: Bool
    let scaleFactor: CGFloat
    let onTap: () -> Void

    @State private var bounceScale: CGFloat = 1.0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)

    // Base sizes - iPhone uses smaller size, iPad uses larger
    private var baseBubbleSize: CGFloat {
        horizontalSizeClass == .compact ? 80 : 110
    }
    private var baseGlowSize: CGFloat {
        horizontalSizeClass == .compact ? 90 : 120
    }
    private var baseIconSize: CGFloat {
        horizontalSizeClass == .compact ? 24 : 32
    }
    private var baseFontSize: CGFloat {
        horizontalSizeClass == .compact ? 11 : 13
    }

    init(
        interest: Interest,
        isSelected: Bool,
        canSelect: Bool,
        scaleFactor: CGFloat = 1.0,
        onTap: @escaping () -> Void
    ) {
        self.interest = interest
        self.isSelected = isSelected
        self.canSelect = canSelect
        self.scaleFactor = scaleFactor
        self.onTap = onTap
    }

    // Animation parameters for floating effect - derived from interest id for stability
    private var amplitude: CGFloat {
        let hash = abs(interest.id.hashValue)
        return CGFloat(4 + (hash % 5))
    }
    private var frequencyY: Double {
        let hash = abs(interest.id.hashValue)
        return 0.15 + Double(hash % 100) / 1000.0
    }
    private var frequencyX: Double {
        let hash = abs(interest.id.hashValue >> 8)
        return 0.1 + Double(hash % 100) / 1000.0
    }
    private var phaseOffset: Double {
        let hash = abs(interest.id.hashValue >> 16)
        return Double(hash % 628) / 100.0
    }

    var body: some View {
        bubbleContent
            .scaleEffect(bounceScale)
            .onTapGesture {
                handleTap()
            }
            .onAppear {
                hapticFeedback.prepare()
            }
    }

    private var bubbleContent: some View {
        let bubbleSize = baseBubbleSize * scaleFactor
        let glowSize = baseGlowSize * scaleFactor
        let iconSize = baseIconSize * scaleFactor
        let fontSize = baseFontSize * scaleFactor

        return VStack(spacing: 12 * scaleFactor) {
            ZStack {
                // Outer glow circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50 * scaleFactor,
                            endRadius: 60 * scaleFactor
                        )
                    )
                    .frame(width: glowSize, height: glowSize)

                // Main circle with glass effect
                Circle()
                    .fill(.ultraThinMaterial)

                // Inner highlight for depth
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            center: .top,
                            startRadius: 0,
                            endRadius: 55 * scaleFactor
                        )
                    )

                // Multiple border layers for depth
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )

                Circle()
                    .stroke(borderGradient, lineWidth: isSelected ? 3 : 2)

                Image(systemName: interest.icon)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .shadow(color: isSelected ? .accentColor.opacity(0.8) : .clear, radius: 8 * scaleFactor)
                    .shadow(color: isSelected ? .accentColor.opacity(0.5) : .clear, radius: 16 * scaleFactor)
            }
            .frame(width: bubbleSize, height: bubbleSize)
            .neonGlow(color: glowColor, radius: glowRadius * scaleFactor, intensity: glowIntensity)
            .shadow(color: Color.black.opacity(0.3), radius: 8 * scaleFactor, y: 4 * scaleFactor)
            .shadow(color: isSelected ? Color.accentColor.opacity(0.5) : .clear, radius: 20 * scaleFactor, y: 8 * scaleFactor)

            Text(interest.localizedName)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(foregroundColor)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: bubbleSize)
        }
        .animation(.easeInOut(duration: 0.25), value: isSelected)
    }

    // MARK: - Styling

    private var foregroundColor: Color {
        if isSelected {
            return .white.opacity(0.95)
        } else if canSelect {
            return .white.opacity(0.75)
        } else {
            return .white.opacity(0.4)
        }
    }

    private var iconColor: Color {
        if isSelected {
            return .accentColor
        } else if canSelect {
            return .white.opacity(0.75)
        } else {
            return .white.opacity(0.4)
        }
    }

    private var borderGradient: LinearGradient {
        let baseColor = isSelected ? Color.accentColor : Color.white
        let opacity = isSelected ? 0.85 : 0.25

        return LinearGradient(
            colors: [
                baseColor.opacity(opacity),
                baseColor.opacity(opacity * 0.4),
                baseColor.opacity(opacity * 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glowColor: Color {
        isSelected ? .accentColor : .clear
    }

    private var glowRadius: CGFloat {
        isSelected ? 24 : 0
    }

    private var glowIntensity: Double {
        isSelected ? 0.5 : 0
    }

    // MARK: - Tap Handling

    private func handleTap() {
        guard canSelect || isSelected else { return }

        hapticFeedback.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            bounceScale = 1.15
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                bounceScale = 1.0
            }
        }

        onTap()
    }
}

#Preview {
    ZStack {
        Color.black

        HStack(spacing: 20) {
            InterestBubbleView(
                interest: Interest.allInterests[0],
                isSelected: false,
                canSelect: true,
                onTap: {}
            )

            InterestBubbleView(
                interest: Interest.allInterests[1],
                isSelected: true,
                canSelect: true,
                onTap: {}
            )
        }
    }
}
