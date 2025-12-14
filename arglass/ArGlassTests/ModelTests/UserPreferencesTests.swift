import XCTest
@testable import ArGlass

final class UserPreferencesTests: XCTestCase {

    // MARK: - UserAgeGroup Tests

    func testUserAgeGroup_allCasesCount() {
        XCTAssertEqual(UserAgeGroup.allCases.count, 4, "Should have 4 age group cases")
    }

    func testUserAgeGroup_rawValues() {
        XCTAssertEqual(UserAgeGroup.twenties.rawValue, "20s")
        XCTAssertEqual(UserAgeGroup.thirtyForties.rawValue, "30-40s")
        XCTAssertEqual(UserAgeGroup.fiftiesPlus.rawValue, "50s+")
        XCTAssertEqual(UserAgeGroup.familyWithKids.rawValue, "family_with_kids")
    }

    func testUserAgeGroup_idEqualsRawValue() {
        for ageGroup in UserAgeGroup.allCases {
            XCTAssertEqual(ageGroup.id, ageGroup.rawValue)
        }
    }

    func testUserAgeGroup_localizedNameNotEmpty() {
        for ageGroup in UserAgeGroup.allCases {
            XCTAssertFalse(ageGroup.localizedName.isEmpty, "\(ageGroup) localizedName should not be empty")
        }
    }

    func testUserAgeGroup_icons() {
        XCTAssertEqual(UserAgeGroup.twenties.icon, "person")
        XCTAssertEqual(UserAgeGroup.thirtyForties.icon, "person.2")
        XCTAssertEqual(UserAgeGroup.fiftiesPlus.icon, "person.3")
        XCTAssertEqual(UserAgeGroup.familyWithKids.icon, "figure.2.and.child.holdinghands")
    }

    func testUserAgeGroup_codable() throws {
        for original in UserAgeGroup.allCases {
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(UserAgeGroup.self, from: data)
            XCTAssertEqual(original, decoded)
        }
    }

    // MARK: - UserBudgetLevel Tests

    func testUserBudgetLevel_allCasesCount() {
        XCTAssertEqual(UserBudgetLevel.allCases.count, 3, "Should have 3 budget level cases")
    }

    func testUserBudgetLevel_rawValues() {
        XCTAssertEqual(UserBudgetLevel.budget.rawValue, "budget")
        XCTAssertEqual(UserBudgetLevel.midRange.rawValue, "mid-range")
        XCTAssertEqual(UserBudgetLevel.luxury.rawValue, "luxury")
    }

    func testUserBudgetLevel_idEqualsRawValue() {
        for budgetLevel in UserBudgetLevel.allCases {
            XCTAssertEqual(budgetLevel.id, budgetLevel.rawValue)
        }
    }

    func testUserBudgetLevel_localizedNameNotEmpty() {
        for budgetLevel in UserBudgetLevel.allCases {
            XCTAssertFalse(budgetLevel.localizedName.isEmpty, "\(budgetLevel) localizedName should not be empty")
        }
    }

    func testUserBudgetLevel_icons() {
        XCTAssertEqual(UserBudgetLevel.budget.icon, "yensign.circle")
        XCTAssertEqual(UserBudgetLevel.midRange.icon, "yensign.circle.fill")
        XCTAssertEqual(UserBudgetLevel.luxury.icon, "sparkles")
    }

    func testUserBudgetLevel_codable() throws {
        for original in UserBudgetLevel.allCases {
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(UserBudgetLevel.self, from: data)
            XCTAssertEqual(original, decoded)
        }
    }

    // MARK: - UserActivityLevel Tests

    func testUserActivityLevel_allCasesCount() {
        XCTAssertEqual(UserActivityLevel.allCases.count, 3, "Should have 3 activity level cases")
    }

    func testUserActivityLevel_rawValues() {
        XCTAssertEqual(UserActivityLevel.active.rawValue, "active")
        XCTAssertEqual(UserActivityLevel.moderate.rawValue, "moderate")
        XCTAssertEqual(UserActivityLevel.relaxed.rawValue, "relaxed")
    }

    func testUserActivityLevel_idEqualsRawValue() {
        for activityLevel in UserActivityLevel.allCases {
            XCTAssertEqual(activityLevel.id, activityLevel.rawValue)
        }
    }

    func testUserActivityLevel_localizedNameNotEmpty() {
        for activityLevel in UserActivityLevel.allCases {
            XCTAssertFalse(activityLevel.localizedName.isEmpty, "\(activityLevel) localizedName should not be empty")
        }
    }

    func testUserActivityLevel_icons() {
        XCTAssertEqual(UserActivityLevel.active.icon, "figure.run")
        XCTAssertEqual(UserActivityLevel.moderate.icon, "figure.walk")
        XCTAssertEqual(UserActivityLevel.relaxed.icon, "figure.stand")
    }

    func testUserActivityLevel_codable() throws {
        for original in UserActivityLevel.allCases {
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(UserActivityLevel.self, from: data)
            XCTAssertEqual(original, decoded)
        }
    }

    // MARK: - UserLanguage Tests

    func testUserLanguage_allCasesCount() {
        XCTAssertEqual(UserLanguage.allCases.count, 8, "Should have 8 language cases")
    }

    func testUserLanguage_rawValues() {
        XCTAssertEqual(UserLanguage.japanese.rawValue, "japanese")
        XCTAssertEqual(UserLanguage.english.rawValue, "english")
        XCTAssertEqual(UserLanguage.chinese.rawValue, "chinese")
        XCTAssertEqual(UserLanguage.korean.rawValue, "korean")
        XCTAssertEqual(UserLanguage.spanish.rawValue, "spanish")
        XCTAssertEqual(UserLanguage.french.rawValue, "french")
        XCTAssertEqual(UserLanguage.german.rawValue, "german")
        XCTAssertEqual(UserLanguage.thai.rawValue, "thai")
    }

