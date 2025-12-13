import Foundation
import CoreLocation

struct LocationInfo: Equatable {
    let coordinate: CLLocationCoordinate2D
    let locality: String?
    let subLocality: String?
    let thoroughfare: String?
    let subThoroughfare: String?

    var formattedAddress: String {
        [locality, subLocality, thoroughfare, subThoroughfare]
            .compactMap { $0 }
            .joined()
    }

    var coordinateString: String {
        String(format: "緯度: %.6f, 経度: %.6f", coordinate.latitude, coordinate.longitude)
    }

    static func == (lhs: LocationInfo, rhs: LocationInfo) -> Bool {
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.locality == rhs.locality &&
        lhs.subLocality == rhs.subLocality &&
        lhs.thoroughfare == rhs.thoroughfare &&
        lhs.subThoroughfare == rhs.subThoroughfare
    }
}
