import XCTest
@testable import ArGlass

final class UserPreferencesManagerTests: XCTestCase {
    private var sut: UserPreferencesManager!
    private var mockUserDefaults: MockUserDefaults!

    override func setUp() {
        mockUserDefaults = MockUserDefaults()
        sut = UserPreferencesManager(userDefaults: mockUserDefaults)
    }

    override func tearDown() {
        sut = nil
        mockUserDefaults = nil
    }

    // MARK: - Save/Load Preferences Tests

    func testSave_encodesAndStoresPreferences() {
        let preferences = UserPreferences(
            ageGroup: .twenties,
            budgetLevel: .midRange,
            activityLevel: .active,
            language: .english
        )

        sut.save(preferences)

        let storedData = mockUserDefaults.data(forKey: "userPreferences")
        XCTAssertNotNil(storedData)
    }

    func testLoad_whenNoData_returnsDefaultPreferences() {
        let preferences = sut.load()

        XCTAssertNil(preferences.ageGroup)
        XCTAssertNil(preferences.budgetLevel)
        XCTAssertNil(preferences.activityLevel)
    }

    func testLoad_whenValidData_decodesPreferences() {
        let originalPreferences = UserPreferences(
            ageGroup: .thirtyForties,
            budgetLevel: .luxury,
            activityLevel: .relaxed,
            language: .japanese
        )
        sut.save(originalPreferences)

        let loadedPreferences = sut.load()

        XCTAssertEqual(loadedPreferences.ageGroup, .thirtyForties)
        XCTAssertEqual(loadedPreferences.budgetLevel, .luxury)
        XCTAssertEqual(loadedPreferences.activityLevel, .relaxed)
        XCTAssertEqual(loadedPreferences.language, .japanese)
    }

    func testLoad_whenCorruptedData_returnsDefaultPreferences() {
        let invalidData = "invalid json".data(using: .utf8)!
        mockUserDefaults.set(invalidData, forKey: "userPreferences")

        let preferences = sut.load()

        XCTAssertNil(preferences.ageGroup)
        XCTAssertNil(preferences.budgetLevel)
        XCTAssertNil(preferences.activityLevel)
    }

    func testSaveAndLoad_roundTrip_preservesAllFields() {
        let original = UserPreferences(
            ageGroup: .familyWithKids,
            budgetLevel: .budget,
            activityLevel: .moderate,
            language: .korean
        )

        sut.save(original)
        let loaded = sut.load()

        XCTAssertEqual(loaded, original)
    }

    // MARK: - Migration Tests

    func testMigrateInterestsIfNeeded_whenAlreadyMigrated_returnsFalse() {
        mockUserDefaults.set(true, forKey: "interestMigrationCompleted_v2")

        let result = sut.migrateInterestsIfNeeded()

        XCTAssertFalse(result)
    }

    func testMigrateInterestsIfNeeded_whenNoExistingInterests_marksMigratedAndReturnsFalse() {
        let result = sut.migrateInterestsIfNeeded()

        XCTAssertFalse(result)
        XCTAssertTrue(mockUserDefaults.bool(forKey: "interestMigrationCompleted_v2"))
    }

    func testMigrateInterestsIfNeeded_filtersDiscontinuedInterests() {
        // Set up interests with some discontinued ones
        // continuingInterestIDs = ["history", "nature", "art", "food"]
        // "architecture", "shopping", "nightlife" are discontinued
        mockUserDefaults.set(["history", "architecture", "shopping", "art"], forKey: "selectedInterestIDs")

        _ = sut.migrateInterestsIfNeeded()

        let migratedIDs = mockUserDefaults.stringArray(forKey: "selectedInterestIDs")
        XCTAssertEqual(Set(migratedIDs ?? []), Set(["history", "art"]))
    }

    func testMigrateInterestsIfNeeded_whenBelowMinSelection_returnsTrue() {
        // Only 2 continuing interests (minSelection is 3)
        mockUserDefaults.set(["history", "art"], forKey: "selectedInterestIDs")

        let result = sut.migrateInterestsIfNeeded()

        XCTAssertTrue(result)
    }

    func testMigrateInterestsIfNeeded_whenAtMinSelection_returnsFalse() {
        // 3 continuing interests (minSelection is 3)
        mockUserDefaults.set(["history", "art", "nature"], forKey: "selectedInterestIDs")

        let result = sut.migrateInterestsIfNeeded()

        XCTAssertFalse(result)
    }

    func testMigrateInterestsIfNeeded_whenAboveMinSelection_returnsFalse() {
        // 4 continuing interests (minSelection is 3)
        mockUserDefaults.set(["history", "art", "nature", "food"], forKey: "selectedInterestIDs")

        let result = sut.migrateInterestsIfNeeded()

        XCTAssertFalse(result)
    }

    // MARK: - Interest Reselection Tests

    func testNeedsInterestReselection_whenNoInterests_returnsTrue() {
        let result = sut.needsInterestReselection()

        XCTAssertTrue(result)
    }

    func testNeedsInterestReselection_whenBelowMinimum_returnsTrue() {
        mockUserDefaults.set(["history", "art"], forKey: "selectedInterestIDs")

        let result = sut.needsInterestReselection()

        XCTAssertTrue(result)
    }

    func testNeedsInterestReselection_whenAtMinimum_returnsFalse() {
        mockUserDefaults.set(["history", "art", "nature"], forKey: "selectedInterestIDs")

        let result = sut.needsInterestReselection()

        XCTAssertFalse(result)
    }

    func testNeedsInterestReselection_filtersInvalidInterests() {
        // 2 valid interests + 1 invalid
        mockUserDefaults.set(["history", "art", "invalid_id"], forKey: "selectedInterestIDs")

        let result = sut.needsInterestReselection()

        XCTAssertTrue(result)
    }

    func testNeedsInterestReselection_countsOnlyValidInterests() {
        // 3 valid interests + some invalid
        mockUserDefaults.set(["history", "art", "nature", "invalid1", "invalid2"], forKey: "selectedInterestIDs")

        let result = sut.needsInterestReselection()

        XCTAssertFalse(result)
    }
}
