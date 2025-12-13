import Foundation

struct Landmark: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    let yearBuilt: String
    let subtitle: String
    let history: String
    let distanceMeters: Double
    let bearingDegrees: Double

    init(
        id: UUID = UUID(),
        name: String,
        yearBuilt: String,
        subtitle: String,
        history: String,
        distanceMeters: Double,
        bearingDegrees: Double
    ) {
        self.id = id
        self.name = name
        self.yearBuilt = yearBuilt
        self.subtitle = subtitle
        self.history = history
        self.distanceMeters = distanceMeters
        self.bearingDegrees = bearingDegrees
    }
}

