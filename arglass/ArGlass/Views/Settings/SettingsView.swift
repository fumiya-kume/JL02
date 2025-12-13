import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingInterestSettings = false
    @State private var showingAgeGroupSettings = false
    @State private var showingBudgetSettings = false
    @State private var showingActivitySettings = false
    @State private var showingLanguageSettings = false
    @State private var currentPreferences = UserPreferencesManager.shared.load()

    var body: some View {
        GeometryReader { geometry in
            let safeRect = geometry.safeAreaInsets.safeRect(in: geometry.size)

            ZStack {
                Color.black

                ScanlinesOverlay()
                    .opacity(0.15)

                VStack(spacing: 0) {
                    headerSection
                        .padding(.top, geometry.safeAreaInsets.top + 16)
                        .hudHorizontalPadding(geometry.safeAreaInsets)

                    settingsList
                        .frame(width: safeRect.width * 0.5)
                        .padding(.top, 30)

                    Spacer()

                    closeButton
                        .frame(width: safeRect.width * 0.5)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 40))
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .fullScreenCover(isPresented: $showingInterestSettings) {
            OnboardingView(isEditing: true) {
                showingInterestSettings = false
            }
        }
        .fullScreenCover(isPresented: $showingAgeGroupSettings) {
            PreferencePickerView<UserAgeGroup>(
                titleKey: "settings_age_group",
                selection: Binding(
                    get: { currentPreferences.ageGroup },
                    set: { newValue in
                        currentPreferences.ageGroup = newValue
                        UserPreferencesManager.shared.save(currentPreferences)
                    }
                )
            )
        }
        .fullScreenCover(isPresented: $showingBudgetSettings) {
            PreferencePickerView<UserBudgetLevel>(
                titleKey: "settings_budget",
                selection: Binding(
                    get: { currentPreferences.budgetLevel },
                    set: { newValue in
                        currentPreferences.budgetLevel = newValue
                        UserPreferencesManager.shared.save(currentPreferences)
                    }
                )
            )
        }
        .fullScreenCover(isPresented: $showingActivitySettings) {
            PreferencePickerView<UserActivityLevel>(
                titleKey: "settings_activity",
                selection: Binding(
                    get: { currentPreferences.activityLevel },
                    set: { newValue in
                        currentPreferences.activityLevel = newValue
                        UserPreferencesManager.shared.save(currentPreferences)
                    }
                )
            )
        }
        .fullScreenCover(isPresented: $showingLanguageSettings) {
            LanguagePickerView(
                selection: Binding(
                    get: { currentPreferences.language },
                    set: { newValue in
                        currentPreferences.language = newValue
                        UserPreferencesManager.shared.save(currentPreferences)
                    }
                )
            )
        }
    }

    private var headerSection: some View {
        Text(NSLocalizedString("settings_title", comment: ""))
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(.white.opacity(0.95))
    }

    private var settingsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                settingsRow(
                    icon: "heart.circle",
                    title: NSLocalizedString("settings_interests", comment: ""),
                    action: { showingInterestSettings = true }
                )

                settingsRow(
                    icon: "person.crop.circle",
                    title: NSLocalizedString("settings_age_group", comment: ""),
                    action: { showingAgeGroupSettings = true }
                )

                settingsRow(
                    icon: "yensign.circle",
                    title: NSLocalizedString("settings_budget", comment: ""),
                    action: { showingBudgetSettings = true }
                )

                settingsRow(
                    icon: "figure.walk",
                    title: NSLocalizedString("settings_activity", comment: ""),
                    action: { showingActivitySettings = true }
                )

                settingsRow(
                    icon: "globe",
                    title: NSLocalizedString("settings_language", comment: ""),
                    action: { showingLanguageSettings = true }
                )
            }
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
                .frame(maxWidth: .infinity)
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
