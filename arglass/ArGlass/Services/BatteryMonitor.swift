import Foundation
import UIKit

@MainActor
final class BatteryMonitor: ObservableObject {
    @Published private(set) var level: Float?
    @Published private(set) var state: UIDevice.BatteryState = .unknown

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        refresh()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refresh),
            name: UIDevice.batteryStateDidChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func refresh() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let currentLevel = UIDevice.current.batteryLevel
            self.level = currentLevel < 0 ? nil : currentLevel
            self.state = UIDevice.current.batteryState
        }
    }
}

