import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HUDViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var needsInterestReselection = false

    var body: some View {
        Group {
            if hasCompletedOnboarding && !needsInterestReselection {
                HUDRootView(viewModel: viewModel)
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                    needsInterestReselection = false
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            needsInterestReselection = UserPreferencesManager.shared.migrateInterestsIfNeeded()
        }
    }
}

#Preview {
    ContentView()
}

