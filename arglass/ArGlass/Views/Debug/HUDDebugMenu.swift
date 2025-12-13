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

            Button {
                viewModel.playDemoSequence()
            } label: {
                Label("Play demo sequence", systemImage: "play.fill")
            }

            Divider()

            Button {
                viewModel.setSearching()
            } label: {
                Label("State: searching", systemImage: "magnifyingglass")
            }

            Menu("State: scanning") {
                ForEach(HUDViewModel.demoLandmarks) { landmark in
                    Button {
                        viewModel.setScanning(candidate: landmark, progress: 0.25)
                    } label: {
                        Text("\(landmark.name) • 25%")
                    }

                    Button {
                        viewModel.setScanning(candidate: landmark, progress: 0.60)
                    } label: {
                        Text("\(landmark.name) • 60%")
                    }

                    Button {
                        viewModel.setScanning(candidate: landmark, progress: 1.00)
                    } label: {
                        Text("\(landmark.name) • 100%")
                    }
                }
            }

            Menu("State: locked") {
                ForEach(HUDViewModel.demoLandmarks) { landmark in
                    Button {
                        viewModel.setLocked(target: landmark, confidence: 0.85)
                    } label: {
                        Text("\(landmark.name) • 85%")
                    }

                    Button {
                        viewModel.setLocked(target: landmark, confidence: 0.95)
                    } label: {
                        Text("\(landmark.name) • 95%")
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.accentColor.opacity(0.90))
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(
                            Color.accentColor.opacity(0.25),
                            lineWidth: 1
                        )
                }
                .neonGlow(color: .accentColor, radius: 10, intensity: 0.14)
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
