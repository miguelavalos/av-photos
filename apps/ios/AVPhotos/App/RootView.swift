import SwiftUI

struct RootView: View {
    @EnvironmentObject private var accessController: AccessController
    @State private var authOptionsArePresented = false
    @State private var automaticGuestOnboardingIsPresented = false
    @State private var isShowingAccountOnboarding = false

    var body: some View {
        Group {
            if shouldShowOnboarding {
                AuthOnboardingView(
                    authOptionsArePresented: $authOptionsArePresented,
                    accountIsAvailable: accessController.accountIsAvailable,
                    onContinueWithApple: startAppleSignIn,
                    onContinueWithGoogle: startGoogleSignIn,
                    onSkip: {
                        automaticGuestOnboardingIsPresented = false
                        isShowingAccountOnboarding = false
                        accessController.skipForNow()
                    }
                )
            } else {
                TabView {
                    LibrarySelectionView()
                        .tabItem {
                            Label(L10n.string("tab.library"), systemImage: "photo.on.rectangle")
                        }

                    SyncQueueView()
                        .tabItem {
                            Label(L10n.string("tab.sync"), systemImage: "arrow.triangle.2.circlepath")
                        }

                    ProfileScreen(startSignInFlow: startSignInFlow)
                        .tabItem {
                            Label(L10n.string("tab.profile"), systemImage: "person.crop.circle")
                        }
                }
                .tint(AVPhotosTheme.highlight)
                .background(AVPhotosTheme.shellBackground.ignoresSafeArea())
            }
        }
        .task {
            await accessController.syncFromAccountProvider()
            presentAutomaticGuestOnboardingIfNeeded()
        }
        .onChange(of: accessController.accessMode) { _, _ in
            authOptionsArePresented = false

            if accessController.accessMode != .guest {
                automaticGuestOnboardingIsPresented = false
                isShowingAccountOnboarding = false
            }
        }
    }

    private var shouldShowOnboarding: Bool {
        isShowingAccountOnboarding || automaticGuestOnboardingIsPresented
    }

    private func startSignInFlow(_ showAuthOptions: Bool = false) {
        authOptionsArePresented = showAuthOptions
        isShowingAccountOnboarding = true
    }

    private func startAppleSignIn() async throws {
        try await accessController.signInWithApple()
        automaticGuestOnboardingIsPresented = false
        isShowingAccountOnboarding = false
    }

    private func startGoogleSignIn() async throws {
        try await accessController.signInWithGoogle()
        automaticGuestOnboardingIsPresented = false
        isShowingAccountOnboarding = false
    }

    private func presentAutomaticGuestOnboardingIfNeeded() {
        guard automaticGuestOnboardingIsPresented == false else { return }
        guard isShowingAccountOnboarding == false else { return }
        guard accessController.shouldAutoShowGuestOnboarding else { return }

        accessController.markGuestOnboardingPromptShown()
        automaticGuestOnboardingIsPresented = true
    }
}
