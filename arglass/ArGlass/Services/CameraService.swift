import AVFoundation
import Foundation
import UIKit

final class CameraService: ObservableObject {
    enum CameraState: Equatable {
        case idle
        case running
        case unauthorized
        case failed
    }

    let session = AVCaptureSession()
    @Published private(set) var state: CameraState = .idle

    private let sessionQueue = DispatchQueue(label: "camera.session", qos: .userInitiated)
    private var isConfigured = false
    private var isRunning = false
    private var videoOutput: AVCaptureVideoDataOutput?
    private let frameHandler = FrameHandler()

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
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.isRunning else { return }
            guard self.configureIfNeeded() else {
                self.setState(.failed)
                return
            }

            self.session.startRunning()
            self.isRunning = true
            self.setState(.running)
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard self.isRunning else {
                self.setState(.idle)
                return
            }

            self.session.stopRunning()
            self.isRunning = false
            self.setState(.idle)
        }
    }

    private func setUnauthorized() {
        setState(.unauthorized)
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

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(frameHandler, queue: DispatchQueue(label: "camera.frame"))
        output.alwaysDiscardsLateVideoFrames = true

        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return false
        }

        session.addOutput(output)
        videoOutput = output

        session.commitConfiguration()
        isConfigured = true
        return true
    }

    func captureCurrentFrame() -> UIImage? {
        frameHandler.latestFrame
    }

    private func setState(_ newState: CameraState) {
        if Thread.isMainThread {
            state = newState
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.state = newState
            }
        }
    }
}

final class FrameHandler: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let lock = NSLock()
    private var _latestFrame: UIImage?

    var latestFrame: UIImage? {
        lock.lock()
        defer { lock.unlock() }
        return _latestFrame
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }

        let image = UIImage(cgImage: cgImage)

        lock.lock()
        _latestFrame = image
        lock.unlock()
    }
}
