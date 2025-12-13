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
        Interest(id: "finance", nameKey: "interest_finance", icon: "chart.line.uptrend.xyaxis"),
        Interest(id: "technology", nameKey: "interest_technology", icon: "cpu"),
        Interest(id: "science", nameKey: "interest_science", icon: "atom"),
        Interest(id: "art", nameKey: "interest_art", icon: "paintpalette"),
        Interest(id: "sports", nameKey: "interest_sports", icon: "sportscourt"),
        Interest(id: "music", nameKey: "interest_music", icon: "music.note"),
        Interest(id: "travel", nameKey: "interest_travel", icon: "airplane"),
        Interest(id: "food", nameKey: "interest_food", icon: "fork.knife"),
        Interest(id: "nature", nameKey: "interest_nature", icon: "leaf")
    ]
}
