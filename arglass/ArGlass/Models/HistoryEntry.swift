import Foundation

struct HistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let yearBuilt: String
    let subtitle: String
    let history: String
    let distanceMeters: Double
    let bearingDegrees: Double
    let timestamp: Date
    let imageFileName: String?

    init(
        id: UUID = UUID(),
        name: String,
        yearBuilt: String,
        subtitle: String,
        history: String,
        distanceMeters: Double,
        bearingDegrees: Double,
        timestamp: Date = Date(),
        imageFileName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.yearBuilt = yearBuilt
        self.subtitle = subtitle
        self.history = history
        self.distanceMeters = distanceMeters
        self.bearingDegrees = bearingDegrees
        self.timestamp = timestamp
        self.imageFileName = imageFileName
    }

    init(landmark: Landmark, imageFileName: String? = nil, timestamp: Date = Date()) {
        self.id = UUID()
        self.name = landmark.name
        self.yearBuilt = landmark.yearBuilt
        self.subtitle = landmark.subtitle
        self.history = landmark.history
        self.distanceMeters = landmark.distanceMeters
        self.bearingDegrees = landmark.bearingDegrees
        self.timestamp = timestamp
        self.imageFileName = imageFileName
    }
}
