import Combine
import UIKit

@MainActor
final class BatteryMonitor: ObservableObject {
    @Published private(set) var level: Float?
    @Published private(set) var state: UIDevice.BatteryState = .unknown

    private var cancellables = Set<AnyCancellable>()

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        refresh()

        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
    }

    private func refresh() {
        let currentLevel = UIDevice.current.batteryLevel
        level = currentLevel < 0 ? nil : currentLevel
        state = UIDevice.current.batteryState
    }
}

