import SwiftUI
import UIKit

struct InterestBubbleView: View {
    let interest: Interest
    let isSelected: Bool
    let canSelect: Bool
    let onTap: () -> Void

    @State private var bounceScale: CGFloat = 1.0

    private let amplitude: CGFloat
    private let frequencyY: Double
    private let frequencyX: Double
    private let phaseOffset: Double

    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)

    init(interest: Interest, isSelected: Bool, canSelect: Bool, onTap: @escaping () -> Void) {
        self.interest = interest
        self.isSelected = isSelected
        self.canSelect = canSelect
        self.onTap = onTap

        let hash = abs(interest.id.hashValue)
        self.amplitude = CGFloat(3 + (hash % 3))  // 3-6pt for subtle floating
        self.frequencyY = 0.25 + Double(hash % 100) / 600.0  // slower, gentler
        self.frequencyX = 0.15 + Double(hash % 80) / 800.0
        self.phaseOffset = Double(hash % 1000) / 1000.0 * .pi * 2
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

            Text(interest.localizedName)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(foregroundColor)
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(borderGradient, lineWidth: isSelected ? 1.5 : 1)
        }
        .neonGlow(color: glowColor, radius: glowRadius, intensity: glowIntensity)
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
        isSelected ? 20 : 0
    }

    private var glowIntensity: Double {
        isSelected ? 0.35 : 0
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
