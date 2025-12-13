import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onComplete: () -> Void

    @State private var glitchIntensity: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black

                ScanlinesOverlay()
                    .opacity(0.15)

                GlitchOverlay(intensity: glitchIntensity)

                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, max(geometry.safeAreaInsets.top, 20) + 20)

                    // Bubbles container
                    FloatingBubblesContainer(viewModel: viewModel)
                        .frame(maxHeight: .infinity)
                        .offset(y: -20)

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
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onChange(of: viewModel.selectedInterests.count) { _, _ in
            triggerGlitch()
        }
    }

    private func triggerGlitch() {
        glitchIntensity = 0.6
        withAnimation(.easeOut(duration: 0.4)) {
            glitchIntensity = 0
        }
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
        .padding(.bottom, 8)
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
