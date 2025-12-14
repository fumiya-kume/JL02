import Foundation

struct HistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let yearBuilt: String
    let subtitle: String
    let history: String
    let timestamp: Date
    let imageFileName: String?
    let captureOrientation: CaptureOrientation?

    init(
        id: UUID = UUID(),
        name: String,
        yearBuilt: String,
        subtitle: String,
        history: String,
        timestamp: Date = Date(),
        imageFileName: String? = nil,
        captureOrientation: CaptureOrientation? = nil
    ) {
        self.id = id
        self.name = name
        self.yearBuilt = yearBuilt
        self.subtitle = subtitle
        self.history = history
        self.timestamp = timestamp
        self.imageFileName = imageFileName
        self.captureOrientation = captureOrientation
    }

    init(landmark: Landmark, imageFileName: String? = nil, timestamp: Date = Date(), captureOrientation: CaptureOrientation? = nil) {
        self.id = UUID()
        self.name = landmark.name
        self.yearBuilt = landmark.yearBuilt
        self.subtitle = landmark.subtitle
        self.history = landmark.history
        self.timestamp = timestamp
        self.imageFileName = imageFileName
        self.captureOrientation = captureOrientation
    }
}
