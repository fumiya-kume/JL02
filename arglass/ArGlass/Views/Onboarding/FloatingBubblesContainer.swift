import SwiftUI

struct FloatingBubblesContainer: View {
    @ObservedObject var viewModel: OnboardingViewModel

    // Grid layout: 2 rows x 5 columns for 10 interests
    private let columns = 5
    private let rows = 2
    private let horizontalPadding: CGFloat = 30
    private let verticalPadding: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - (horizontalPadding * 2)
            let availableHeight = geometry.size.height - (verticalPadding * 2)
            let cellWidth = availableWidth / CGFloat(columns)
            let cellHeight = availableHeight / CGFloat(rows)

            ZStack {
                ForEach(Array(Interest.allInterests.enumerated()), id: \.element.id) { index, interest in
                    let row = index / columns
                    let col = index % columns

                    // Center position for each cell with padding offset
                    let centerX = horizontalPadding + cellWidth * (CGFloat(col) + 0.5)
                    let centerY = verticalPadding + cellHeight * (CGFloat(row) + 0.5)

                    InterestBubbleView(
                        interest: interest,
                        isSelected: viewModel.isSelected(interest),
                        canSelect: viewModel.canSelectMore || viewModel.isSelected(interest),
                        onTap: { viewModel.toggleInterest(interest) }
                    )
                    .position(x: centerX, y: centerY)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black

        FloatingBubblesContainer(viewModel: OnboardingViewModel())
    }
}
