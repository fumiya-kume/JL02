import SwiftUI

extension View {
    func neonGlow(color: Color, radius: CGFloat, intensity: Double) -> some View {
        shadow(color: color.opacity(intensity * 0.9), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(intensity * 0.55), radius: radius * 0.6, x: 0, y: 0)
    }
}

