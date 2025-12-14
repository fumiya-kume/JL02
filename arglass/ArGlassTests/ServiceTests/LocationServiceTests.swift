import CoreLocation
import XCTest
@testable import ArGlass

@MainActor
final class LocationServiceTests: XCTestCase {
    private var sut: LocationService!
    private var mockLocationManager: MockLocationManager!
    private var mockGeocoder: MockGeocoder!
    private var mockUserDefaults: MockUserDefaults!

    override func setUp() async throws {
        mockLocationManager = MockLocationManager()
        mockGeocoder = MockGeocoder()
        mockUserDefaults = MockUserDefaults()
        sut = LocationService(
            locationManager: mockLocationManager,
            geocoder: mockGeocoder,
            userDefaults: mockUserDefaults
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockLocationManager = nil
        mockGeocoder = nil
        mockUserDefaults = nil
    }

    // MARK: - Initial State Tests

    func testInit_stateIsIdle() {
        XCTAssertEqual(sut.state, .idle)
    }

    func testInit_currentLocationIsNil() {
        XCTAssertNil(sut.currentLocation)
    }

    func testInit_showDeniedAlertIsFalse() {
        XCTAssertFalse(sut.showDeniedAlert)
    }

    func testInit_configuresLocationManager() {
        XCTAssertEqual(mockLocationManager.desiredAccuracy, kCLLocationAccuracyHundredMeters)
        XCTAssertEqual(mockLocationManager.distanceFilter, 50)
        XCTAssertNotNil(mockLocationManager.delegate)
    }

    // MARK: - Request Authorization Tests

    func testRequestAuthorization_whenNotDetermined_requestsAuthorization() {
        mockLocationManager.authorizationStatus = .notDetermined

        sut.requestAuthorization()

        XCTAssertEqual(mockLocationManager.requestAuthorizationCallCount, 1)
    }

    func testRequestAuthorization_whenAuthorizedWhenInUse_setsAuthorizedState() {
        mockLocationManager.authorizationStatus = .authorizedWhenInUse

        sut.requestAuthorization()

        XCTAssertEqual(sut.state, .updating)
    }

    func testRequestAuthorization_whenAuthorizedAlways_setsAuthorizedState() {
        mockLocationManager.authorizationStatus = .authorizedAlways

        sut.requestAuthorization()

        XCTAssertEqual(sut.state, .updating)
    }

    func testRequestAuthorization_whenAuthorized_startsUpdating() {
        mockLocationManager.authorizationStatus = .authorizedWhenInUse

        sut.requestAuthorization()

        XCTAssertEqual(mockLocationManager.startUpdatingCallCount, 1)
    }

    func testRequestAuthorization_whenDenied_setsDeniedState() {
        mockLocationManager.authorizationStatus = .denied

        sut.requestAuthorization()

        XCTAssertEqual(sut.state, .denied)
    }

    func testRequestAuthorization_whenRestricted_setsDeniedState() {
        mockLocationManager.authorizationStatus = .restricted

        sut.requestAuthorization()

        XCTAssertEqual(sut.state, .denied)
    }

    // MARK: - Denied Alert Tests

    func testRequestAuthorization_whenDeniedFirstTime_showsAlert() {
        mockLocationManager.authorizationStatus = .denied

        sut.requestAuthorization()

        XCTAssertTrue(sut.showDeniedAlert)
    }

    func testRequestAuthorization_whenDeniedSecondTime_doesNotShowAlert() {
        mockUserDefaults.set(true, forKey: LocationService.deniedAlertShownKey)
        mockLocationManager.authorizationStatus = .denied

        sut.requestAuthorization()

        XCTAssertFalse(sut.showDeniedAlert)
    }

    func testRequestAuthorization_whenDenied_savesAlertShownFlag() {
        mockLocationManager.authorizationStatus = .denied

        sut.requestAuthorization()

        XCTAssertTrue(mockUserDefaults.bool(forKey: LocationService.deniedAlertShownKey))
    }

    // MARK: - Start Updating Tests

    func testStartUpdating_whenAuthorized_setsUpdatingState() {
        sut.handleAuthorizationChange(status: .authorizedWhenInUse)
        mockLocationManager.startUpdatingCallCount = 0

        sut.startUpdating()

        XCTAssertEqual(sut.state, .updating)
    }

    func testStartUpdating_whenAuthorized_startsLocationManager() {
        // Set up authorized state, then stop updating to go back to .authorized
        sut.handleAuthorizationChange(status: .authorizedWhenInUse)
        sut.stopUpdating()
        XCTAssertEqual(sut.state, .authorized)
        mockLocationManager.startUpdatingCallCount = 0

        sut.startUpdating()

        XCTAssertEqual(mockLocationManager.startUpdatingCallCount, 1)
    }

    func testStartUpdating_whenNotAuthorized_doesNothing() {
        XCTAssertEqual(sut.state, .idle)

        sut.startUpdating()

        XCTAssertEqual(sut.state, .idle)
        XCTAssertEqual(mockLocationManager.startUpdatingCallCount, 0)
    }

    // MARK: - Stop Updating Tests

    func testStopUpdating_stopsLocationManager() {
        sut.handleAuthorizationChange(status: .authorizedWhenInUse)

        sut.stopUpdating()

        XCTAssertEqual(mockLocationManager.stopUpdatingCallCount, 1)
    }

    func testStopUpdating_whenUpdating_setsAuthorizedState() {
        sut.handleAuthorizationChange(status: .authorizedWhenInUse)
        XCTAssertEqual(sut.state, .updating)

        sut.stopUpdating()

        XCTAssertEqual(sut.state, .authorized)
    }

    func testStopUpdating_whenNotUpdating_keepsCurrentState() {
        XCTAssertEqual(sut.state, .idle)

        sut.stopUpdating()

        XCTAssertEqual(sut.state, .idle)
    }

    // MARK: - Handle Authorization Change Tests

    func testHandleAuthorizationChange_authorizedWhenInUse_setsAuthorizedAndStartsUpdating() {
        sut.handleAuthorizationChange(status: .authorizedWhenInUse)

        XCTAssertEqual(sut.state, .updating)
        XCTAssertEqual(mockLocationManager.startUpdatingCallCount, 1)
    }

    func testHandleAuthorizationChange_authorizedAlways_setsAuthorizedAndStartsUpdating() {
        sut.handleAuthorizationChange(status: .authorizedAlways)

        XCTAssertEqual(sut.state, .updating)
        XCTAssertEqual(mockLocationManager.startUpdatingCallCount, 1)
    }

    func testHandleAuthorizationChange_denied_setsDenied() {
        sut.handleAuthorizationChange(status: .denied)

        XCTAssertEqual(sut.state, .denied)
    }

    func testHandleAuthorizationChange_restricted_setsDenied() {
        sut.handleAuthorizationChange(status: .restricted)

        XCTAssertEqual(sut.state, .denied)
    }

    func testHandleAuthorizationChange_notDetermined_setsIdle() {
        sut.handleAuthorizationChange(status: .notDetermined)

        XCTAssertEqual(sut.state, .idle)
    }

    // MARK: - Handle Location Error Tests

    func testHandleLocationError_setsFailedState() {
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])

