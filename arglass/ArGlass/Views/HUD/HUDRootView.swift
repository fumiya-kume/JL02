import SwiftUI

struct HUDRootView: View {
    @ObservedObject var viewModel: HUDViewModel

    @State private var glitchIntensity: CGFloat = 0
    @State private var showingHistory = false
    @State private var showingImageViewer = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background

                ScanlinesOverlay()
                    .opacity(0.20)

                GlitchOverlay(intensity: glitchIntensity)

                overlay(safeAreaTop: geometry.safeAreaInsets.top)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onChange(of: viewModel.recognitionState) { _, newValue in
            if case .locked = newValue {
                triggerGlitch()
            }
        }
        .onAppear {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
        .fullScreenCover(isPresented: $showingHistory) {
            HistoryView()
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            ImageViewerView(image: viewModel.lastCapturedImage, subtitle: currentSubtitle)
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

    private var currentSubtitle: String? {
        if case .locked(let landmark, _) = viewModel.recognitionState {
            return landmark.subtitle
        }
        return nil
    }

    @ViewBuilder
    private var background: some View {
        if viewModel.isCameraPreviewEnabled {
            CameraPreviewView(session: viewModel.cameraService.session)
        } else {
            Color.black
        }
    }

    private var historyButton: some View {
        Button(action: { showingHistory = true }) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.accentColor.opacity(0.90))
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
                }
                .neonGlow(color: .accentColor, radius: 10, intensity: 0.14)
        }
        .contentShape(Capsule())
    }

    private func overlay(safeAreaTop: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                historyButton

#if DEBUG
                DebugStatusOverlay(viewModel: viewModel)
#endif

                Spacer(minLength: 0)

#if DEBUG
                HUDDebugMenu(viewModel: viewModel)
#endif
            }
            .padding(.top, safeAreaTop + 16)
            .padding(.horizontal, 20)

            Spacer()

            TargetMarkerView(recognitionState: viewModel.recognitionState)
                .padding(.horizontal, 20)

            Spacer()

            HologramPanelView(
                recognitionState: viewModel.recognitionState,
                capturedImage: viewModel.lastCapturedImage,
                onImageTap: { showingImageViewer = true }
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
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
