import Foundation
@testable import ArGlass

enum TestFixtures {

    static func makeLandmark(
        name: String = "Test Landmark",
        description: String = "Test description"
    ) -> Landmark {
        Landmark(
            name: name,
            description: description
        )
    }

    static func makeHistoryEntry(
        id: UUID = UUID(),
        name: String = "Test Entry",
        description: String = "Test description",
        timestamp: Date = Date(),
        imageFileName: String? = nil,
        captureOrientation: CaptureOrientation? = nil
    ) -> HistoryEntry {
        HistoryEntry(
            id: id,
            name: name,
            description: description,
            timestamp: timestamp,
            imageFileName: imageFileName,
            captureOrientation: captureOrientation
        )
    }
}
