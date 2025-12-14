import XCTest
@testable import ArGlass

final class HistoryEntryTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_createsEntryWithCorrectValues() {
        let entry = HistoryEntry(
            name: "Tokyo Tower",
            description: "Built as a symbol of Japan's post-war rebirth"
        )

        XCTAssertEqual(entry.name, "Tokyo Tower")
        XCTAssertEqual(entry.description, "Built as a symbol of Japan's post-war rebirth")
        XCTAssertNil(entry.imageFileName)
        XCTAssertNil(entry.captureOrientation)
    }

    func testInit_withCaptureOrientation_storesValue() {
        let entry = HistoryEntry(
            name: "Test",
            description: "Test description",
            captureOrientation: .landscapeLeft
        )

        XCTAssertEqual(entry.captureOrientation, .landscapeLeft)
    }

    func testInit_fromLandmark_copiesAllValues() {
        let landmark = Landmark(
            name: "Test Landmark",
            description: "Test description"
        )

        let entry = HistoryEntry(landmark: landmark)

        XCTAssertEqual(entry.name, landmark.name)
        XCTAssertEqual(entry.description, landmark.description)
    }

    func testInit_fromLandmark_withCaptureOrientation() {
        let landmark = Landmark(
            name: "Test",
            description: "Test description"
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
            description: "Built for testing purposes",
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
        XCTAssertEqual(decodedEntry.description, originalEntry.description)
        XCTAssertEqual(decodedEntry.imageFileName, originalEntry.imageFileName)
    }

    func testCodable_handlesNilImageFileName() throws {
        let entry = HistoryEntry(
            name: "No Image Entry",
            description: "Entry without image"
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
            description: "Test description",
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
            "description": "Test description",
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
            description: "Description",
            timestamp: timestamp
        )

        let entry2 = HistoryEntry(
            id: id,
            name: "Test",
            description: "Description",
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
