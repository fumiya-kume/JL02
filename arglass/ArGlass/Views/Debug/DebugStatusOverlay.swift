import SwiftUI

struct DebugStatusOverlay: View {
    @ObservedObject var viewModel: HUDViewModel

    var body: some View {
        HStack(spacing: 8) {
            cameraStateView
            captureStatusView
            apiStatusView
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        }
    }

    private var cameraStateView: some View {
        HStack(spacing: 4) {
            Image(systemName: "video.fill")
                .font(.system(size: 9))

            switch viewModel.cameraService.state {
            case .idle:
                Text("IDLE")
                    .foregroundStyle(.secondary)
            case .running:
                Text("RUN")
                    .foregroundStyle(.green)
            case .unauthorized:
                Text("DENY")
                    .foregroundStyle(.orange)
            case .failed:
                Text("FAIL")
                    .foregroundStyle(.red)
            }
        }
        .foregroundStyle(.white.opacity(0.8))
    }

    private var captureStatusView: some View {
        HStack(spacing: 4) {
            Image(systemName: "camera.fill")
                .font(.system(size: 9))

            switch viewModel.captureState {
            case .idle:
                Text("--")
                    .foregroundStyle(.secondary)
            case .captured(let sizeKB):
                Text(String(format: "%.0fKB", sizeKB))
                    .foregroundStyle(.green)
            case .failed:
                Text("FAIL")
                    .foregroundStyle(.red)
            }
        }
        .foregroundStyle(.white.opacity(0.8))
    }

    private var apiStatusView: some View {
        HStack(spacing: 4) {
            Image(systemName: "network")
                .font(.system(size: 9))

            switch viewModel.apiRequestState {
            case .idle:
                Text("--")
                    .foregroundStyle(.secondary)
            case .requesting:
                Text("...")
                    .foregroundStyle(.yellow)
            case .success(let responseTime):
                Text(String(format: "%.1fs", responseTime))
                    .foregroundStyle(.green)
            case .error:
                Text("ERR")
                    .foregroundStyle(.red)
            }
        }
        .foregroundStyle(.white.opacity(0.8))
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 20) {
            DebugStatusOverlay(viewModel: {
                let vm = HUDViewModel()
                return vm
            }())
        }
    }
}
