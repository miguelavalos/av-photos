import Foundation

enum AppConfig {
    static var avAppsAPIBaseURL: URL? {
        urlValue(for: "AVPHOTOS_AVAPPS_API_BASE_URL")
    }

    static var authToken: String? {
        nonEmptyStringValue(for: "AVPHOTOS_AUTH_TOKEN")
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

    static var isHostedAuthConfigured: Bool {
        authToken != nil
    }

    private static func nonEmptyStringValue(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func urlValue(for key: String) -> URL? {
        guard let value = nonEmptyStringValue(for: key) else {
            return nil
        }

        return URL(string: value)
    }
}
