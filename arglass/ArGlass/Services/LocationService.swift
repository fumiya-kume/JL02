import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, ObservableObject, LocationServiceProtocol {
    enum LocationState: Equatable {
        case idle
        case authorized
        case denied
        case updating
        case failed(String)
    }

    @Published private(set) var state: LocationState = .idle
    @Published private(set) var currentLocation: LocationInfo?
    @Published var showDeniedAlert: Bool = false

    private let locationManager: LocationManagerProtocol
    private let geocoder: GeocoderProtocol
    private let userDefaults: UserDefaultsProtocol
    private var lastGeocodedLocation: CLLocation?
    let geocodeDistanceThreshold: CLLocationDistance = 50

    static let deniedAlertShownKey = "LocationService.deniedAlertShown"

    init(
        locationManager: LocationManagerProtocol = CLLocationManager(),
        geocoder: GeocoderProtocol = CLGeocoder(),
        userDefaults: UserDefaultsProtocol = UserDefaults.standard
    ) {
        self.locationManager = locationManager
        self.geocoder = geocoder
        self.userDefaults = userDefaults
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        self.locationManager.distanceFilter = 50
    }

    func requestAuthorization() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            state = .authorized
            startUpdating()
        case .denied, .restricted:
            handleDenied()
        @unknown default:
            state = .failed("Unknown authorization status")
        }
    }

    func startUpdating() {
        guard state == .authorized else { return }
        state = .updating
        locationManager.startUpdatingLocation()
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        if state == .updating {
            state = .authorized
        }
    }

    private func handleDenied() {
        state = .denied
        if !userDefaults.bool(forKey: Self.deniedAlertShownKey) {
            userDefaults.set(true, forKey: Self.deniedAlertShownKey)
            showDeniedAlert = true
        }
    }

    func reverseGeocode(location: CLLocation) {
        if let last = lastGeocodedLocation,
           location.distance(from: last) < geocodeDistanceThreshold {
            return
        }

        lastGeocodedLocation = location

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor in
                guard let self = self else { return }

                if let error = error {
                    print("[Location] Geocoding failed: \(error.localizedDescription)")
                    self.updateLocation(coordinate: location.coordinate, placemark: nil)
                    return
                }

                self.updateLocation(
                    coordinate: location.coordinate,
                    placemark: placemarks?.first
                )
            }
        }
    }

    func handleAuthorizationChange(status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            state = .authorized
            startUpdating()
        case .denied, .restricted:
            handleDenied()
        case .notDetermined:
            state = .idle
        @unknown default:
            state = .failed("Unknown status")
        }
    }

    func handleLocationError(_ error: Error) {
        state = .failed(error.localizedDescription)
        print("[Location] Error: \(error.localizedDescription)")
    }

    func resetLastGeocodedLocation() {
        lastGeocodedLocation = nil
    }

    private func updateLocation(coordinate: CLLocationCoordinate2D, placemark: CLPlacemark?) {
        currentLocation = LocationInfo(
            coordinate: coordinate,
            locality: placemark?.locality,
            subLocality: placemark?.subLocality,
            thoroughfare: placemark?.thoroughfare,
            subThoroughfare: placemark?.subThoroughfare
        )
        print("[Location] Updated: \(currentLocation?.coordinateString ?? "nil"), address: \(currentLocation?.formattedAddress ?? "nil")")
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            reverseGeocode(location: location)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            handleAuthorizationChange(status: manager.authorizationStatus)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            handleLocationError(error)
        }
    }
}
