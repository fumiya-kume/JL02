import XCTest
@testable import ArGlass

final class HistoryEntryTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_createsEntryWithCorrectValues() {
        let entry = HistoryEntry(
            name: "Tokyo Tower",
            yearBuilt: "1958",
            subtitle: "Communications tower",
            history: "Built as a symbol of Japan's post-war rebirth",
            distanceMeters: 150.0,
            bearingDegrees: 45.0
        )

        XCTAssertEqual(entry.name, "Tokyo Tower")
        XCTAssertEqual(entry.yearBuilt, "1958")
        XCTAssertEqual(entry.subtitle, "Communications tower")
        XCTAssertEqual(entry.distanceMeters, 150.0)
        XCTAssertEqual(entry.bearingDegrees, 45.0)
        XCTAssertNil(entry.imageFileName)
        XCTAssertNil(entry.captureOrientation)
    }

    func testInit_withCaptureOrientation_storesValue() {
        let entry = HistoryEntry(
            name: "Test",
            yearBuilt: "2020",
            subtitle: "Test",
            history: "Test",
            distanceMeters: 100.0,
            bearingDegrees: 0.0,
            captureOrientation: .landscapeLeft
        )

        XCTAssertEqual(entry.captureOrientation, .landscapeLeft)
    }

    func testInit_fromLandmark_copiesAllValues() {
        let landmark = Landmark(
            name: "Test Landmark",
            yearBuilt: "2000",
            subtitle: "Test subtitle",
            history: "Test history",
            distanceMeters: 200.0,
            bearingDegrees: 90.0
        )

        let entry = HistoryEntry(landmark: landmark)

        XCTAssertEqual(entry.name, landmark.name)
        XCTAssertEqual(entry.yearBuilt, landmark.yearBuilt)
        XCTAssertEqual(entry.subtitle, landmark.subtitle)
        XCTAssertEqual(entry.history, landmark.history)
        XCTAssertEqual(entry.distanceMeters, landmark.distanceMeters)
        XCTAssertEqual(entry.bearingDegrees, landmark.bearingDegrees)
    }

    func testInit_fromLandmark_withCaptureOrientation() {
        let landmark = Landmark(
            name: "Test",
            yearBuilt: "2020",
            subtitle: "Test",
            history: "Test",
            distanceMeters: 100.0,
            bearingDegrees: 0.0
        )

        let entry = HistoryEntry(landmark: landmark, captureOrientation: .landscapeRight)

        XCTAssertEqual(entry.captureOrientation, .landscapeRight)
    }

    func testInit_generatesUniqueIDs() {
        let entry1 = TestFixtures.makeHistoryEntry(name: "Entry 1")
        let entry2 = TestFixtures.makeHistoryEntry(name: "Entry 2")

        XCTAssertNotEqual(entry1.id, entry2.id)
    }

    // MARK: - Codable Tests

    func testCodable_encodesAndDecodesCorrectly() throws {
        let originalEntry = HistoryEntry(
            name: "Test Building",
            yearBuilt: "1990",
            subtitle: "A test building",
            history: "Built for testing purposes",
            distanceMeters: 100.0,
            bearingDegrees: 180.0,
            imageFileName: "test.jpg"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(originalEntry)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedEntry = try decoder.decode(HistoryEntry.self, from: data)

        XCTAssertEqual(decodedEntry.id, originalEntry.id)
        XCTAssertEqual(decodedEntry.name, originalEntry.name)
        XCTAssertEqual(decodedEntry.yearBuilt, originalEntry.yearBuilt)
        XCTAssertEqual(decodedEntry.subtitle, originalEntry.subtitle)
        XCTAssertEqual(decodedEntry.history, originalEntry.history)
        XCTAssertEqual(decodedEntry.distanceMeters, originalEntry.distanceMeters)
        XCTAssertEqual(decodedEntry.bearingDegrees, originalEntry.bearingDegrees)
        XCTAssertEqual(decodedEntry.imageFileName, originalEntry.imageFileName)
    }

    func testCodable_handlesNilImageFileName() throws {
        let entry = HistoryEntry(
            name: "No Image Entry",
            yearBuilt: "2020",
            subtitle: "Entry without image",
            history: "Test",
            distanceMeters: 50.0,
            bearingDegrees: 0.0
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(HistoryEntry.self, from: data)

        XCTAssertNil(decoded.imageFileName)
    }

    func testCodable_encodesAndDecodesCaptureOrientation() throws {
        let entry = HistoryEntry(
            name: "Test",
            yearBuilt: "2020",
            subtitle: "Test",
            history: "Test",
            distanceMeters: 100.0,
            bearingDegrees: 0.0,
            captureOrientation: .landscapeLeft
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(HistoryEntry.self, from: data)

        XCTAssertEqual(decoded.captureOrientation, .landscapeLeft)
    }

    func testCodable_backwardCompatibility_handlesNilCaptureOrientation() throws {
        // JSON without captureOrientation field (legacy data)
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "name": "Legacy Entry",
            "yearBuilt": "2020",
            "subtitle": "Test",
            "history": "Test",
            "distanceMeters": 100.0,
            "bearingDegrees": 0.0,
            "timestamp": "2024-01-01T00:00:00Z"
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(HistoryEntry.self, from: data)

        XCTAssertNil(decoded.captureOrientation)
    }

    // MARK: - Equatable Tests

    func testEquatable_sameEntriesAreEqual() {
        let id = UUID()
        let timestamp = Date()

        let entry1 = HistoryEntry(
            id: id,
            name: "Test",
            yearBuilt: "2020",
            subtitle: "Sub",
            history: "History",
            distanceMeters: 100,
            bearingDegrees: 45,
            timestamp: timestamp
        )

        let entry2 = HistoryEntry(
            id: id,
            name: "Test",
            yearBuilt: "2020",
            subtitle: "Sub",
            history: "History",
            distanceMeters: 100,
            bearingDegrees: 45,
            timestamp: timestamp
        )

        XCTAssertEqual(entry1, entry2)
    }

    func testEquatable_differentIDsMeansNotEqual() {
        let entry1 = TestFixtures.makeHistoryEntry(name: "Test")
        let entry2 = TestFixtures.makeHistoryEntry(name: "Test")

        XCTAssertNotEqual(entry1, entry2)
    }
}
