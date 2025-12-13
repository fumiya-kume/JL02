import XCTest
import CoreLocation
@testable import ArGlass

final class LocationInfoTests: XCTestCase {
    
    func testFormattedAddress() {
        // All fields present
        let location1 = LocationInfo(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            locality: "Tokyo",
            subLocality: "Shibuya",
            thoroughfare: "Jingumae",
            subThoroughfare: "2-1-1"
        )
        XCTAssertEqual(location1.formattedAddress, "TokyoShibuyaJingumae2-1-1")
        
        // Some fields nil
        let location2 = LocationInfo(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            locality: "Tokyo",
            subLocality: nil,
            thoroughfare: "Jingumae",
            subThoroughfare: nil
        )
        XCTAssertEqual(location2.formattedAddress, "TokyoJingumae")
        
        // All fields nil
        let location3 = LocationInfo(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            locality: nil,
            subLocality: nil,
            thoroughfare: nil,
            subThoroughfare: nil
        )
        XCTAssertEqual(location3.formattedAddress, "")
    }
    
    func testCoordinateString() {
        let location = LocationInfo(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            locality: nil,
            subLocality: nil,
            thoroughfare: nil,
            subThoroughfare: nil
        )
        XCTAssertEqual(location.coordinateString, "緯度: 35.676200, 経度: 139.650300")
    }
    
    func testEquality() {
        let location1 = LocationInfo(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            locality: "Tokyo",
            subLocality: "Shibuya",
            thoroughfare: "Jingumae",
            subThoroughfare: "2-1-1"
        )
        
        let location2 = LocationInfo(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            locality: "Tokyo",
            subLocality: "Shibuya",
            thoroughfare: "Jingumae",
            subThoroughfare: "2-1-1"
        )
        
        let location3 = LocationInfo(
            coordinate: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            locality: "Tokyo",
            subLocality: "Shinjuku", // Different
            thoroughfare: "Jingumae",
            subThoroughfare: "2-1-1"
        )
        
        let location4 = LocationInfo(
            coordinate: CLLocationCoordinate2D(latitude: 35.6763, longitude: 139.6503), // Different coordinate
            locality: "Tokyo",
            subLocality: "Shibuya",
            thoroughfare: "Jingumae",
            subThoroughfare: "2-1-1"
        )
        
        XCTAssertEqual(location1, location2, "Locations with same data should be equal")
        XCTAssertNotEqual(location1, location3, "Locations with different subLocality should not be equal")
        XCTAssertNotEqual(location1, location4, "Locations with different coordinates should not be equal")
    }
}
