import SwiftUI

struct SiriListeningOverlay: View {
    var level: Double

    private var normalizedLevel: Double {
        max(0, min(1, level))
    }

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let glowStrength = 0.12 + (normalizedLevel * 0.45)
            let levelCGFloat = CGFloat(normalizedLevel)
            let slowBreath = 0.5 + 0.5 * sin(t * 0.9)
            let microBreath = 0.5 + 0.5 * sin(t * 2.2 + 1.1)
            let hueShift = Angle.degrees((t * 10).truncatingRemainder(dividingBy: 360))

            ZStack {
                FuzzyScreenEdgeGlow(
                    level: normalizedLevel,
                    time: t,
                    slowBreath: slowBreath,
                    microBreath: microBreath
                )
                .hueRotation(hueShift)

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

    private struct FuzzyScreenEdgeGlow: View {
        var level: Double
        var time: Double
        var slowBreath: Double
        var microBreath: Double

        private var gradient: LinearGradient {
            LinearGradient(
                colors: [
                    .cyan.opacity(0.95),
                    .blue.opacity(0.95),
                    .purple.opacity(0.95),
                    .pink.opacity(0.95),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        var body: some View {
            let levelCGFloat = CGFloat(max(0, min(1, level)))

            // 画面「外周」の枠に見えるよう、Shape自体を大きくしてクリップさせる
            let outerPadding = -54 - (levelCGFloat * 20) - (CGFloat(slowBreath) * 6)
            let outerBlur = 26 + (levelCGFloat * 30) + (CGFloat(slowBreath) * 10)
            let outerLineWidth = 20 + (levelCGFloat * 16) + (CGFloat(microBreath) * 4)

            // ふわふわ感：ゆっくり漂うドリフト（ごく小さく）
            let driftX = (6 * sin(time * 0.18)) + (2 * sin(time * 0.91 + 0.7))
            let driftY = (6 * cos(time * 0.16 + 0.2)) + (2 * cos(time * 1.07))

            ZStack {
                // もやっとした外周ハロー
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(gradient, lineWidth: outerLineWidth)
                    .opacity(0.22 + (Double(levelCGFloat) * 0.30))
                    .blur(radius: outerBlur)
                    .padding(outerPadding)
                    .offset(x: driftX, y: driftY)

                // 少しだけ輪郭が残る薄い枠（回転はしない）
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(gradient, lineWidth: 1.2 + (levelCGFloat * 1.6))
                    .opacity(0.10 + (Double(levelCGFloat) * 0.22))
                    .blur(radius: 1.5 + (levelCGFloat * 2.0))
                    .padding(-18 - (levelCGFloat * 6))
                    .offset(x: driftX * 0.35, y: driftY * 0.35)

                // 外周に薄いグローをもう1枚重ねて“漂い”を強める
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(gradient, lineWidth: 10 + (levelCGFloat * 10))
                    .opacity(0.10 + (Double(levelCGFloat) * 0.18))
                    .blur(radius: 18 + (levelCGFloat * 20))
                    .padding(-70 - (levelCGFloat * 16) - (CGFloat(slowBreath) * 8))
                    .offset(x: -driftX * 0.65, y: driftY * 0.55)
            }
            .compositingGroup()
        }
    }
}

#Preview {
    ZStack {
        Color.black
        SiriListeningOverlay(level: 0.65)
    }
}
