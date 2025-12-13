import UIKit
import Foundation
import CoreLocation
import AVFoundation

// MARK: - Service Protocols

protocol CameraServiceProtocol: AnyObject {
    var state: CameraService.CameraState { get }
    var session: AVCaptureSession { get }
    func requestAccessAndStart() async
    func stop()
    func captureCurrentFrame() -> UIImage?
}

@MainActor
protocol LocationServiceProtocol: AnyObject {
    var state: LocationService.LocationState { get }
    var currentLocation: LocationInfo? { get }
    var showDeniedAlert: Bool { get }
    func requestAuthorization()
    func startUpdating()
    func stopUpdating()
}

protocol VLMAPIClientProtocol: Actor {
    func inferLandmark(image: UIImage, locationInfo: LocationInfo?, interests: Set<Interest>, preferences: UserPreferences) async throws -> Landmark
    func inferLandmark(jpegData: Data, locationInfo: LocationInfo?, interests: Set<Interest>, preferences: UserPreferences) async throws -> Landmark
}

protocol HistoryServiceProtocol: Actor {
    func loadHistory() -> [HistoryEntry]
    func addEntry(_ entry: HistoryEntry, image: UIImage?) async
    func deleteEntry(_ entry: HistoryEntry) async
    func clearAll() async
    func imageURL(for entry: HistoryEntry) -> URL?
}