    func testUserLanguage_idEqualsRawValue() {
        for language in UserLanguage.allCases {
            XCTAssertEqual(language.id, language.rawValue)
        }
    }

    func testUserLanguage_localizedNameNotEmpty() {
        for language in UserLanguage.allCases {
            XCTAssertFalse(language.localizedName.isEmpty, "\(language) localizedName should not be empty")
        }
    }

    func testUserLanguage_iconIsGlobe() {
        for language in UserLanguage.allCases {
            XCTAssertEqual(language.icon, "globe")
        }
    }

    func testUserLanguage_speechLocaleIdentifiers() {
        XCTAssertEqual(UserLanguage.japanese.speechLocaleIdentifier, "ja-JP")
        XCTAssertEqual(UserLanguage.english.speechLocaleIdentifier, "en-US")
        XCTAssertEqual(UserLanguage.chinese.speechLocaleIdentifier, "zh-CN")
        XCTAssertEqual(UserLanguage.korean.speechLocaleIdentifier, "ko-KR")
        XCTAssertEqual(UserLanguage.spanish.speechLocaleIdentifier, "es-ES")
        XCTAssertEqual(UserLanguage.french.speechLocaleIdentifier, "fr-FR")
        XCTAssertEqual(UserLanguage.german.speechLocaleIdentifier, "de-DE")
        XCTAssertEqual(UserLanguage.thai.speechLocaleIdentifier, "th-TH")
    }

    func testUserLanguage_fromDeviceLocale_returnsValidLanguage() {
        let language = UserLanguage.fromDeviceLocale()
        XCTAssertTrue(UserLanguage.allCases.contains(language))
    }

    func testUserLanguage_codable() throws {
        for original in UserLanguage.allCases {
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(UserLanguage.self, from: data)
            XCTAssertEqual(original, decoded)
        }
    }

    // MARK: - UserPreferences Tests

    func testUserPreferences_defaultValues() {
        let preferences = UserPreferences.default

        XCTAssertNil(preferences.ageGroup)
        XCTAssertNil(preferences.budgetLevel)
        XCTAssertNil(preferences.activityLevel)
        XCTAssertFalse(preferences.isReadAloudEnabled)
        // language defaults to device locale
        XCTAssertTrue(UserLanguage.allCases.contains(preferences.language))
    }

    func testUserPreferences_initWithAllParameters() {
        let preferences = UserPreferences(
            ageGroup: .twenties,
            budgetLevel: .luxury,
            activityLevel: .active,
            language: .english,
            isReadAloudEnabled: true
        )

        XCTAssertEqual(preferences.ageGroup, .twenties)
        XCTAssertEqual(preferences.budgetLevel, .luxury)
        XCTAssertEqual(preferences.activityLevel, .active)
        XCTAssertEqual(preferences.language, .english)
        XCTAssertTrue(preferences.isReadAloudEnabled)
    }

    func testUserPreferences_initWithDefaultParameters() {
        let preferences = UserPreferences()

        XCTAssertNil(preferences.ageGroup)
        XCTAssertNil(preferences.budgetLevel)
        XCTAssertNil(preferences.activityLevel)
        XCTAssertFalse(preferences.isReadAloudEnabled)
    }

    func testUserPreferences_codableWithAllFields() throws {
        let original = UserPreferences(
            ageGroup: .thirtyForties,
            budgetLevel: .midRange,
            activityLevel: .moderate,
            language: .japanese,
            isReadAloudEnabled: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)

        XCTAssertEqual(original, decoded)
    }

    func testUserPreferences_codableWithOptionalFieldsNil() throws {
        let original = UserPreferences(
            ageGroup: nil,
            budgetLevel: nil,
            activityLevel: nil,
            language: .english,
            isReadAloudEnabled: false
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)

        XCTAssertEqual(original, decoded)
        XCTAssertNil(decoded.ageGroup)
        XCTAssertNil(decoded.budgetLevel)
        XCTAssertNil(decoded.activityLevel)
    }

    func testUserPreferences_decoderHandlesMissingOptionalFields() throws {
        // JSON with only required field (language)
        let json = """
        {
            "language": "english"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(UserPreferences.self, from: json)

        XCTAssertNil(decoded.ageGroup)
        XCTAssertNil(decoded.budgetLevel)
        XCTAssertNil(decoded.activityLevel)
        XCTAssertEqual(decoded.language, .english)
        XCTAssertFalse(decoded.isReadAloudEnabled)
    }

    func testUserPreferences_decoderDefaultsIsReadAloudToFalse() throws {
        let json = """
        {
            "language": "japanese"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(UserPreferences.self, from: json)

        XCTAssertFalse(decoded.isReadAloudEnabled)
    }

    func testUserPreferences_equatable() {
        let preferences1 = UserPreferences(
            ageGroup: .twenties,
            budgetLevel: .budget,
            activityLevel: .relaxed,
            language: .korean,
            isReadAloudEnabled: true
        )

        let preferences2 = UserPreferences(
            ageGroup: .twenties,
            budgetLevel: .budget,
            activityLevel: .relaxed,
            language: .korean,
            isReadAloudEnabled: true
        )

        let preferences3 = UserPreferences(
            ageGroup: .fiftiesPlus,
            budgetLevel: .budget,
            activityLevel: .relaxed,
            language: .korean,
            isReadAloudEnabled: true
        )

        XCTAssertEqual(preferences1, preferences2)
        XCTAssertNotEqual(preferences1, preferences3)
    }
}
