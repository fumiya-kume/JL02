import AVFoundation
import Foundation
import UIKit

final class CameraService: ObservableObject, CameraServiceProtocol {
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
    private let authorizationProvider: CameraAuthorizationProviding

    init(authorizationProvider: CameraAuthorizationProviding = CameraAuthorizationProvider()) {
        self.authorizationProvider = authorizationProvider
    }

    func requestAccessAndStart() async {
        let status = authorizationProvider.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            guard !Task.isCancelled else { return }
            start()
        case .notDetermined:
            let granted = await authorizationProvider.requestAccess(for: .video)
            guard !Task.isCancelled else { return }
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
        session.sessionPreset = .hd1280x720

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            return false
        }

        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
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
        frameHandler.captureCurrentFrame()
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
    private let context = CIContext()
    private var latestPixelBuffer: CVPixelBuffer?

    func captureCurrentFrame() -> UIImage? {
        guard let pixelBuffer = copyLatestPixelBuffer() else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private func copyLatestPixelBuffer() -> CVPixelBuffer? {
        lock.lock()
        defer { lock.unlock() }
        return latestPixelBuffer
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        lock.lock()
        latestPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        lock.unlock()
    }
}
