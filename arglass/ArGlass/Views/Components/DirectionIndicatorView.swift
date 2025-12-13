import SwiftUI

struct DirectionIndicatorView: View {
    let distanceMeters: Double
    let bearingDegrees: Double

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "location.north.fill")
                .font(.system(size: 12, weight: .semibold))
                .rotationEffect(.degrees(bearingDegrees))

            Text("\(formattedDistance(distanceMeters)) • \(compassLabel(for: bearingDegrees))")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(.black.opacity(0.22), in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }

    private func formattedDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1fkm", meters / 1000.0)
        }
        return "\(Int(meters.rounded()))m"
    }

    private func compassLabel(for degrees: Double) -> String {
        let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        switch normalized {
        case 337.5...360, 0..<22.5: return NSLocalizedString("compass_n", comment: "")
        case 22.5..<67.5: return NSLocalizedString("compass_ne", comment: "")
        case 67.5..<112.5: return NSLocalizedString("compass_e", comment: "")
        case 112.5..<157.5: return NSLocalizedString("compass_se", comment: "")
        case 157.5..<202.5: return NSLocalizedString("compass_s", comment: "")
        case 202.5..<247.5: return NSLocalizedString("compass_sw", comment: "")
        case 247.5..<292.5: return NSLocalizedString("compass_w", comment: "")
        default: return NSLocalizedString("compass_nw", comment: "")
        }
    }
}

#Preview {
    DirectionIndicatorView(distanceMeters: 420, bearingDegrees: 35)
        .padding()
        .background(Color.black)
}

