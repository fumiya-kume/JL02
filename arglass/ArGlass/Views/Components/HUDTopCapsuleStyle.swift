import SwiftUI

private struct HUDTopCapsuleStyle: ViewModifier {
    var height: CGFloat
    var verticalPadding: CGFloat
    var horizontalPadding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .frame(height: height)
            .background(.ultraThinMaterial, in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
            }
            .neonGlow(color: .accentColor, radius: 10, intensity: 0.14)
    }
}

extension View {
    func hudTopCapsuleStyle(
        height: CGFloat = 44,
        verticalPadding: CGFloat = 12,
        horizontalPadding: CGFloat = 14
    ) -> some View {
        modifier(
            HUDTopCapsuleStyle(
                height: height,
                verticalPadding: verticalPadding,
                horizontalPadding: horizontalPadding
            )
        )
    }
}

