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
    func inferLandmark(image: UIImage, locationInfo: LocationInfo?, interests: Set<Interest>, preferences: UserPreferences, text: String?) async throws -> Landmark
    func inferLandmark(jpegData: Data, locationInfo: LocationInfo?, interests: Set<Interest>, preferences: UserPreferences, text: String?) async throws -> Landmark
}

protocol HistoryServiceProtocol: Actor {
    func loadHistory() -> [HistoryEntry]
    func addEntry(_ entry: HistoryEntry, image: UIImage?) async
    func deleteEntry(_ entry: HistoryEntry) async
    func clearAll() async
    func imageURL(for entry: HistoryEntry) -> URL?
}

// MARK: - UserDefaults Protocol

protocol UserDefaultsProtocol {
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
    func bool(forKey defaultName: String) -> Bool
    func stringArray(forKey defaultName: String) -> [String]?
}

extension UserDefaults: UserDefaultsProtocol {}

// MARK: - Battery Providing Protocol

protocol BatteryProviding {
    var batteryLevel: Float { get }
    var batteryState: UIDevice.BatteryState { get }
}

extension UIDevice: BatteryProviding {}
