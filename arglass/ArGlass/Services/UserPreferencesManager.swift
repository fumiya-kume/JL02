import Foundation

final class UserPreferencesManager {
    static let shared = UserPreferencesManager()

    private let userDefaultsKey = "userPreferences"
    private let interestMigrationKey = "interestMigrationCompleted_v2"

    private init() {}

    // MARK: - User Preferences

    func save(_ preferences: UserPreferences) {
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    func load() -> UserPreferences {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
            return .default
        }
        return preferences
    }

    // MARK: - Interest Migration

    func migrateInterestsIfNeeded() -> Bool {
        guard !UserDefaults.standard.bool(forKey: interestMigrationKey) else {
            return false
        }

        guard let ids = UserDefaults.standard.stringArray(forKey: "selectedInterestIDs") else {
            UserDefaults.standard.set(true, forKey: interestMigrationKey)
            return false
        }

        let migratedIDs = ids.filter { Interest.continuingInterestIDs.contains($0) }
        UserDefaults.standard.set(migratedIDs, forKey: "selectedInterestIDs")
        UserDefaults.standard.set(true, forKey: interestMigrationKey)

        return migratedIDs.count < OnboardingViewModel.minSelection
    }

    func needsInterestReselection() -> Bool {
        guard let ids = UserDefaults.standard.stringArray(forKey: "selectedInterestIDs") else {
            return true
        }
        let validCount = ids.filter { Interest.allInterests.map(\.id).contains($0) }.count
        return validCount < OnboardingViewModel.minSelection
    }
}
