import Foundation

struct Interest: Identifiable, Equatable, Hashable, Codable {
    let id: String
    let nameKey: String
    let icon: String

    var localizedName: String {
        NSLocalizedString(nameKey, comment: "Interest category name")
    }

    static let allInterests: [Interest] = [
        Interest(id: "history", nameKey: "interest_history", icon: "building.columns"),
        Interest(id: "nature", nameKey: "interest_nature", icon: "leaf"),
        Interest(id: "art", nameKey: "interest_art", icon: "paintpalette"),
        Interest(id: "food", nameKey: "interest_food", icon: "fork.knife"),
        Interest(id: "architecture", nameKey: "interest_architecture", icon: "building.2"),
        Interest(id: "shopping", nameKey: "interest_shopping", icon: "bag"),
        Interest(id: "nightlife", nameKey: "interest_nightlife", icon: "moon.stars")
    ]

    static let continuingInterestIDs: Set<String> = ["history", "nature", "art", "food"]
}
