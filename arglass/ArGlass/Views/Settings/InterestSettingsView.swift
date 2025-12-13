import SwiftUI

struct InterestSettingsView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                ScanlinesOverlay()
                    .opacity(0.15)

                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, geometry.safeAreaInsets.top + 16)
                        .hudHorizontalPadding(geometry.safeAreaInsets)

                    // Bubbles container
                    FloatingBubblesContainer(viewModel: viewModel)
                        .frame(maxHeight: .infinity)
                        .offset(y: -20)

                    // Footer
                    footerSection
                        .hudHorizontalPadding(geometry.safeAreaInsets)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 40))
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onAppear {
            viewModel.loadSelectedInterests()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(NSLocalizedString("settings_edit_interests", comment: ""))
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))

            Text(viewModel.validationMessage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(viewModel.isValidSelection ? Color.accentColor.opacity(0.9) : Color.white.opacity(0.6))
                .animation(.easeInOut(duration: 0.2), value: viewModel.selectionCount)
        }
        .padding(.bottom, 20)
    }

    private var footerSection: some View {
        GeometryReader { geometry in
            Button(action: handleDone) {
                Text(NSLocalizedString("settings_done", comment: ""))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(buttonForeground)
                    .padding(.vertical, 16)
                    .frame(width: geometry.size.width * 0.5)
                    .background(buttonBackground, in: Capsule(style: .continuous))
                    .overlay {
                        Capsule(style: .continuous)
                            .stroke(buttonBorder, lineWidth: 1)
                    }
            }
            .disabled(!viewModel.isValidSelection && viewModel.selectionCount > 0)
            .neonGlow(
                color: .accentColor,
                radius: canSave ? 16 : 0,
                intensity: canSave ? 0.25 : 0
            )
            .animation(.easeInOut(duration: 0.25), value: canSave)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 60)
    }

    private var canSave: Bool {
        viewModel.isValidSelection || viewModel.selectionCount == 0
    }

    private var buttonForeground: Color {
        canSave ? .white.opacity(0.95) : .white.opacity(0.4)
    }

    private var buttonBackground: some ShapeStyle {
        canSave
            ? AnyShapeStyle(Color.accentColor.opacity(0.25))
            : AnyShapeStyle(.ultraThinMaterial)
    }

    private var buttonBorder: Color {
        canSave
            ? .accentColor.opacity(0.6)
            : .white.opacity(0.15)
    }

    private func handleDone() {
        viewModel.saveSelectedInterests()
        dismiss()
    }
}

#Preview {
    InterestSettingsView()
}
