import Foundation
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Constants

    static let minSelection = 3
    static let maxSelection = 5

    // MARK: - Published State

    @Published private(set) var selectedInterests: Set<Interest> = []

    // MARK: - Computed Properties

    var selectionCount: Int {
        selectedInterests.count
    }

    var isValidSelection: Bool {
        selectionCount >= Self.minSelection && selectionCount <= Self.maxSelection
    }

    var canSelectMore: Bool {
        selectionCount < Self.maxSelection
    }

    var validationMessage: String {
        switch selectionCount {
        case 0:
            return String(
                format: NSLocalizedString("onboarding_select_at_least", comment: ""),
                Self.minSelection
            )
        case 1..<Self.minSelection:
            let remaining = Self.minSelection - selectionCount
            return String(
                format: NSLocalizedString("onboarding_select_more", comment: ""),
                remaining
            )
        case Self.minSelection...Self.maxSelection:
            return String(
                format: NSLocalizedString("onboarding_selected_count", comment: ""),
                selectionCount
            )
        default:
            return String(
                format: NSLocalizedString("onboarding_maximum", comment: ""),
                Self.maxSelection
            )
        }
    }

    // MARK: - Actions

    func toggleInterest(_ interest: Interest) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else if canSelectMore {
            selectedInterests.insert(interest)
        }
    }

    func isSelected(_ interest: Interest) -> Bool {
        selectedInterests.contains(interest)
    }

    // MARK: - Persistence

    func saveSelectedInterests() {
        let ids = selectedInterests.map { $0.id }
        UserDefaults.standard.set(ids, forKey: "selectedInterestIDs")
    }

    func loadSelectedInterests() {
        guard let ids = UserDefaults.standard.stringArray(forKey: "selectedInterestIDs") else {
            return
        }
        selectedInterests = Set(Interest.allInterests.filter { ids.contains($0.id) })
    }

    static func getSelectedInterests() -> Set<Interest> {
        guard let ids = UserDefaults.standard.stringArray(forKey: "selectedInterestIDs") else {
            return []
        }
        return Set(Interest.allInterests.filter { ids.contains($0.id) })
    }
}
