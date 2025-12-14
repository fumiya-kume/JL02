import Foundation
@testable import ArGlass

enum TestFixtures {

    static func makeLandmark(
        name: String = "Test Landmark",
        yearBuilt: String = "2020",
        subtitle: String = "A test landmark",
        history: String = "Test history description"
    ) -> Landmark {
        Landmark(
            name: name,
            yearBuilt: yearBuilt,
            subtitle: subtitle,
            history: history
        )
    }

    static func makeHistoryEntry(
        id: UUID = UUID(),
        name: String = "Test Entry",
        yearBuilt: String = "2020",
        subtitle: String = "Test subtitle",
        history: String = "Test history",
        timestamp: Date = Date(),
        imageFileName: String? = nil,
        captureOrientation: CaptureOrientation? = nil
    ) -> HistoryEntry {
        HistoryEntry(
            id: id,
            name: name,
            yearBuilt: yearBuilt,
            subtitle: subtitle,
            history: history,
            timestamp: timestamp,
            imageFileName: imageFileName,
            captureOrientation: captureOrientation
        )
    }
}
