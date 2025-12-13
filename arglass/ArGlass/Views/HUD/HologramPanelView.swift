import SwiftUI

struct HologramPanelView: View {
    let recognitionState: HUDViewModel.RecognitionState
    var capturedImage: UIImage?
    var onImageTap: (() -> Void)?

    var body: some View {
        switch recognitionState {
        case .searching:
            searchingPanel
                .transition(.opacity)
        case let .scanning(candidate, progress):
            scanningPanel(candidate: candidate, progress: progress)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        case let .locked(target, confidence):
            lockedPanel(target: target, confidence: confidence)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private var searchingPanel: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor.opacity(0.85))
                    .neonGlow(color: .accentColor, radius: 10, intensity: 0.18)

                VStack(alignment: .leading, spacing: 4) {
                    Text("ガイド待機中")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text("視界に入ったランドマークを自動認識します。")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func scanningPanel(candidate: Landmark, progress: Double) -> some View {
        GlassCard(accent: .accentColor) {
            VStack(alignment: .leading, spacing: 10) {
                header(
                    title: candidate.name,
                    badge: "SCANNING",
                    accent: .accentColor,
                    trailing: String(format: "%.0f%%", progress * 100)
                )

                TypingText(
                    text: "輪郭・テクスチャを解析中…",
                    characterDelay: .milliseconds(26)
                )
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.82))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func lockedPanel(target: Landmark, confidence: Double) -> some View {
        GlassCard(accent: .accentColor) {
            VStack(alignment: .leading, spacing: 12) {
                header(
                    title: target.name,
                    badge: "LOCKED",
                    accent: .accentColor,
                    trailing: String(format: "%.0f%%", confidence * 100)
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("建築年 • \(target.yearBuilt)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.75))

                    TypingText(text: target.subtitle, characterDelay: .milliseconds(18))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))

                    Text(target.history)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineSpacing(2)
                }

                HStack(spacing: 10) {
                    ChipView(label: formatDistance(target.distanceMeters), systemImage: "ruler")
                    ChipView(label: formatBearing(target.bearingDegrees), systemImage: "location.north.line")
                    ChipView(label: "HIST", systemImage: "book")
                    Spacer()

                    if let image = capturedImage {
                        Button(action: { onImageTap?() }) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func header(title: String, badge: String, accent: Color, trailing: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white.opacity(0.94))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(badge)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(accent.opacity(0.95))
                .padding(.vertical, 3)
                .padding(.horizontal, 7)
                .background(accent.opacity(0.12), in: Capsule(style: .continuous))

            Spacer()

            Text(trailing)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.70))
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1fkm", meters / 1000.0)
        }
        return "\(Int(meters.rounded()))m"
    }

    private func formatBearing(_ degrees: Double) -> String {
        let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return "\(Int(normalized.rounded()))°"
    }
}

private struct ChipView: View {
    let label: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
        }
        .foregroundStyle(.white.opacity(0.78))
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(.white.opacity(0.06), in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HologramPanelView(recognitionState: .searching)
        HologramPanelView(recognitionState: .scanning(candidate: HUDViewModel.demoLandmarks[0], progress: 0.62))
        HologramPanelView(recognitionState: .locked(target: HUDViewModel.demoLandmarks[1], confidence: 0.93))
    }
    .padding()
    .background(Color.black)
}
