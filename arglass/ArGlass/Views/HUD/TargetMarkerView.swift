import SwiftUI

struct TargetMarkerView: View {
    let recognitionState: HUDViewModel.RecognitionState

    var body: some View {
        ZStack {
            switch recognitionState {
            case .searching:
                searchingView
            case let .scanning(candidate, progress):
                markerView(
                    title: candidate.name,
                    subtitle: NSLocalizedString("hud_badge_scanning", comment: ""),
                    progress: progress,
                    highlightColor: Color.accentColor.opacity(0.85)
                )
            case let .locked(target, confidence):
                markerView(
                    title: target.name,
                    subtitle: String(format: "%@ • %.0f%%", NSLocalizedString("hud_badge_locked", comment: ""), confidence * 100),
                    progress: 1,
                    highlightColor: Color.accentColor.opacity(1.0)
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var searchingView: some View {
        VStack(spacing: 10) {
            ZStack {
                ReticleCornersShape(cornerLength: 16)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    .frame(width: 150, height: 110)

                ProgressView()
                    .tint(Color.accentColor.opacity(0.85))
            }
            Text(NSLocalizedString("hud_searching_landmarks", comment: ""))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private func markerView(
        title: String,
        subtitle: String,
        progress: Double,
        highlightColor: Color
    ) -> some View {
        ZStack {
            PulseRing(color: highlightColor, lineWidth: 1)
                .frame(width: 190, height: 190)

            ReticleCornersShape(cornerLength: 22)
                .stroke(highlightColor.opacity(0.9), lineWidth: 1.25)
                .frame(width: 210, height: 150)
                .neonGlow(color: highlightColor, radius: 16, intensity: 0.22)

            VStack(spacing: 8) {
                VStack(spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(highlightColor.opacity(0.90))
                        .tracking(1.1)
                }
            }
            .padding(.top, 4)

            if progress < 1 {
                VStack {
                    Spacer()
                    ProgressView(value: progress)
                        .tint(highlightColor.opacity(0.9))
                        .frame(width: 160)
                }
                .padding(.bottom, 10)
            }
        }
    }
}

private struct PulseRing: View {
    let color: Color
    let lineWidth: CGFloat

    @State private var isPulsing = false

    var body: some View {
        Circle()
            .stroke(color.opacity(0.55), lineWidth: lineWidth)
            .scaleEffect(isPulsing ? 1.35 : 0.85)
            .opacity(isPulsing ? 0 : 1)
            .onAppear { isPulsing = true }
            .animation(.easeOut(duration: 1.25).repeatForever(autoreverses: false), value: isPulsing)
    }
}

private struct ReticleCornersShape: Shape {
    let cornerLength: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let l = cornerLength
        let x0 = rect.minX
        let x1 = rect.maxX
        let y0 = rect.minY
        let y1 = rect.maxY

        // Top-left
        path.move(to: CGPoint(x: x0, y: y0 + l))
        path.addLine(to: CGPoint(x: x0, y: y0))
        path.addLine(to: CGPoint(x: x0 + l, y: y0))

        // Top-right
        path.move(to: CGPoint(x: x1 - l, y: y0))
        path.addLine(to: CGPoint(x: x1, y: y0))
        path.addLine(to: CGPoint(x: x1, y: y0 + l))

        // Bottom-right
        path.move(to: CGPoint(x: x1, y: y1 - l))
        path.addLine(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x1 - l, y: y1))

        // Bottom-left
        path.move(to: CGPoint(x: x0 + l, y: y1))
        path.addLine(to: CGPoint(x: x0, y: y1))
        path.addLine(to: CGPoint(x: x0, y: y1 - l))

        return path
    }
}

#Preview {
    let sampleLandmark = Landmark(
        name: "Sample Building",
        yearBuilt: "2020",
        subtitle: "A sample landmark for preview.",
        history: "This is a sample landmark for preview purposes."
    )
    return VStack(spacing: 30) {
        TargetMarkerView(recognitionState: .searching)
        TargetMarkerView(recognitionState: .scanning(candidate: sampleLandmark, progress: 0.42))
        TargetMarkerView(recognitionState: .locked(target: sampleLandmark, confidence: 0.93))
    }
    .padding()
    .background(Color.black)
}
