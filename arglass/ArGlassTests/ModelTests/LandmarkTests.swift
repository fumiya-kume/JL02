import XCTest
@testable import ArGlass

final class LandmarkTests: XCTestCase {

    func testLandmarkInitialization() {
        let landmark = Landmark(
            name: "Tokyo Tower",
            description: "Built in 1958, it has become a symbol of Tokyo."
        )

        XCTAssertEqual(landmark.name, "Tokyo Tower")
        XCTAssertEqual(landmark.description, "Built in 1958, it has become a symbol of Tokyo.")
        XCTAssertNotNil(landmark.id)
    }

    func testLandmarkWithDefaultID() {
        let landmark1 = Landmark(
            name: "Test",
            description: "Test"
        )

        let landmark2 = Landmark(
            name: "Test",
            description: "Test"
        )

        XCTAssertNotEqual(landmark1.id, landmark2.id, "Default IDs should be unique")
    }

    func testLandmarkEquality() {
        let id = UUID()

        let landmark1 = Landmark(
            id: id,
            name: "Same Name",
            description: "Same Description"
        )

        let landmark2 = Landmark(
            id: id,
            name: "Same Name",
            description: "Same Description"
        )

        let landmark3 = Landmark(
            id: id,
            name: "Different Name",
            description: "Same Description"
        )

        XCTAssertEqual(landmark1, landmark2, "Landmarks with same properties should be equal")
        XCTAssertNotEqual(landmark1, landmark3, "Landmarks with different names should not be equal")
    }

    func testLandmarkIdentifiable() {
        let landmark = Landmark(
            name: "Test",
            description: "Test"
        )

        // Test that it conforms to Identifiable
        let id: UUID = landmark.id
        XCTAssertEqual(id, landmark.id)
    }

    func testCodable() throws {
        let original = Landmark(
            name: "Test Landmark",
            description: "Test description"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Landmark.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.description, decoded.description)
        XCTAssertEqual(original, decoded, "Decoded landmark should equal original")
    }
}
