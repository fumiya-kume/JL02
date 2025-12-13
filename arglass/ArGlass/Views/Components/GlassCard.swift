import SwiftUI

struct GlassCard<Content: View>: View {
    var accent: Color = .accentColor
    var content: () -> Content

    init(accent: Color = .accentColor, @ViewBuilder content: @escaping () -> Content) {
        self.accent = accent
        self.content = content
    }

    var body: some View {
        content()
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                accent.opacity(0.75),
                                accent.opacity(0.22),
                                accent.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .neonGlow(color: accent, radius: 18, intensity: 0.14)
    }
}

#Preview {
    GlassCard {
        Text("Hologram Panel")
            .foregroundStyle(.white)
    }
    .padding()
    .background(Color.black)
}
