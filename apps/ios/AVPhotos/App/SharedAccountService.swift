import Foundation

enum SharedAccountService {
    @MainActor
    static let instance: AVAppsAccountService = DefaultAVAppsAccountService()

    @MainActor
    static func getToken() async throws -> String? {
        try await instance.getToken()
    }
}
