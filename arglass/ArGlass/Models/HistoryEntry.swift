import Foundation

struct HistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let description: String
    let timestamp: Date
    let imageFileName: String?
    let captureOrientation: CaptureOrientation?

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        timestamp: Date = Date(),
        imageFileName: String? = nil,
        captureOrientation: CaptureOrientation? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.timestamp = timestamp
        self.imageFileName = imageFileName
        self.captureOrientation = captureOrientation
    }

    init(landmark: Landmark, imageFileName: String? = nil, timestamp: Date = Date(), captureOrientation: CaptureOrientation? = nil) {
        self.id = UUID()
        self.name = landmark.name
        self.description = landmark.description
        self.timestamp = timestamp
        self.imageFileName = imageFileName
        self.captureOrientation = captureOrientation
    }
}
