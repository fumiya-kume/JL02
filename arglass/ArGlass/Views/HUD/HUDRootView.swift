import SwiftUI

struct HUDRootView: View {
    @ObservedObject var viewModel: HUDViewModel

    @State private var glitchIntensity: CGFloat = 0

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
        Color.black
    }

    private func overlay(safeAreaTop: CGFloat) -> some View {
        VStack(spacing: 0) {
#if DEBUG
            HStack(spacing: 10) {
                DebugStatusOverlay(viewModel: viewModel)
                Spacer(minLength: 0)
                HUDDebugMenu(viewModel: viewModel)
            }
            .padding(.top, safeAreaTop + 10)
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
