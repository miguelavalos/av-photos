import Foundation

enum AccessMode: String {
    case guest
    case signedInFree
    case signedInPro
}

struct PhotosAccountUser: Equatable {
    let id: String
    let displayName: String
    let emailAddress: String?

    var initials: String {
        let pieces = displayName.split(separator: " ")
        let initials = pieces.prefix(2).compactMap { $0.first }.map(String.init).joined()
        return initials.isEmpty ? "AV" : initials.uppercased()
    }
}

@MainActor
final class AccessController: ObservableObject {
    @Published private(set) var accessMode: AccessMode
    @Published private(set) var accountUser: PhotosAccountUser?

    let accountService: AVAppsAccountService

    private let userDefaults: UserDefaults
    private let onboardingPromptKey = "avphotos.guestOnboarding.lastPromptAt"

    init(
        accountService: AVAppsAccountService = SharedAccountService.instance,
        userDefaults: UserDefaults = .standard
    ) {
        self.accountService = accountService
        self.userDefaults = userDefaults
        self.accountUser = accountService.currentUser
        self.accessMode = accountService.currentUser == nil ? .guest : .signedInFree
    }

    var accountIsAvailable: Bool {
        accountService.isAvailable
    }

    var hasEverSeenGuestOnboarding: Bool {
        userDefaults.object(forKey: onboardingPromptKey) as? Date != nil
    }

    var shouldAutoShowGuestOnboarding: Bool {
        guard accessMode == .guest else { return false }
        guard let lastPromptAt = userDefaults.object(forKey: onboardingPromptKey) as? Date else {
            return true
        }

        return Date() >= lastPromptAt.addingTimeInterval(10 * 24 * 60 * 60)
    }

    func syncFromAccountProvider() async {
        accountUser = accountService.currentUser
        accessMode = accountUser == nil ? .guest : .signedInFree
    }

    func markGuestOnboardingPromptShown() {
        userDefaults.set(Date(), forKey: onboardingPromptKey)
    }

    func skipForNow() {
        markGuestOnboardingPromptShown()
        accessMode = .guest
    }

    func signInWithApple() async throws {
        try await accountService.signInWithApple()
        markGuestOnboardingPromptShown()
        await syncFromAccountProvider()
    }

    func signInWithGoogle() async throws {
        try await accountService.signInWithGoogle()
        markGuestOnboardingPromptShown()
        await syncFromAccountProvider()
    }

    func signOut() async {
        try? await accountService.signOut()
        await syncFromAccountProvider()
    }
}
