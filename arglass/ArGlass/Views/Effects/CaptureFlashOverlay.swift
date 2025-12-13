import SwiftUI

struct CaptureFlashOverlay: View {
    let intensity: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(
                        Color.accentColor.opacity(0.8 * intensity),
                        lineWidth: 20
                    )
                    .blur(radius: 30)

                RoundedRectangle(cornerRadius: 0)
                    .stroke(
                        Color.accentColor.opacity(0.5 * intensity),
                        lineWidth: 10
                    )
                    .blur(radius: 15)

                RoundedRectangle(cornerRadius: 0)
                    .stroke(
                        Color.accentColor.opacity(0.4 * intensity),
                        lineWidth: 3
                    )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .blendMode(.screen)
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.black
        CaptureFlashOverlay(intensity: 1)
    }
    .ignoresSafeArea()
}
