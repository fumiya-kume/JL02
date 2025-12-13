import AVFoundation
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

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        // swiftlint:disable:next force_cast
        layer as! AVCaptureVideoPreviewLayer
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateVideoRotation()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    override func removeFromSuperview() {
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

