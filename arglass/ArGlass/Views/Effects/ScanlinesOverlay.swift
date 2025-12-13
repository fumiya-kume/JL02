import SwiftUI

struct ScanlinesOverlay: View {
    var lineSpacing: CGFloat = 4
    var lineThickness: CGFloat = 1

    var body: some View {
        Canvas { canvasContext, size in
            var path = Path()
            for y in stride(from: 0, through: size.height, by: lineSpacing) {
                path.addRect(CGRect(x: 0, y: y, width: size.width, height: lineThickness))
            }

            canvasContext.fill(path, with: .color(.white.opacity(0.08)))
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

