import UIKit

enum CaptureOrientation: String, Codable {
    case landscapeRight
    case landscapeLeft

    var displayRotationDegrees: Double {
        switch self {
        case .landscapeRight:
            return 0
        case .landscapeLeft:
            return 180
        }
    }

    static func current() -> CaptureOrientation {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            return .landscapeRight
        }

        switch windowScene.interfaceOrientation {
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight, .portrait, .portraitUpsideDown, .unknown:
            return .landscapeRight
        @unknown default:
            return .landscapeRight
        }
    }
}
