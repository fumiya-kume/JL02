import SwiftUI

// MARK: - Preference Option Protocol

protocol PreferenceOption: CaseIterable, Identifiable, RawRepresentable, Equatable where RawValue == String, AllCases: RandomAccessCollection {
    var localizedName: String { get }
    var icon: String { get }
}

extension UserAgeGroup: PreferenceOption {}
extension UserBudgetLevel: PreferenceOption {}
extension UserActivityLevel: PreferenceOption {}
extension UserLanguage: PreferenceOption {}

// MARK: - Preference Picker View

struct PreferencePickerView<T: PreferenceOption>: View {
    let titleKey: String
    @Binding var selection: T?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                ScanlinesOverlay()
                    .opacity(0.15)

                VStack(spacing: 0) {
                    Text(NSLocalizedString(titleKey, comment: ""))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(.top, geometry.safeAreaInsets.top + 16)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(T.allCases), id: \.id) { option in
                                optionRow(option: option)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 30)
                    }

                    Spacer()

                    closeButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 40))
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
    }

    private func optionRow(option: T) -> some View {
        Button {
            selection = option
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: option.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(selection == option ? Color.accentColor : .white.opacity(0.6))
                    .frame(width: 32)

                Text(option.localizedName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                if selection == option {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .background(
                selection == option
                    ? Color.accentColor.opacity(0.15)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        selection == option ? Color.accentColor.opacity(0.5) : Color.white.opacity(0.15),
                        lineWidth: 1
                    )
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

// MARK: - Language Picker (special case - always has a value)

struct LanguagePickerView: View {
    @Binding var selection: UserLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                ScanlinesOverlay()
                    .opacity(0.15)

                VStack(spacing: 0) {
                    Text(NSLocalizedString("settings_language", comment: ""))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(.top, geometry.safeAreaInsets.top + 16)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(UserLanguage.allCases), id: \.id) { option in
                                optionRow(option: option)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 30)
                    }

                    Spacer()

                    closeButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom, 40))
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
    }

    private func optionRow(option: UserLanguage) -> some View {
        Button {
            selection = option
            dismiss()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: option.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(selection == option ? Color.accentColor : .white.opacity(0.6))
                    .frame(width: 32)

                Text(option.localizedName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                if selection == option {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .background(
                selection == option
                    ? Color.accentColor.opacity(0.15)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        selection == option ? Color.accentColor.opacity(0.5) : Color.white.opacity(0.15),
                        lineWidth: 1
                    )
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
    PreferencePickerView<UserAgeGroup>(titleKey: "settings_age_group", selection: .constant(.twenties))
}
