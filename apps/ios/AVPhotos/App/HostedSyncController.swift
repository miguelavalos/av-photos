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

    private let client: AVPhotosAPIClient?

    init(client: AVPhotosAPIClient? = AppConfig.avAppsAPIBaseURL.map { AVPhotosAPIClient(baseURL: $0) }) {
        self.client = client
    }

    func refresh() async {
        guard let client else {
            hostedState = .notConfigured
            assets = []
            lastRefreshedAt = nil
            return
        }

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
