import SwiftUI

struct GlitchOverlay: View {
    let intensity: CGFloat

    var body: some View {
        Group {
            if intensity > 0.01 {
                TimelineView(.animation) { context in
                    Canvas { canvasContext, size in
                        let t = context.date.timeIntervalSinceReferenceDate
                        for i in 0..<14 {
                            let y = pseudoRandom(seed: i, time: t) * size.height
                            let height = max(1, pseudoRandom(seed: i + 100, time: t) * 18)
                            let xShift = (pseudoRandom(seed: i + 200, time: t) - 0.5) * 50 * intensity

                            let rect = CGRect(x: 0, y: y, width: size.width, height: height)
                            var sliceContext = canvasContext
                            sliceContext.translateBy(x: xShift, y: 0)
                            sliceContext.fill(Path(rect), with: .color(Color.accentColor.opacity(0.10 * intensity)))
                        }

                        // Offset ghosting
                        let rShift = (pseudoRandom(seed: 900, time: t) - 0.5) * 14 * intensity
                        let bShift = (pseudoRandom(seed: 901, time: t) - 0.5) * 14 * intensity

                        var ghostAContext = canvasContext
                        ghostAContext.translateBy(x: rShift, y: 0)
                        ghostAContext.fill(
                            Path(CGRect(origin: .zero, size: size)),
                            with: .color(Color.accentColor.opacity(0.012 * intensity))
                        )

                        var ghostBContext = canvasContext
                        ghostBContext.translateBy(x: bShift, y: 0)
                        ghostBContext.fill(
                            Path(CGRect(origin: .zero, size: size)),
                            with: .color(Color.accentColor.opacity(0.010 * intensity))
                        )
                    }
                }
                .blendMode(.screen)
            }
        }
        .allowsHitTesting(false)
    }

    private func pseudoRandom(seed: Int, time: TimeInterval) -> CGFloat {
        let x = sin((Double(seed) * 12.9898) + time * 18.0) * 43758.5453
        return CGFloat(x - floor(x))
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.black, .gray.opacity(0.5)], startPoint: .top, endPoint: .bottom)
        GlitchOverlay(intensity: 1)
    }
}
