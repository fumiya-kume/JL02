import SwiftUI

struct FloatingBubblesContainer: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var rotation: Double = 0
    @State private var lastDragValue: CGFloat = 0

    private let radiusX: CGFloat = 260  // Max horizontal radius (designed for landscape)
    private let radiusY: CGFloat = 50   // Max vertical radius (flat to avoid overlap)

    var body: some View {
        GeometryReader { geometry in
            // Keep interactive bubbles inside safe area to avoid the notch / Dynamic Island cutout in landscape.
            let safeRect = geometry.safeAreaInsets.safeRect(in: geometry.size)
            let center = CGPoint(x: safeRect.midX, y: safeRect.midY)
            let bubbleHalfWidth: CGFloat = 55
            let bubbleHalfHeight: CGFloat = 80
            let horizontalMargin: CGFloat = 12
            let verticalMargin: CGFloat = 12
            let maxRadiusX = max(0, safeRect.width / 2 - bubbleHalfWidth - horizontalMargin)
            let maxRadiusY = max(0, safeRect.height / 2 - bubbleHalfHeight - verticalMargin)
            let effectiveRadiusX = min(radiusX, maxRadiusX)
            let effectiveRadiusY = min(radiusY, maxRadiusY)

            ZStack {
                ForEach(Array(Interest.allInterests.enumerated()), id: \.element.id) { index, interest in
                    let angle = angleForIndex(index, total: Interest.allInterests.count) + rotation
                    let position = positionOnEllipse(
                        angle: angle,
                        radiusX: effectiveRadiusX,
                        radiusY: effectiveRadiusY,
                        center: center
                    )
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

    private func positionOnEllipse(angle: Double, radiusX: CGFloat, radiusY: CGFloat, center: CGPoint) -> CGPoint {
        let radians = angle * .pi / 180
        let x = center.x + radiusX * cos(radians)
        let y = center.y + radiusY * sin(radians)
        return CGPoint(x: x, y: y)
    }
}

#Preview {
    ZStack {
        Color.black

        FloatingBubblesContainer(viewModel: OnboardingViewModel())
    }
}
