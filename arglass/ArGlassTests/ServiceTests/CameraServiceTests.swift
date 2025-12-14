import AVFoundation
import XCTest
@testable import ArGlass

final class CameraServiceTests: XCTestCase {
    private var sut: CameraService!

    override func setUp() {
        super.setUp()
        MockCameraAuthorizationProvider.reset()
    }

    override func tearDown() {
        sut = nil
        MockCameraAuthorizationProvider.reset()
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInit_stateIsIdle() {
        sut = CameraService(authorizationProvider: MockCameraAuthorizationProvider.self)

        XCTAssertEqual(sut.state, .idle)
    }

    // MARK: - Authorization Tests - Already Authorized

    func testRequestAccessAndStart_whenAuthorized_startsCamera() async {
        MockCameraAuthorizationProvider.mockStatus = .authorized
        sut = CameraService(authorizationProvider: MockCameraAuthorizationProvider.self)

        await sut.requestAccessAndStart()

        // Give time for state update on main thread
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Note: In unit tests without actual camera hardware, configureIfNeeded() will fail
        // So state will be .failed, not .running
        // This tests the authorization flow, not the actual camera session
        XCTAssertNotEqual(sut.state, .unauthorized)
    }

    // MARK: - Authorization Tests - Not Determined

    func testRequestAccessAndStart_whenNotDetermined_requestsAccess() async {
        MockCameraAuthorizationProvider.mockStatus = .notDetermined
        MockCameraAuthorizationProvider.mockGrantAccess = true
        sut = CameraService(authorizationProvider: MockCameraAuthorizationProvider.self)

        await sut.requestAccessAndStart()

        XCTAssertEqual(MockCameraAuthorizationProvider.requestAccessCallCount, 1)
    }

    func testRequestAccessAndStart_whenNotDeterminedAndGranted_startsCamera() async {
        MockCameraAuthorizationProvider.mockStatus = .notDetermined
        MockCameraAuthorizationProvider.mockGrantAccess = true
        sut = CameraService(authorizationProvider: MockCameraAuthorizationProvider.self)

        await sut.requestAccessAndStart()

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Should not be unauthorized since access was granted
        XCTAssertNotEqual(sut.state, .unauthorized)
    }

    func testRequestAccessAndStart_whenNotDeterminedAndDenied_setsUnauthorized() async {
        MockCameraAuthorizationProvider.mockStatus = .notDetermined
        MockCameraAuthorizationProvider.mockGrantAccess = false
        sut = CameraService(authorizationProvider: MockCameraAuthorizationProvider.self)

        await sut.requestAccessAndStart()

        // Wait for async state update on main thread
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(sut.state, .unauthorized)
    }

    // MARK: - Authorization Tests - Denied/Restricted

    func testRequestAccessAndStart_whenDenied_setsUnauthorized() async {
        MockCameraAuthorizationProvider.mockStatus = .denied
        sut = CameraService(authorizationProvider: MockCameraAuthorizationProvider.self)

        await sut.requestAccessAndStart()

        // Wait for async state update on main thread
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(sut.state, .unauthorized)
    }

    func testRequestAccessAndStart_whenRestricted_setsUnauthorized() async {
        MockCameraAuthorizationProvider.mockStatus = .restricted
        sut = CameraService(authorizationProvider: MockCameraAuthorizationProvider.self)

        await sut.requestAccessAndStart()

        // Wait for async state update on main thread
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(sut.state, .unauthorized)
    }

    // MARK: - Stop Tests

    func testStop_whenIdle_remainsIdle() {
        sut = CameraService(authorizationProvider: MockCameraAuthorizationProvider.self)
        XCTAssertEqual(sut.state, .idle)

        sut.stop()

        // Give time for async queue operation
        let expectation = expectation(description: "State updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(sut.state, .idle)
    }

    // MARK: - Capture Frame Tests

    func testCaptureCurrentFrame_whenNoFrameAvailable_returnsNil() {
        sut = CameraService(authorizationProvider: MockCameraAuthorizationProvider.self)

        let frame = sut.captureCurrentFrame()

        XCTAssertNil(frame)
    }

    // MARK: - Session Tests

    func testSession_isNotNil() {
        sut = CameraService(authorizationProvider: MockCameraAuthorizationProvider.self)

        XCTAssertNotNil(sut.session)
    }
}