        sut.handleLocationError(error)

        XCTAssertEqual(sut.state, .failed("Test error"))
    }

    // MARK: - Reverse Geocode Tests

    func testReverseGeocode_callsGeocoder() async {
        let location = CLLocation(latitude: 35.6762, longitude: 139.6503)

        sut.reverseGeocode(location: location)

        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockGeocoder.reverseGeocodeCallCount, 1)
        XCTAssertEqual(mockGeocoder.lastGeocodedLocation?.coordinate.latitude, 35.6762)
        XCTAssertEqual(mockGeocoder.lastGeocodedLocation?.coordinate.longitude, 139.6503)
    }

    func testReverseGeocode_withinThreshold_skipsGeocode() async {
        let location1 = CLLocation(latitude: 35.6762, longitude: 139.6503)
        let location2 = CLLocation(latitude: 35.6762, longitude: 139.6503) // Same location

        sut.reverseGeocode(location: location1)
        try? await Task.sleep(nanoseconds: 100_000_000)
        sut.reverseGeocode(location: location2)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockGeocoder.reverseGeocodeCallCount, 1)
    }

    func testReverseGeocode_beyondThreshold_callsGeocode() async {
        let location1 = CLLocation(latitude: 35.6762, longitude: 139.6503)
        // Location about 100m away (beyond 50m threshold)
        let location2 = CLLocation(latitude: 35.6772, longitude: 139.6513)

        sut.reverseGeocode(location: location1)
        try? await Task.sleep(nanoseconds: 100_000_000)
        sut.reverseGeocode(location: location2)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockGeocoder.reverseGeocodeCallCount, 2)
    }

    func testReverseGeocode_success_updatesCurrentLocation() async {
        let location = CLLocation(latitude: 35.6762, longitude: 139.6503)

        sut.reverseGeocode(location: location)

        // Wait for async completion handler
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNotNil(sut.currentLocation)
        XCTAssertEqual(sut.currentLocation?.coordinate.latitude, 35.6762)
        XCTAssertEqual(sut.currentLocation?.coordinate.longitude, 139.6503)
    }

    func testReverseGeocode_error_updatesLocationWithCoordinatesOnly() async {
        let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
        mockGeocoder.mockError = NSError(domain: "test", code: 1, userInfo: nil)

        sut.reverseGeocode(location: location)

        // Wait for async completion handler
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertNotNil(sut.currentLocation)
        XCTAssertEqual(sut.currentLocation?.coordinate.latitude, 35.6762)
        XCTAssertNil(sut.currentLocation?.locality)
    }

    // MARK: - Reset Tests

    func testResetLastGeocodedLocation_allowsNewGeocode() async {
        let location = CLLocation(latitude: 35.6762, longitude: 139.6503)

        sut.reverseGeocode(location: location)
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(mockGeocoder.reverseGeocodeCallCount, 1)

        sut.resetLastGeocodedLocation()
        sut.reverseGeocode(location: location)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockGeocoder.reverseGeocodeCallCount, 2)
    }

    // MARK: - Geocode Distance Threshold Tests

    func testGeocodeDistanceThreshold_isCorrect() {
        XCTAssertEqual(sut.geocodeDistanceThreshold, 50)
    }
}
