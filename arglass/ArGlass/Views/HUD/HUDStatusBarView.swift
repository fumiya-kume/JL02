import SwiftUI

struct HUDStatusBarView: View {
    let isConnected: Bool

    @StateObject private var battery = BatteryMonitor()

    var body: some View {
        HStack(spacing: 10) {
            connectionView
            batteryView
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.70),
                            Color.accentColor.opacity(0.28),
                            Color.accentColor.opacity(0.14)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        }
        .neonGlow(color: .accentColor, radius: 10, intensity: 0.18)
    }

    private var connectionView: some View {
        HStack(spacing: 6) {
            Image(systemName: isConnected ? "wifi" : "wifi.slash")
                .font(.system(size: 12, weight: .semibold))
            Text(isConnected ? "ONLINE" : "OFFLINE")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
        }
        .foregroundStyle(Color.accentColor.opacity(isConnected ? 0.90 : 0.55))
    }

    private var batteryView: some View {
        HStack(spacing: 6) {
            Image(systemName: batterySymbolName(level: battery.level, state: battery.state))
                .font(.system(size: 12, weight: .semibold))
            Text(batteryText(level: battery.level, state: battery.state))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
        }
        .foregroundStyle(.white.opacity(0.85))
    }

    private func batteryText(level: Float?, state: UIDevice.BatteryState) -> String {
        guard let level else { return "--%" }
        let percent = Int((level * 100).rounded())
        let suffix = state == .charging || state == .full ? "+" : ""
        return "\(percent)%\(suffix)"
    }

    private func batterySymbolName(level: Float?, state: UIDevice.BatteryState) -> String {
        if state == .charging {
            return "battery.100.bolt"
        }
        guard let level else { return "battery.0" }

        switch level {
        case 0.85...: return "battery.100"
        case 0.60..<0.85: return "battery.75"
        case 0.35..<0.60: return "battery.50"
        case 0.10..<0.35: return "battery.25"
        default: return "battery.0"
        }
    }
}

#Preview {
    HUDStatusBarView(isConnected: true)
        .padding()
        .background(Color.black)
}
