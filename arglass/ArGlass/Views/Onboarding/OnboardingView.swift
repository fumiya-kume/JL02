import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onComplete: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black

                ScanlinesOverlay()
                    .opacity(0.15)

                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, max(geometry.safeAreaInsets.top, 20) + 40)

                    // Bubbles container
                    FloatingBubblesContainer(viewModel: viewModel)
                        .padding(.horizontal, 20)

                    // Footer
                    OnboardingFooterView(
                        viewModel: viewModel,
                        onContinue: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                onComplete()
                            }
                        },
                        onSkip: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                onComplete()
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 28))
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
    }

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text(NSLocalizedString("onboarding_title", comment: ""))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))

            Text(NSLocalizedString("onboarding_subtitle", comment: ""))
                .font(.system(size: 8))
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 14)
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
