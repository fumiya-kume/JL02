import AVFoundation
import Foundation

@MainActor
final class CameraService: ObservableObject {
    enum CameraState: Equatable {
        case idle
        case running
        case unauthorized
        case failed
    }

    let session = AVCaptureSession()
    @Published private(set) var state: CameraState = .idle

    private var isConfigured = false

    func requestAccessAndStart() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            start()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            granted ? start() : setUnauthorized()
        default:
            setUnauthorized()
        }
    }

    func start() {
        guard state != .running else { return }
        guard configureIfNeeded() else {
            state = .failed
            return
        }

        session.startRunning()
        state = .running
    }

    func stop() {
        session.stopRunning()
        state = .idle
    }

    private func setUnauthorized() {
        state = .unauthorized
    }

    private func configureIfNeeded() -> Bool {
        guard !isConfigured else { return true }

        session.beginConfiguration()
        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            return false
        }

        session.addInput(input)
        session.commitConfiguration()
        isConfigured = true
        return true
    }
}

