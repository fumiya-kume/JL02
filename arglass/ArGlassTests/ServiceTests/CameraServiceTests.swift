import AVFoundation
import Combine
import XCTest
@testable import ArGlass

final class CameraServiceTests: XCTestCase {
    private var sut: CameraService!
    private var mockAuthProvider: MockCameraAuthorizationProvider!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockAuthProvider = MockCameraAuthorizationProvider()
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        mockAuthProvider = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInit_stateIsIdle() {
        sut = CameraService(authorizationProvider: mockAuthProvider)

        XCTAssertEqual(sut.state, .idle)
    }

    // MARK: - Authorization Tests - Already Authorized

    func testRequestAccessAndStart_whenAuthorized_doesNotSetUnauthorized() async {
        mockAuthProvider.mockStatus = .authorized
        sut = CameraService(authorizationProvider: mockAuthProvider)

        // Set up expectation BEFORE calling requestAccessAndStart
        let expectation = expectation(description: "State updated")
        sut.$state
            .dropFirst()
            .first { $0 != .idle }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        await sut.requestAccessAndStart()

        await fulfillment(of: [expectation], timeout: 2.0)

        // Note: In unit tests without actual camera hardware, configureIfNeeded() will fail
        // So state will be .failed, not .running
        // This tests the authorization flow, not the actual camera session
        XCTAssertNotEqual(sut.state, .unauthorized)
    }

    // MARK: - Authorization Tests - Not Determined

    func testRequestAccessAndStart_whenNotDetermined_requestsAccess() async {
        mockAuthProvider.mockStatus = .notDetermined
        mockAuthProvider.mockGrantAccess = true
        sut = CameraService(authorizationProvider: mockAuthProvider)

        await sut.requestAccessAndStart()

        XCTAssertEqual(mockAuthProvider.requestAccessCallCount, 1)
    }

    func testRequestAccessAndStart_whenNotDeterminedAndGranted_doesNotSetUnauthorized() async {
        mockAuthProvider.mockStatus = .notDetermined
        mockAuthProvider.mockGrantAccess = true
        sut = CameraService(authorizationProvider: mockAuthProvider)

        // Set up expectation BEFORE calling requestAccessAndStart
        let expectation = expectation(description: "State updated")
        sut.$state
            .dropFirst()
            .first { $0 != .idle }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        await sut.requestAccessAndStart()

        await fulfillment(of: [expectation], timeout: 2.0)

        // Should not be unauthorized since access was granted
        XCTAssertNotEqual(sut.state, .unauthorized)
    }

    func testRequestAccessAndStart_whenNotDeterminedAndDenied_setsUnauthorized() async {
        mockAuthProvider.mockStatus = .notDetermined
        mockAuthProvider.mockGrantAccess = false
        sut = CameraService(authorizationProvider: mockAuthProvider)

        let expectation = expectation(description: "State updated to unauthorized")
        sut.$state
            .dropFirst()
            .first { $0 == .unauthorized }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        await sut.requestAccessAndStart()

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(sut.state, .unauthorized)
    }

    // MARK: - Authorization Tests - Denied/Restricted

    func testRequestAccessAndStart_whenDenied_setsUnauthorized() async {
        mockAuthProvider.mockStatus = .denied
        sut = CameraService(authorizationProvider: mockAuthProvider)

        let expectation = expectation(description: "State updated to unauthorized")
        sut.$state
            .dropFirst()
            .first { $0 == .unauthorized }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        await sut.requestAccessAndStart()

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(sut.state, .unauthorized)
    }

    func testRequestAccessAndStart_whenRestricted_setsUnauthorized() async {
        mockAuthProvider.mockStatus = .restricted
        sut = CameraService(authorizationProvider: mockAuthProvider)

        let expectation = expectation(description: "State updated to unauthorized")
        sut.$state
            .dropFirst()
            .first { $0 == .unauthorized }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        await sut.requestAccessAndStart()

        await fulfillment(of: [expectation], timeout: 1.0)

        XCTAssertEqual(sut.state, .unauthorized)
    }

    // MARK: - Stop Tests

    func testStop_whenIdle_remainsIdle() {
        sut = CameraService(authorizationProvider: mockAuthProvider)
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
        sut = CameraService(authorizationProvider: mockAuthProvider)

        let frame = sut.captureCurrentFrame()

        XCTAssertNil(frame)
    }

    // MARK: - Session Tests

    func testSession_isNotNil() {
        sut = CameraService(authorizationProvider: mockAuthProvider)

        XCTAssertNotNil(sut.session)
    }
}
