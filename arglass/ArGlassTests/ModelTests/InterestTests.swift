import XCTest
@testable import ArGlass

final class InterestTests: XCTestCase {
    
    func testAllInterestsCount() {
        XCTAssertEqual(Interest.allInterests.count, 7, "Should have 7 predefined interests")
    }
    
    func testInterestProperties() {
        let history = Interest.allInterests.first { $0.id == "history" }!
        
        XCTAssertEqual(history.id, "history")
        XCTAssertEqual(history.nameKey, "interest_history")
        XCTAssertEqual(history.icon, "building.columns")
        XCTAssertFalse(history.localizedName.isEmpty, "localizedName should not be empty")
    }
    
    func testLocalizedNameUsesLocalization() {
        let interest = Interest.allInterests.first!
        // This test ensures localizedName is using NSLocalizedString
        // The actual value depends on the localization bundle
        let name = interest.localizedName
        XCTAssertFalse(name.isEmpty, "Localized name should not be empty")
        XCTAssertEqual(name, NSLocalizedString(interest.nameKey, comment: "Interest category name"))
    }
    
    func testUniqueIDs() {
        let ids = Interest.allInterests.map { $0.id }
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count, "All interest IDs should be unique")
    }
    
    func testHashableAndEquatable() {
        let history1 = Interest.allInterests.first { $0.id == "history" }!
        let history2 = Interest.allInterests.first { $0.id == "history" }!
        let architecture = Interest.allInterests.first { $0.id == "architecture" }!

        XCTAssertEqual(history1, history2, "Same interests should be equal")
        XCTAssertNotEqual(history1, architecture, "Different interests should not be equal")

        let hash1 = history1.hashValue
        let hash2 = history2.hashValue
        let hash3 = architecture.hashValue

        XCTAssertEqual(hash1, hash2, "Hash values should be equal for equal interests")
        XCTAssertNotEqual(hash1, hash3, "Hash values should differ for different interests")
    }
    
    func testCodable() throws {
        let original = Interest.allInterests.randomElement()!
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Interest.self, from: data)
        
        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.nameKey, decoded.nameKey)
        XCTAssertEqual(original.icon, decoded.icon)
        XCTAssertEqual(original, decoded, "Decoded interest should equal original")
    }
}
