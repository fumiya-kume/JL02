import SwiftUI

struct FloatingBubblesContainer: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Interest.allInterests, id: \.id) { interest in
                    InterestBubbleView(
                        interest: interest,
                        isSelected: viewModel.isSelected(interest),
                        canSelect: viewModel.canSelectMore || viewModel.isSelected(interest),
                        onTap: { viewModel.toggleInterest(interest) }
                    )
                }
            }
            .frame(maxWidth: 500)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ZStack {
        Color.black

        FloatingBubblesContainer(viewModel: OnboardingViewModel())
    }
}
