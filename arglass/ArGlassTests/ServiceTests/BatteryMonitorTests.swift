import Combine
import XCTest
@testable import ArGlass

@MainActor
final class BatteryMonitorTests: XCTestCase {
    private var sut: BatteryMonitor!
    private var mockBatteryProvider: MockBatteryProvider!
    private var notificationCenter: NotificationCenter!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        mockBatteryProvider = MockBatteryProvider()
        notificationCenter = NotificationCenter()
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        mockBatteryProvider = nil
        notificationCenter = nil
        cancellables = nil
    }

    // MARK: - Initial State Tests

    func testInit_setsInitialLevelFromDevice() {
        mockBatteryProvider.batteryLevel = 0.75

        sut = BatteryMonitor(device: mockBatteryProvider, notificationCenter: notificationCenter)

        XCTAssertEqual(sut.level, 0.75)
    }

    func testInit_whenNegativeLevel_setsNil() {
        mockBatteryProvider.batteryLevel = -1.0

        sut = BatteryMonitor(device: mockBatteryProvider, notificationCenter: notificationCenter)

        XCTAssertNil(sut.level)
    }

    func testInit_setsInitialState() {
        mockBatteryProvider.batteryState = .charging

        sut = BatteryMonitor(device: mockBatteryProvider, notificationCenter: notificationCenter)

        XCTAssertEqual(sut.state, .charging)
    }

    func testInit_whenUnpluggedState_setsUnplugged() {
        mockBatteryProvider.batteryState = .unplugged

        sut = BatteryMonitor(device: mockBatteryProvider, notificationCenter: notificationCenter)

        XCTAssertEqual(sut.state, .unplugged)
    }

    func testInit_whenFullState_setsFull() {
        mockBatteryProvider.batteryState = .full

        sut = BatteryMonitor(device: mockBatteryProvider, notificationCenter: notificationCenter)

        XCTAssertEqual(sut.state, .full)
    }

    // MARK: - Notification Tests

    func testBatteryLevelChange_notification_updatesLevel() {
        mockBatteryProvider.batteryLevel = 0.5
        sut = BatteryMonitor(device: mockBatteryProvider, notificationCenter: notificationCenter)
        XCTAssertEqual(sut.level, 0.5)

        let expectation = expectation(description: "Level updated to 0.8")

        sut.$level
            .dropFirst()
            .first { $0 == 0.8 }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        mockBatteryProvider.batteryLevel = 0.8
        notificationCenter.post(name: UIDevice.batteryLevelDidChangeNotification, object: nil)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.level, 0.8)
    }

    func testBatteryStateChange_notification_updatesState() {
        mockBatteryProvider.batteryState = .unplugged
        sut = BatteryMonitor(device: mockBatteryProvider, notificationCenter: notificationCenter)
        XCTAssertEqual(sut.state, .unplugged)

        let expectation = expectation(description: "State updated to charging")

        sut.$state
            .dropFirst()
            .first { $0 == .charging }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        mockBatteryProvider.batteryState = .charging
        notificationCenter.post(name: UIDevice.batteryStateDidChangeNotification, object: nil)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.state, .charging)
    }

    // MARK: - Edge Cases

    func testLevel_whenUnknown_returnsNil() {
        mockBatteryProvider.batteryLevel = -1.0
        mockBatteryProvider.batteryState = .unknown

        sut = BatteryMonitor(device: mockBatteryProvider, notificationCenter: notificationCenter)

        XCTAssertNil(sut.level)
        XCTAssertEqual(sut.state, .unknown)
    }

    func testLevel_normalizesValidValues() {
        mockBatteryProvider.batteryLevel = 0.0
        sut = BatteryMonitor(device: mockBatteryProvider, notificationCenter: notificationCenter)
        XCTAssertEqual(sut.level, 0.0)

        let expectation = expectation(description: "Level updated to 1.0")

        sut.$level
            .dropFirst()
            .first { $0 == 1.0 }
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        mockBatteryProvider.batteryLevel = 1.0
        notificationCenter.post(name: UIDevice.batteryLevelDidChangeNotification, object: nil)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.level, 1.0)
    }

    func testLevel_handlesZeroLevel() {
        mockBatteryProvider.batteryLevel = 0.0

        sut = BatteryMonitor(device: mockBatteryProvider, notificationCenter: notificationCenter)

        XCTAssertEqual(sut.level, 0.0)
    }

    func testLevel_handlesFullLevel() {
        mockBatteryProvider.batteryLevel = 1.0

        sut = BatteryMonitor(device: mockBatteryProvider, notificationCenter: notificationCenter)

        XCTAssertEqual(sut.level, 1.0)
    }
}
