import UIKit
import Foundation
import CoreLocation
import AVFoundation
@testable import ArGlass

// MARK: - Mock Camera Service

final class MockCameraService: CameraServiceProtocol {
    var state: CameraService.CameraState = .idle
    var mockFrame: UIImage?
    var shouldFailCapture = false
    let session = AVCaptureSession()
    
    func requestAccessAndStart() async {
        state = .running
    }
    
    func stop() {
        state = .idle
    }
    
    func captureCurrentFrame() -> UIImage? {
        if shouldFailCapture {
            return nil
        }
        return mockFrame ?? UIImage(systemName: "camera")
    }
}

// MARK: - Mock Location Service

final class MockLocationService: LocationServiceProtocol {
    @Published var state: LocationService.LocationState = .idle
    @Published var currentLocation: LocationInfo?
    @Published var showDeniedAlert: Bool = false
    
    func requestAuthorization() {
        state = .authorized
        currentLocation = LocationInfo(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            locality: "Tokyo",
            subLocality: "Shibuya",
            thoroughfare: nil,
            subThoroughfare: nil
        )
        startUpdating()
    }
    
    func startUpdating() {
        state = .updating
    }
    
    func stopUpdating() {
        state = .authorized
    }
}

// MARK: - Mock VLM API Client

actor MockVLMAPIClient: VLMAPIClientProtocol {
    var shouldFailInference = false
    var mockLandmark: Landmark?
    var inferenceCallCount = 0
    var lastPreferences: UserPreferences?

    func inferLandmark(image: UIImage, locationInfo: LocationInfo?, interests: Set<Interest>, preferences: UserPreferences) async throws -> Landmark {
        inferenceCallCount += 1
        lastPreferences = preferences

        if shouldFailInference {
            throw VLMError.apiError(message: "Mock error")
        }

        return mockLandmark ?? TestFixtures.makeLandmark(name: "Mock Landmark")
    }

    func inferLandmark(jpegData: Data, locationInfo: LocationInfo?, interests: Set<Interest>, preferences: UserPreferences) async throws -> Landmark {
        return try await inferLandmark(image: UIImage(), locationInfo: locationInfo, interests: interests, preferences: preferences)
    }

    func setShouldFailInference(_ value: Bool) {
        shouldFailInference = value
    }

    func setMockLandmark(_ landmark: Landmark?) {
        mockLandmark = landmark
    }
}

// MARK: - Mock History Service

actor MockHistoryService: HistoryServiceProtocol {
    var entries: [HistoryEntry] = []
    var addEntryCallCount = 0
    var lastAddedEntry: HistoryEntry?
    var lastAddedImage: UIImage?
    var deleteEntryCallCount = 0
    var clearAllCallCount = 0
    var lastDeletedEntry: HistoryEntry?
    var mockImageURLs: [UUID: URL] = [:]
    
    func loadHistory() -> [HistoryEntry] {
        return entries
    }
    
    func addEntry(_ entry: HistoryEntry, image: UIImage?) async {
        addEntryCallCount += 1
        lastAddedEntry = entry
        lastAddedImage = image
        entries.insert(entry, at: 0)
    }
    
    func deleteEntry(_ entry: HistoryEntry) async {
        deleteEntryCallCount += 1
        lastDeletedEntry = entry
        entries.removeAll { $0.id == entry.id }
    }
    
    func clearAll() async {
        clearAllCallCount += 1
        entries.removeAll()
    }
    
    func imageURL(for entry: HistoryEntry) -> URL? {
        return mockImageURLs[entry.id]
    }
    
    func getAddEntryCallCount() -> Int {
        return addEntryCallCount
    }
    
    func setEntries(_ newEntries: [HistoryEntry]) {
        entries = newEntries
    }
    
    func setMockImageURL(_ url: URL?, for entryID: UUID) {
        if let url = url {
            mockImageURLs[entryID] = url
        } else {
            mockImageURLs.removeValue(forKey: entryID)
        }
    }
    
    func getDeleteEntryCallCount() -> Int {
        return deleteEntryCallCount
    }
    
    func getClearAllCallCount() -> Int {
        return clearAllCallCount
    }
    
    func reset() {
        entries = []
        addEntryCallCount = 0
        deleteEntryCallCount = 0
        clearAllCallCount = 0
        lastAddedEntry = nil
        lastAddedImage = nil
        lastDeletedEntry = nil
        mockImageURLs = [:]
    }
}
