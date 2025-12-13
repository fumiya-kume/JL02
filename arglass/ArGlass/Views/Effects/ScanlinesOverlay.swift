import SwiftUI

struct ScanlinesOverlay: View {
    var lineSpacing: CGFloat = 4
    var lineThickness: CGFloat = 1

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { canvasContext, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let phase = CGFloat(t.remainder(dividingBy: 1.0)) * lineSpacing * 2

                var path = Path()
                for y in stride(from: -phase, through: size.height, by: lineSpacing) {
                    path.addRect(CGRect(x: 0, y: y, width: size.width, height: lineThickness))
                }

                canvasContext.fill(path, with: .color(.white.opacity(0.08)))
            }
        }
        .blendMode(.overlay)
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom)
        ScanlinesOverlay()
    }
}

