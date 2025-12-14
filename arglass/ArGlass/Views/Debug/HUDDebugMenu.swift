import SwiftUI

struct HUDDebugMenu: View {
    @ObservedObject var viewModel: HUDViewModel
    @State private var showingSettings = false

    var body: some View {
        Menu {
            Button {
                showingSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
            }

            Button {
                viewModel.toggleCameraPreview()
            } label: {
                Label(
                    viewModel.isCameraPreviewEnabled ? "Hide camera preview" : "Show camera preview",
                    systemImage: viewModel.isCameraPreviewEnabled ? "video.slash.fill" : "video.fill"
                )
            }

            Divider()

            Button {
                if viewModel.isAutoInferenceEnabled {
                    viewModel.stopAutoInference()
                } else {
                    viewModel.startAutoInference()
                }
            } label: {
                Label(
                    viewModel.isAutoInferenceEnabled ? "Stop VLM inference" : "Start VLM inference",
                    systemImage: viewModel.isAutoInferenceEnabled ? "stop.fill" : "camera.fill"
                )
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.accentColor.opacity(0.90))
                .hudTopCapsuleStyle()
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

#Preview {
    ZStack {
        Color.black
        HUDDebugMenu(viewModel: HUDViewModel())
    }
}
