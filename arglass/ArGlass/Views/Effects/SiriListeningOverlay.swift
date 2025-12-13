import SwiftUI

struct SiriListeningOverlay: View {
    var level: Double

    private var normalizedLevel: Double {
        max(0, min(1, level))
    }

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let rotation = Angle.degrees((t * 22).truncatingRemainder(dividingBy: 360))
            let glowStrength = 0.12 + (normalizedLevel * 0.45)
            let levelCGFloat = CGFloat(normalizedLevel)
            let lineWidth = 1.5 + (levelCGFloat * 6.5)

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(gradient, lineWidth: lineWidth)
                    .opacity(0.85)
                    .blur(radius: 10 + (levelCGFloat * 22))
                    .rotationEffect(rotation)
                    .padding(18)

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(gradient, lineWidth: 1.0)
                    .opacity(0.22)
                    .rotationEffect(rotation)
                    .padding(18)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentColor.opacity(0.60),
                                Color.accentColor.opacity(0.05),
                                .clear,
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 210
                        )
                    )
                    .frame(width: 140 + (levelCGFloat * 140), height: 140 + (levelCGFloat * 140))
                    .blur(radius: 18 + (levelCGFloat * 24))
                    .opacity(0.55)
                    .scaleEffect(0.90 + (levelCGFloat * 0.12))
            }
            .blendMode(.screen)
            .neonGlow(color: .accentColor, radius: 18, intensity: glowStrength)
            .animation(.easeOut(duration: 0.12), value: normalizedLevel)
        }
        .allowsHitTesting(false)
    }

    private var gradient: AngularGradient {
        AngularGradient(
            colors: [
                .cyan,
                .blue,
                .purple,
                .pink,
                .cyan,
            ],
            center: .center
        )
    }
}

#Preview {
    ZStack {
        Color.black
        SiriListeningOverlay(level: 0.65)
    }
}
