import Foundation

// MARK: - User Age Group

enum UserAgeGroup: String, Codable, CaseIterable, Identifiable {
    case twenties = "20s"
    case thirtyForties = "30-40s"
    case fiftiesPlus = "50s+"
    case familyWithKids = "family_with_kids"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .twenties:
            return NSLocalizedString("age_group_20s", comment: "")
        case .thirtyForties:
            return NSLocalizedString("age_group_30_40s", comment: "")
        case .fiftiesPlus:
            return NSLocalizedString("age_group_50splus", comment: "")
        case .familyWithKids:
            return NSLocalizedString("age_group_family_with_kids", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .twenties: return "person"
        case .thirtyForties: return "person.2"
        case .fiftiesPlus: return "person.3"
        case .familyWithKids: return "figure.2.and.child.holdinghands"
        }
    }
}

// MARK: - User Budget Level

enum UserBudgetLevel: String, Codable, CaseIterable, Identifiable {
    case budget = "budget"
    case midRange = "mid-range"
    case luxury = "luxury"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .budget:
            return NSLocalizedString("budget_budget", comment: "")
        case .midRange:
            return NSLocalizedString("budget_mid_range", comment: "")
        case .luxury:
            return NSLocalizedString("budget_luxury", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .budget: return "yensign.circle"
        case .midRange: return "yensign.circle.fill"
        case .luxury: return "sparkles"
        }
    }
}

// MARK: - User Activity Level

enum UserActivityLevel: String, Codable, CaseIterable, Identifiable {
    case active = "active"
    case moderate = "moderate"
    case relaxed = "relaxed"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .active:
            return NSLocalizedString("activity_active", comment: "")
        case .moderate:
            return NSLocalizedString("activity_moderate", comment: "")
        case .relaxed:
            return NSLocalizedString("activity_relaxed", comment: "")
        }
    }

    var icon: String {
        switch self {
        case .active: return "figure.run"
        case .moderate: return "figure.walk"
        case .relaxed: return "figure.stand"
        }
    }
}

// MARK: - User Language

enum UserLanguage: String, Codable, CaseIterable, Identifiable {
    case japanese = "japanese"
    case english = "english"
    case chinese = "chinese"
    case korean = "korean"
    case spanish = "spanish"
    case french = "french"
    case german = "german"
    case thai = "thai"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .japanese:
            return NSLocalizedString("language_japanese", comment: "")
        case .english:
            return NSLocalizedString("language_english", comment: "")
        case .chinese:
            return NSLocalizedString("language_chinese", comment: "")
        case .korean:
            return NSLocalizedString("language_korean", comment: "")
        case .spanish:
            return NSLocalizedString("language_spanish", comment: "")
        case .french:
            return NSLocalizedString("language_french", comment: "")
        case .german:
            return NSLocalizedString("language_german", comment: "")
        case .thai:
            return NSLocalizedString("language_thai", comment: "")
        }
    }

    var icon: String { "globe" }

    var speechLocaleIdentifier: String {
        switch self {
        case .japanese: return "ja-JP"
        case .english: return "en-US"
        case .chinese: return "zh-CN"
        case .korean: return "ko-KR"
        case .spanish: return "es-ES"
        case .french: return "fr-FR"
        case .german: return "de-DE"
        case .thai: return "th-TH"
        }
    }

    static func fromDeviceLocale() -> UserLanguage {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "ja"
        switch languageCode {
        case "ja": return .japanese
        case "en": return .english
        case "zh": return .chinese
        case "ko": return .korean
        case "es": return .spanish
        case "fr": return .french
        case "de": return .german
        case "th": return .thai
        default: return .japanese
        }
    }
}

// MARK: - User Preferences Container

struct UserPreferences: Codable, Equatable {
    var ageGroup: UserAgeGroup?
    var budgetLevel: UserBudgetLevel?
    var activityLevel: UserActivityLevel?
    var language: UserLanguage
    var isReadAloudEnabled: Bool

    static let `default` = UserPreferences(
        ageGroup: nil,
        budgetLevel: nil,
        activityLevel: nil,
        language: .fromDeviceLocale(),
        isReadAloudEnabled: false
    )

    init(
        ageGroup: UserAgeGroup? = nil,
        budgetLevel: UserBudgetLevel? = nil,
        activityLevel: UserActivityLevel? = nil,
        language: UserLanguage = .fromDeviceLocale(),
        isReadAloudEnabled: Bool = false
    ) {
        self.ageGroup = ageGroup
        self.budgetLevel = budgetLevel
        self.activityLevel = activityLevel
        self.language = language
        self.isReadAloudEnabled = isReadAloudEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ageGroup = try container.decodeIfPresent(UserAgeGroup.self, forKey: .ageGroup)
        budgetLevel = try container.decodeIfPresent(UserBudgetLevel.self, forKey: .budgetLevel)
        activityLevel = try container.decodeIfPresent(UserActivityLevel.self, forKey: .activityLevel)
        language = try container.decodeIfPresent(UserLanguage.self, forKey: .language) ?? .fromDeviceLocale()
        isReadAloudEnabled = try container.decodeIfPresent(Bool.self, forKey: .isReadAloudEnabled) ?? false
    }
}
