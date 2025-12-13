import AVFoundation
import Combine
import SwiftUI
import UIKit

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    private var cancellables = Set<AnyCancellable>()

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        // connection が設定されたら回転を更新
        videoPreviewLayer.publisher(for: \.connection)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateVideoRotation()
            }
            .store(in: &cancellables)

        // 既に connection がある場合は即座に更新
        updateVideoRotation()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    override func removeFromSuperview() {
        cancellables.removeAll()
        NotificationCenter.default.removeObserver(self)
        super.removeFromSuperview()
    }

    @objc private func handleOrientationChange() {
        updateVideoRotation()
    }

    private func updateVideoRotation() {
        guard let connection = videoPreviewLayer.connection else { return }

        let angle = currentVideoRotationAngle()
        if connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }
    }

    private func currentVideoRotationAngle() -> CGFloat {
        guard let windowScene = window?.windowScene else {
            return 90 // デフォルト: ランドスケープ右
        }

        switch windowScene.interfaceOrientation {
        case .portrait:
            return 90
        case .portraitUpsideDown:
            return 270
        case .landscapeLeft:
            return 180
        case .landscapeRight:
            return 0
        default:
            return 90
        }
    }
}

