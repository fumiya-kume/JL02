import SwiftUI
import UIKit

struct InterestBubbleView: View {
    let interest: Interest
    let isSelected: Bool
    let canSelect: Bool
    let onTap: () -> Void

    @State private var bounceScale: CGFloat = 1.0

    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)

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
        VStack(spacing: 12) {
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
                            startRadius: 50,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

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
                            endRadius: 55
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
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .shadow(color: isSelected ? .accentColor.opacity(0.8) : .clear, radius: 8)
                    .shadow(color: isSelected ? .accentColor.opacity(0.5) : .clear, radius: 16)
                    .symbolEffect(.pulse, isActive: isSelected)
            }
            .frame(width: 110, height: 110)
            .neonGlow(color: glowColor, radius: glowRadius, intensity: glowIntensity)
            .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
            .shadow(color: isSelected ? Color.accentColor.opacity(0.5) : .clear, radius: 20, y: 8)

            Text(interest.localizedName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(foregroundColor)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 110)
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
