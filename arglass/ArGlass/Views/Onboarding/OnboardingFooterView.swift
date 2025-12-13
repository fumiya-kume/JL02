import SwiftUI

struct OnboardingFooterView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Validation message
            Text(viewModel.validationMessage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(validationColor)
                .animation(.easeInOut(duration: 0.2), value: viewModel.selectionCount)

            HStack(spacing: 14) {
                // Skip button
                Button(action: onSkip) {
                    Text(NSLocalizedString("onboarding_skip", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(minWidth: 140)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        }
                }

                // Continue button
                Button(action: handleContinue) {
                    HStack(spacing: 8) {
                        Text(NSLocalizedString("onboarding_continue", comment: ""))
                            .font(.system(size: 15, weight: .semibold))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(buttonForeground)
                    .frame(minWidth: 140)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 28)
                    .background(buttonBackground, in: Capsule(style: .continuous))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(buttonBorder, lineWidth: 1)
                    }
                }
                .disabled(!viewModel.isValidSelection)
                .neonGlow(
                    color: .accentColor,
                    radius: viewModel.isValidSelection ? 16 : 0,
                    intensity: viewModel.isValidSelection ? 0.25 : 0
                )
                .animation(.easeInOut(duration: 0.25), value: viewModel.isValidSelection)
            }
        }
    }

    private var validationColor: Color {
        viewModel.isValidSelection ? .accentColor.opacity(0.9) : .white.opacity(0.6)
    }

    private var buttonForeground: Color {
        viewModel.isValidSelection ? .white.opacity(0.95) : .white.opacity(0.4)
    }

    private var buttonBackground: some ShapeStyle {
        viewModel.isValidSelection
            ? AnyShapeStyle(Color.accentColor.opacity(0.25))
            : AnyShapeStyle(.ultraThinMaterial)
    }

    private var buttonBorder: Color {
        viewModel.isValidSelection
            ? .accentColor.opacity(0.6)
            : .white.opacity(0.15)
    }

    private func handleContinue() {
        viewModel.saveSelectedInterests()
        onContinue()
    }
}

#Preview {
    ZStack {
        Color.black

        VStack {
            Spacer()
            OnboardingFooterView(
                viewModel: OnboardingViewModel(),
                onContinue: {},
                onSkip: {}
            )
            .padding()
        }
    }
}
