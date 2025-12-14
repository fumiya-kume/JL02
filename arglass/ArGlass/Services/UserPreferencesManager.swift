import Foundation

final class UserPreferencesManager {
    static let shared = UserPreferencesManager()

    private let userDefaults: UserDefaultsProtocol
    private let userDefaultsKey = "userPreferences"
    private let interestMigrationKey = "interestMigrationCompleted_v2"

    init(userDefaults: UserDefaultsProtocol = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - User Preferences

    func save(_ preferences: UserPreferences) {
        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: userDefaultsKey)
        }
    }

    func load() -> UserPreferences {
        guard let data = userDefaults.data(forKey: userDefaultsKey),
              let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return .default
        }
        return preferences
    }

    // MARK: - Interest Migration

    func migrateInterestsIfNeeded() -> Bool {
        guard !userDefaults.bool(forKey: interestMigrationKey) else {
            return false
        }

        guard let ids = userDefaults.stringArray(forKey: "selectedInterestIDs") else {
            userDefaults.set(true, forKey: interestMigrationKey)
            return false
        }

        let migratedIDs = ids.filter { Interest.continuingInterestIDs.contains($0) }
        userDefaults.set(migratedIDs, forKey: "selectedInterestIDs")
        userDefaults.set(true, forKey: interestMigrationKey)

        return migratedIDs.count < OnboardingViewModel.minSelection
    }

    func needsInterestReselection() -> Bool {
        guard let ids = userDefaults.stringArray(forKey: "selectedInterestIDs") else {
            return true
        }
        let validCount = ids.filter { Interest.allInterests.map(\.id).contains($0) }.count
        return validCount < OnboardingViewModel.minSelection
    }
}
