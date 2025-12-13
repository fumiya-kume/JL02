import XCTest
@testable import ArGlass

final class LandmarkTests: XCTestCase {
    
    func testLandmarkInitialization() {
        let landmark = Landmark(
            name: "Tokyo Tower",
            yearBuilt: "1958",
            subtitle: "Iconic communications tower",
            history: "Built in 1958, it has become a symbol of Tokyo.",
            distanceMeters: 500.0,
            bearingDegrees: 45.0
        )
        
        XCTAssertEqual(landmark.name, "Tokyo Tower")
        XCTAssertEqual(landmark.yearBuilt, "1958")
        XCTAssertEqual(landmark.subtitle, "Iconic communications tower")
        XCTAssertEqual(landmark.history, "Built in 1958, it has become a symbol of Tokyo.")
        XCTAssertEqual(landmark.distanceMeters, 500.0)
        XCTAssertEqual(landmark.bearingDegrees, 45.0)
        XCTAssertNotNil(landmark.id)
    }
    
    func testLandmarkWithDefaultID() {
        let landmark1 = Landmark(
            name: "Test",
            yearBuilt: "2020",
            subtitle: "Test",
            history: "Test",
            distanceMeters: 0,
            bearingDegrees: 0
        )
        
        let landmark2 = Landmark(
            name: "Test",
            yearBuilt: "2020",
            subtitle: "Test",
            history: "Test",
            distanceMeters: 0,
            bearingDegrees: 0
        )
        
        XCTAssertNotEqual(landmark1.id, landmark2.id, "Default IDs should be unique")
    }
    
    func testLandmarkEquality() {
        let id = UUID()
        
        let landmark1 = Landmark(
            id: id,
            name: "Same Name",
            yearBuilt: "2020",
            subtitle: "Same Subtitle",
            history: "Same History",
            distanceMeters: 100.0,
            bearingDegrees: 45.0
        )
        
        let landmark2 = Landmark(
            id: id,
            name: "Same Name",
            yearBuilt: "2020",
            subtitle: "Same Subtitle",
            history: "Same History",
            distanceMeters: 100.0,
            bearingDegrees: 45.0
        )
        
        let landmark3 = Landmark(
            id: id,
            name: "Different Name", // Different name
            yearBuilt: "2020",
            subtitle: "Same Subtitle",
            history: "Same History",
            distanceMeters: 100.0,
            bearingDegrees: 45.0
        )
        
        XCTAssertEqual(landmark1, landmark2, "Landmarks with same properties should be equal")
        XCTAssertNotEqual(landmark1, landmark3, "Landmarks with different names should not be equal")
    }
    
    func testLandmarkIdentifiable() {
        let landmark = Landmark(
            name: "Test",
            yearBuilt: "2020",
            subtitle: "Test",
            history: "Test",
            distanceMeters: 0,
            bearingDegrees: 0
        )
        
        // Test that it conforms to Identifiable
        let id: UUID = landmark.id
        XCTAssertEqual(id, landmark.id)
    }
    
    func testCodable() throws {
        let original = Landmark(
            name: "Test Landmark",
            yearBuilt: "2023",
            subtitle: "Test subtitle",
            history: "Test history",
            distanceMeters: 250.5,
            bearingDegrees: 180.0
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Landmark.self, from: data)
        
        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.name, decoded.name)
        XCTAssertEqual(original.yearBuilt, decoded.yearBuilt)
        XCTAssertEqual(original.subtitle, decoded.subtitle)
        XCTAssertEqual(original.history, decoded.history)
        XCTAssertEqual(original.distanceMeters, decoded.distanceMeters)
        XCTAssertEqual(original.bearingDegrees, decoded.bearingDegrees)
        XCTAssertEqual(original, decoded, "Decoded landmark should equal original")
    }
}
