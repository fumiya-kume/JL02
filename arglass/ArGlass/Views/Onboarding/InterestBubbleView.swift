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
        TimelineView(.periodic(from: .now, by: 1.0 / 15.0)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let yOffset = sin(time * frequencyY * .pi * 2 + phaseOffset) * amplitude
            let xOffset = cos(time * frequencyX * .pi * 2 + phaseOffset) * (amplitude * 0.4)

            bubbleContent
                .scaleEffect(bounceScale)
                .offset(x: xOffset, y: yOffset)
        }
        .onTapGesture {
            handleTap()
        }
        .onAppear {
            hapticFeedback.prepare()
        }
    }

    private var bubbleContent: some View {
        VStack(spacing: 6) {
            Image(systemName: interest.icon)
                .font(.system(size: 22, weight: .semibold))
                .symbolEffect(.pulse, isActive: isSelected)

            Text(interest.localizedName)
                .font(.system(size: 11, weight: .bold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(foregroundColor)
        .frame(width: 80, height: 80)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderGradient, lineWidth: isSelected ? 2 : 1.2)
        }
        .neonGlow(color: glowColor, radius: glowRadius, intensity: glowIntensity)
        .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: 12, y: 4)
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
