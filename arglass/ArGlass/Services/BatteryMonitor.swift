import Combine
import UIKit

@MainActor
final class BatteryMonitor: ObservableObject {
    @Published private(set) var level: Float?
    @Published private(set) var state: UIDevice.BatteryState = .unknown

    private var cancellables = Set<AnyCancellable>()
    private let device: BatteryProviding
    private let notificationCenter: NotificationCenter

    init(
        device: BatteryProviding = UIDevice.current,
        notificationCenter: NotificationCenter = .default
    ) {
        self.device = device
        self.notificationCenter = notificationCenter

        if let uiDevice = device as? UIDevice {
            uiDevice.isBatteryMonitoringEnabled = true
        }

        refresh()

        notificationCenter.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .merge(with: notificationCenter.publisher(for: UIDevice.batteryStateDidChangeNotification))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
    }

    private func refresh() {
        let currentLevel = device.batteryLevel
        level = currentLevel < 0 ? nil : currentLevel
        state = device.batteryState
    }
}
