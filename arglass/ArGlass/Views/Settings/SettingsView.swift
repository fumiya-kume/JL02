import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingInterestSettings = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                ScanlinesOverlay()
                    .opacity(0.15)

                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, max(geometry.safeAreaInsets.top, 20) + 40)

                    // Settings list
                    settingsList
                        .padding(.horizontal, 20)
                        .padding(.top, 30)

                    Spacer()

                    // Close button
                    closeButton
                        .frame(width: geometry.size.width * 0.5)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 40))
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .fullScreenCover(isPresented: $showingInterestSettings) {
            InterestSettingsView()
        }
    }

    private var headerSection: some View {
        Text(NSLocalizedString("settings_title", comment: ""))
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(.white.opacity(0.95))
    }

    private var settingsList: some View {
        VStack(spacing: 12) {
            settingsRow(
                icon: "heart.circle",
                title: NSLocalizedString("settings_interests", comment: ""),
                action: { showingInterestSettings = true }
            )
        }
    }

    private func settingsRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            }
        }
    }

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Text(NSLocalizedString("settings_close", comment: ""))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.vertical, 14)
                .padding(.horizontal, 32)
                .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                }
        }
    }
}

#Preview {
    SettingsView()
}
