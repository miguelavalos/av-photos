import ClerkKit
import Foundation

enum AppConfig {
    private static let selfHostedBaseURLKey = "avphotos.selfHosted.baseURL"
    private static let selfHostedAuthTokenKey = "avphotos.selfHosted.authToken"

    static var avAppsAccountKey: String {
        stringValue(for: "AVAPPS_ACCOUNT_PUBLISHABLE_KEY")
    }

    static var avAppsAPIBaseURL: URL? {
        if let overrideURL = nonEmptyOverrideValue(for: selfHostedBaseURLKey) {
            return URL(string: overrideURL)
        }
        return urlValue(for: "AVAPPS_API_BASE_URL") ?? urlValue(for: "AVPHOTOS_AVAPPS_API_BASE_URL")
    }

    static var selfHostedBaseURLString: String? {
        nonEmptyOverrideValue(for: selfHostedBaseURLKey)
    }

    static var selfHostedAuthToken: String? {
        nonEmptyOverrideValue(for: selfHostedAuthTokenKey)
    }

    static var isUsingSelfHostedOverride: Bool {
        selfHostedBaseURLString != nil
    }

    static var accountManagementURL: URL? {
        urlValue(for: "AVPHOTOS_ACCOUNT_MANAGEMENT_URL")
    }

    static var termsURL: URL? {
        urlValue(for: "AVPHOTOS_TERMS_URL")
    }

    static var privacyURL: URL? {
        urlValue(for: "AVPHOTOS_PRIVACY_URL")
    }

    static var openSourceURL: URL? {
        urlValue(for: "AVPHOTOS_OPEN_SOURCE_URL")
    }

    static var supportEmail: String? {
        nonEmptyStringValue(for: "AVPHOTOS_SUPPORT_EMAIL")
    }

    static var supportURL: URL? {
        guard let supportEmail else { return nil }
        let encodedSubject = "AV Photos Support".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "AV%20Photos%20Support"
        return URL(string: "mailto:\(supportEmail)?subject=\(encodedSubject)")
    }

    static var isHostedSyncConfigured: Bool {
        avAppsAPIBaseURL != nil
    }

    static var isAVAppsAccountAvailable: Bool {
        !avAppsAccountKey.isEmpty
    }

    @MainActor
    static func configureAVAppsAccountIfPossible() {
        guard isAVAppsAccountAvailable else {
            return
        }

        Clerk.configure(publishableKey: avAppsAccountKey)
    }

    static func saveSelfHostedConfiguration(baseURLString: String, authToken: String?) {
        let trimmedBaseURL = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmedBaseURL, forKey: selfHostedBaseURLKey)

        let trimmedToken = authToken?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmedToken.isEmpty {
            UserDefaults.standard.removeObject(forKey: selfHostedAuthTokenKey)
        } else {
            UserDefaults.standard.set(trimmedToken, forKey: selfHostedAuthTokenKey)
        }
    }

    static func clearSelfHostedConfiguration() {
        UserDefaults.standard.removeObject(forKey: selfHostedBaseURLKey)
        UserDefaults.standard.removeObject(forKey: selfHostedAuthTokenKey)
    }

    static func hasValidSelfHostedBaseURL(_ value: String) -> Bool {
        selfHostedURL(from: value) != nil
    }

    static func selfHostedURL(from value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let url = URL(string: trimmed) else { return nil }
        guard let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http" else { return nil }
        guard url.host != nil else { return nil }
        return url
    }

    private static func stringValue(for key: String) -> String {
        nonEmptyStringValue(for: key) ?? ""
    }

    private static func nonEmptyStringValue(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("$("), trimmed.hasSuffix(")") {
            return nil
        }
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func urlValue(for key: String) -> URL? {
        guard let value = nonEmptyStringValue(for: key) else {
            return nil
        }

        return URL(string: value)
    }

    private static func nonEmptyOverrideValue(for key: String) -> String? {
        guard let value = UserDefaults.standard.string(forKey: key) else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
