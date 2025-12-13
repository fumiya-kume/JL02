import SwiftUI

struct SiriListeningOverlay: View {
    var level: Double

    private var normalizedLevel: Double {
        max(0, min(1, level))
    }

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            // Siri風の“強め”発光に寄せる
            let glowStrength = 0.20 + (normalizedLevel * 0.75)
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
            .neonGlow(color: .accentColor, radius: 26, intensity: glowStrength)
            .animation(.easeOut(duration: 0.12), value: normalizedLevel)
        }
        .allowsHitTesting(false)
    }

    private struct FuzzyScreenEdgeGlow: View {
        var level: Double
        var time: Double
        var slowBreath: Double
        var microBreath: Double

        /// iOS 18のSiriっぽい「エッジライト」感：色が周回しつつ、ところどころ消える（常に全面発光しない）
        private var edgeLightGradient: AngularGradient {
            let a = Angle.degrees((time * 26).truncatingRemainder(dividingBy: 360))
            let b = Angle.degrees((time * 11 + 120).truncatingRemainder(dividingBy: 360))

            // 1本のコニックだけだと“素直な周回”になりやすいので、stopを疎にして“光の塊”を作る
            // （回転しているのはShapeではなくグラデの位相）
            let stops: [Gradient.Stop] = [
                .init(color: .clear, location: 0.00),
                .init(color: .pink.opacity(1.00), location: 0.05),
                .init(color: .orange.opacity(0.95), location: 0.09),
                .init(color: .purple.opacity(1.00), location: 0.14),
                .init(color: .blue.opacity(1.00), location: 0.22),
                .init(color: .cyan.opacity(1.00), location: 0.30),
                .init(color: .clear, location: 0.40),
                // もう1つの塊（強めに見せる）
                .init(color: .clear, location: 0.55),
                .init(color: .pink.opacity(0.95), location: 0.60),
                .init(color: .purple.opacity(0.95), location: 0.66),
                .init(color: .cyan.opacity(0.95), location: 0.73),
                .init(color: .clear, location: 0.82),
                .init(color: .clear, location: 1.00),
            ]

            // 2本を合成して“ふわっと揺れる”感じを出す
            return AngularGradient(gradient: Gradient(stops: stops), center: .center, angle: a + b * 0.12)
        }

        var body: some View {
            let levelCGFloat = CGFloat(max(0, min(1, level)))

            // 画面内の枠としてインセットしつつ、ブラーと太さで“ふわふわ”感を出す
            let baseInset = 12 + (levelCGFloat * 10) + (CGFloat(slowBreath) * 3)
            let outerBlur = 32 + (levelCGFloat * 46) + (CGFloat(slowBreath) * 12)
            let outerLineWidth = 28 + (levelCGFloat * 22) + (CGFloat(microBreath) * 6)

            // “Siriっぽく”枠自体は大きく動かさず、微小な揺らぎだけにする
            let driftX = (2.2 * sin(time * 0.20)) + (0.9 * sin(time * 1.03 + 0.7))
            let driftY = (2.2 * cos(time * 0.18 + 0.2)) + (0.9 * cos(time * 1.11))

            ZStack {
                // もやっとした“内側”の枠ハロー
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(edgeLightGradient, lineWidth: outerLineWidth)
                    .opacity(0.36 + (Double(levelCGFloat) * 0.44))
                    .blur(radius: outerBlur)
                    .padding(baseInset)
                    .offset(x: driftX, y: driftY)

                // 少しだけ輪郭が残る薄い枠（回転はしない）
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(edgeLightGradient, lineWidth: 1.2 + (levelCGFloat * 1.6))
                    .opacity(0.22 + (Double(levelCGFloat) * 0.34))
                    .blur(radius: 1.5 + (levelCGFloat * 2.0))
                    .padding(max(10, baseInset - (10 + levelCGFloat * 4)))
                    .offset(x: driftX * 0.35, y: driftY * 0.35)

                // 外周に薄いグローをもう1枚重ねて“漂い”を強める
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(edgeLightGradient, lineWidth: 10 + (levelCGFloat * 10))
                    .opacity(0.20 + (Double(levelCGFloat) * 0.26))
                    .blur(radius: 24 + (levelCGFloat * 28))
                    .padding(baseInset + 18 + (levelCGFloat * 6) + (CGFloat(slowBreath) * 6))
                    .offset(x: -driftX * 0.65, y: driftY * 0.55)

                // さらに強い“ブルーム”を1枚（音量でしっかり出る）
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(edgeLightGradient, lineWidth: 40 + (levelCGFloat * 26))
                    .opacity(0.08 + (Double(levelCGFloat) * 0.22))
                    .blur(radius: 46 + (levelCGFloat * 44))
                    .padding(baseInset + 6)
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
