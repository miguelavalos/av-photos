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
    let providerLabel: String

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

    private let userDefaults: UserDefaults
    private let onboardingPromptKey = "avphotos.guestOnboarding.lastPromptAt"
    private let accountIDKey = "avphotos.account.id"
    private let accountNameKey = "avphotos.account.name"
    private let accountEmailKey = "avphotos.account.email"
    private let accountProviderKey = "avphotos.account.provider"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let userID = userDefaults.string(forKey: accountIDKey),
           let displayName = userDefaults.string(forKey: accountNameKey),
           let providerLabel = userDefaults.string(forKey: accountProviderKey) {
            self.accountUser = PhotosAccountUser(
                id: userID,
                displayName: displayName,
                emailAddress: userDefaults.string(forKey: accountEmailKey),
                providerLabel: providerLabel
            )
            self.accessMode = .signedInFree
        } else {
            self.accountUser = nil
            self.accessMode = .guest
        }
    }

    var accountIsAvailable: Bool {
        true
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
        if accountUser == nil {
            accessMode = .guest
        }
    }

    func markGuestOnboardingPromptShown() {
        userDefaults.set(Date(), forKey: onboardingPromptKey)
    }

    func skipForNow() {
        markGuestOnboardingPromptShown()
        accessMode = .guest
    }

    func signInWithApple() async throws {
        try await signIn(
            providerLabel: "Apple",
            displayName: "AV Photos User",
            emailAddress: "photos-user@example.com"
        )
    }

    func signInWithGoogle() async throws {
        try await signIn(
            providerLabel: "Google",
            displayName: "AV Photos User",
            emailAddress: "photos-user@example.com"
        )
    }

    func signOut() async {
        userDefaults.removeObject(forKey: accountIDKey)
        userDefaults.removeObject(forKey: accountNameKey)
        userDefaults.removeObject(forKey: accountEmailKey)
        userDefaults.removeObject(forKey: accountProviderKey)
        accountUser = nil
        accessMode = .guest
    }

    private func signIn(
        providerLabel: String,
        displayName: String,
        emailAddress: String?
    ) async throws {
        let userID = UUID().uuidString.lowercased()
        userDefaults.set(userID, forKey: accountIDKey)
        userDefaults.set(displayName, forKey: accountNameKey)
        userDefaults.set(emailAddress, forKey: accountEmailKey)
        userDefaults.set(providerLabel, forKey: accountProviderKey)
        markGuestOnboardingPromptShown()

        accountUser = PhotosAccountUser(
            id: userID,
            displayName: displayName,
            emailAddress: emailAddress,
            providerLabel: providerLabel
        )
        accessMode = .signedInFree
    }
}
