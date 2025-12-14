import Foundation

struct Landmark: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    let yearBuilt: String
    let subtitle: String
    let history: String

    init(
        id: UUID = UUID(),
        name: String,
        yearBuilt: String,
        subtitle: String,
        history: String
    ) {
        self.id = id
        self.name = name
        self.yearBuilt = yearBuilt
        self.subtitle = subtitle
        self.history = history
    }
}

