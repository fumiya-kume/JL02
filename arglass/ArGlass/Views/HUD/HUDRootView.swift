import SwiftUI

struct HUDRootView: View {
    @ObservedObject var viewModel: HUDViewModel

    @State private var glitchIntensity: CGFloat = 0

    var body: some View {
        ZStack {
            background

            ScanlinesOverlay()
                .opacity(0.20)

            GlitchOverlay(intensity: glitchIntensity)

            overlay
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onChange(of: viewModel.recognitionState) { _, newValue in
            if case .locked = newValue {
                triggerGlitch()
            }
        }
    }

    private var phaseKey: Int {
        switch viewModel.recognitionState {
        case .searching:
            0
        case .scanning:
            1
        case .locked:
            2
        }
    }

    private var background: some View {
        ZStack {
            switch viewModel.cameraService.state {
            case .running:
                CameraPreviewView(session: viewModel.cameraService.session)
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.25),
                                Color.black.opacity(0.70)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            default:
                LinearGradient(
                    colors: [
                        Color(white: 0.08),
                        Color(white: 0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    RadialGradient(
                        colors: [
                            Color.accentColor.opacity(0.10),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 50,
                        endRadius: 500
                    )
                }
            }
        }
    }

    private var overlay: some View {
        VStack(spacing: 0) {
#if DEBUG
            HStack(spacing: 10) {
                Spacer(minLength: 0)
                HUDDebugMenu(viewModel: viewModel)
            }
            .padding(.top, 10)
            .padding(.horizontal, 12)
#endif

            Spacer()

            TargetMarkerView(recognitionState: viewModel.recognitionState)
                .padding(.horizontal, 22)

            Spacer()

            HologramPanelView(recognitionState: viewModel.recognitionState)
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
        }
        .animation(.easeInOut(duration: 0.25), value: phaseKey)
    }

    private func triggerGlitch() {
        glitchIntensity = 1
        withAnimation(.easeOut(duration: 0.65)) {
            glitchIntensity = 0
        }
    }
}

#Preview {
    HUDRootView(viewModel: HUDViewModel())
}
