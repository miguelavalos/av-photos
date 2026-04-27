import Foundation

@MainActor
final class HostedSyncController: ObservableObject {
    enum HostedState: Equatable {
        case notConfigured
        case checking
        case authRequired
        case forbidden(String)
        case ready(assetCount: Int)
        case failed(String)
    }

    @Published private(set) var hostedState: HostedState = .notConfigured
    @Published private(set) var assets: [HostedPhotoAsset] = []
    @Published private(set) var lastRefreshedAt: Date?

    func refresh() async {
        guard let baseURL = AppConfig.avAppsAPIBaseURL else {
            hostedState = .notConfigured
            assets = []
            lastRefreshedAt = nil
            return
        }

        let client = AVPhotosAPIClient(baseURL: baseURL, authToken: AppConfig.authToken)

        hostedState = .checking

        do {
            _ = try await client.fetchHealth()
        } catch {
            hostedState = .failed(error.localizedDescription)
            assets = []
            return
        }

        do {
            let response = try await client.listAssets()
            assets = response.assets
            hostedState = .ready(assetCount: response.assets.count)
            lastRefreshedAt = .now
        } catch let error as AVPhotosAPIClientError {
            assets = []

            switch error {
            case .authRequired:
                hostedState = .authRequired
            case .forbidden(let message):
                hostedState = .forbidden(message)
            default:
                hostedState = .failed(error.localizedDescription)
            }
        } catch {
            assets = []
            hostedState = .failed(error.localizedDescription)
        }
    }
}
