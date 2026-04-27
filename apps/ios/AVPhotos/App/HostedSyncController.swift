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
    @Published private(set) var deletingAssetID: String?

    func refresh() async {
        guard let baseURL = AppConfig.avAppsAPIBaseURL else {
            hostedState = .notConfigured
            assets = []
            lastRefreshedAt = nil
            return
        }

        hostedState = .checking

        let result = await probeConnection(
            baseURL: baseURL,
            authToken: AppConfig.isUsingSelfHostedOverride ? AppConfig.selfHostedAuthToken : nil
        )
        assets = result.assets
        hostedState = result.state
        lastRefreshedAt = result.lastRefreshedAt
    }

    func probeConnection(baseURL: URL, authToken: String?) async -> ProbeResult {
        let client = makeClient(baseURL: baseURL, authToken: authToken)

        do {
            _ = try await client.fetchHealth()
        } catch {
            return ProbeResult(
                state: .failed(error.localizedDescription),
                assets: [],
                lastRefreshedAt: nil
            )
        }

        do {
            let response = try await client.listAssets()
            return ProbeResult(
                state: .ready(assetCount: response.assets.count),
                assets: response.assets,
                lastRefreshedAt: .now
            )
        } catch let error as AVPhotosAPIClientError {
            switch error {
            case .authRequired:
                return ProbeResult(state: .authRequired, assets: [], lastRefreshedAt: nil)
            case .forbidden(let message):
                return ProbeResult(state: .forbidden(message), assets: [], lastRefreshedAt: nil)
            default:
                return ProbeResult(
                    state: .failed(error.localizedDescription),
                    assets: [],
                    lastRefreshedAt: nil
                )
            }
        } catch {
            return ProbeResult(
                state: .failed(error.localizedDescription),
                assets: [],
                lastRefreshedAt: nil
            )
        }
    }

    func deleteAsset(_ asset: HostedPhotoAsset) async throws {
        guard let baseURL = AppConfig.avAppsAPIBaseURL else {
            hostedState = .notConfigured
            assets = []
            lastRefreshedAt = nil
            return
        }

        deletingAssetID = asset.assetId
        defer { deletingAssetID = nil }

        let client = makeClient(
            baseURL: baseURL,
            authToken: AppConfig.isUsingSelfHostedOverride ? AppConfig.selfHostedAuthToken : nil
        )

        _ = try await client.deleteAsset(assetID: asset.assetId)
        assets.removeAll { $0.assetId == asset.assetId }
        hostedState = .ready(assetCount: assets.count)
        lastRefreshedAt = .now
    }

    private func makeClient(baseURL: URL, authToken: String?) -> AVPhotosAPIClient {
        AVPhotosAPIClient(
            baseURL: baseURL,
            authToken: authToken,
            authTokenProvider: {
                try await SharedAccountService.getToken()
            }
        )
    }
}

extension HostedSyncController {
    struct ProbeResult {
        let state: HostedState
        let assets: [HostedPhotoAsset]
        let lastRefreshedAt: Date?
    }
}
