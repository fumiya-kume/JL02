import SwiftUI

struct FloatingBubblesContainer: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var rotation: Double = 0
    @State private var lastDragValue: CGFloat = 0

    private let radiusX: CGFloat = 260  // Horizontal radius (wider for landscape)
    private let radiusY: CGFloat = 50   // Vertical radius (very flat for landscape to avoid overlap)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(Interest.allInterests.enumerated()), id: \.element.id) { index, interest in
                    let angle = angleForIndex(index, total: Interest.allInterests.count) + rotation
                    let position = positionOnEllipse(angle: angle, radiusX: radiusX, radiusY: radiusY, center: geometry.size)
                    let depth = depthForAngle(angle)
                    let scale = scaleForDepth(depth)
                    let opacity = opacityForDepth(depth)

                    InterestBubbleView(
                        interest: interest,
                        isSelected: viewModel.isSelected(interest),
                        canSelect: viewModel.canSelectMore || viewModel.isSelected(interest),
                        onTap: { viewModel.toggleInterest(interest) }
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .zIndex(depth)
                    .position(position)
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let delta = value.translation.width - lastDragValue
                        rotation -= delta * 0.3  // Reversed: right drag = clockwise rotation
                        lastDragValue = value.translation.width
                    }
                    .onEnded { _ in
                        lastDragValue = 0
                    }
            )
        }
    }

    private func depthForAngle(_ angle: Double) -> Double {
        // Normalize angle to 0-360
        let normalizedAngle = angle.truncatingRemainder(dividingBy: 360)
        let adjustedAngle = normalizedAngle < 0 ? normalizedAngle + 360 : normalizedAngle

        // Front (90 degrees - top) = 1.0, Back (270 degrees - bottom) = 0.0
        let radians = adjustedAngle * .pi / 180
        return (sin(radians) + 1.0) / 2.0
    }

    private func scaleForDepth(_ depth: Double) -> CGFloat {
        // Scale from 0.6 (back) to 1.0 (front)
        return 0.6 + (0.4 * depth)
    }

    private func opacityForDepth(_ depth: Double) -> Double {
        // Opacity from 0.4 (back) to 1.0 (front)
        return 0.4 + (0.6 * depth)
    }

    private func angleForIndex(_ index: Int, total: Int) -> Double {
        let angleStep = 360.0 / Double(total)
        return Double(index) * angleStep // Start from right (0 degrees)
    }

    private func positionOnEllipse(angle: Double, radiusX: CGFloat, radiusY: CGFloat, center: CGSize) -> CGPoint {
        let radians = angle * .pi / 180
        let x = center.width / 2 + radiusX * cos(radians)
        let y = center.height / 2 + radiusY * sin(radians)
        return CGPoint(x: x, y: y)
    }
}

#Preview {
    ZStack {
        Color.black

        FloatingBubblesContainer(viewModel: OnboardingViewModel())
    }
}
