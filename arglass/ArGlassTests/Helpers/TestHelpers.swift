import Foundation
@testable import ArGlass

enum TestFixtures {

    static func makeLandmark(
        name: String = "Test Landmark",
        yearBuilt: String = "2020",
        subtitle: String = "A test landmark",
        history: String = "Test history description",
        distanceMeters: Double = 100.0,
        bearingDegrees: Double = 45.0
    ) -> Landmark {
        Landmark(
            name: name,
            yearBuilt: yearBuilt,
            subtitle: subtitle,
            history: history,
            distanceMeters: distanceMeters,
            bearingDegrees: bearingDegrees
        )
    }

    static func makeHistoryEntry(
        id: UUID = UUID(),
        name: String = "Test Entry",
        yearBuilt: String = "2020",
        subtitle: String = "Test subtitle",
        history: String = "Test history",
        distanceMeters: Double = 50.0,
        bearingDegrees: Double = 90.0,
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
            distanceMeters: distanceMeters,
            bearingDegrees: bearingDegrees,
            timestamp: timestamp,
            imageFileName: imageFileName,
            captureOrientation: captureOrientation
        )
    }
}
