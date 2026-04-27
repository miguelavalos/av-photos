import Foundation
import UIKit

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
    @Published private(set) var recentChanges: [HostedPhotoAsset] = []
    @Published private(set) var lastRefreshedAt: Date?
    @Published private(set) var deletingAssetID: String?
    @Published private(set) var changesCursor: String?

    private let userDefaults: UserDefaults
    private let recentChangesKey = "avphotos.hosted.recentChanges"
    private let changesCursorKey = "avphotos.hosted.changesCursor"
    private let maxStoredChanges = 10
    private var previewImageCache: [String: UIImage] = [:]

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let data = userDefaults.data(forKey: recentChangesKey),
           let decoded = try? JSONDecoder().decode([HostedPhotoAsset].self, from: data) {
            recentChanges = decoded
        } else {
            recentChanges = []
        }

        changesCursor = userDefaults.string(forKey: changesCursorKey)
    }

    func refresh() async {
        guard let baseURL = AppConfig.avAppsAPIBaseURL else {
            hostedState = .notConfigured
            assets = []
            recentChanges = []
            changesCursor = nil
            lastRefreshedAt = nil
            persistChangesState()
            return
        }

        hostedState = .checking

        let result = await probeConnection(
            baseURL: baseURL,
            authToken: AppConfig.isUsingSelfHostedOverride ? AppConfig.selfHostedAuthToken : nil
        )
        assets = result.assets
        recentChanges = mergedRecentChanges(current: recentChanges, incoming: result.changes)
        changesCursor = result.changesCursor
        hostedState = result.state
        lastRefreshedAt = result.lastRefreshedAt
        persistChangesState()
    }

    func probeConnection(baseURL: URL, authToken: String?) async -> ProbeResult {
        let client = makeClient(baseURL: baseURL, authToken: authToken)

        do {
            _ = try await client.fetchHealth()
        } catch {
            return ProbeResult(
                state: .failed(error.localizedDescription),
                assets: [],
                changes: [],
                changesCursor: nil,
                lastRefreshedAt: nil
            )
        }

        do {
            let response = try await client.listAssets()
            let changesResponse = try await client.listChanges(cursor: changesCursor)
            return ProbeResult(
                state: .ready(assetCount: response.assets.count),
                assets: response.assets,
                changes: changesResponse.changes,
                changesCursor: changesResponse.cursor,
                lastRefreshedAt: .now
            )
        } catch let error as AVPhotosAPIClientError {
            switch error {
            case .authRequired:
                return ProbeResult(state: .authRequired, assets: [], changes: [], changesCursor: nil, lastRefreshedAt: nil)
            case .forbidden(let message):
                return ProbeResult(state: .forbidden(message), assets: [], changes: [], changesCursor: nil, lastRefreshedAt: nil)
            default:
                return ProbeResult(
                    state: .failed(error.localizedDescription),
                    assets: [],
                    changes: [],
                    changesCursor: nil,
                    lastRefreshedAt: nil
                )
            }
        } catch {
            return ProbeResult(
                state: .failed(error.localizedDescription),
                assets: [],
                changes: [],
                changesCursor: nil,
                lastRefreshedAt: nil
            )
        }
    }

    func deleteAsset(_ asset: HostedPhotoAsset) async throws {
        guard let baseURL = AppConfig.avAppsAPIBaseURL else {
            hostedState = .notConfigured
            assets = []
            recentChanges = []
            changesCursor = nil
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
        recentChanges.insert(
            HostedPhotoAsset(
                assetId: asset.assetId,
                deviceId: asset.deviceId,
                sourceLocalIdentifier: asset.sourceLocalIdentifier,
                originalFilename: asset.originalFilename,
                mediaType: asset.mediaType,
                captureTakenAt: asset.captureTakenAt,
                importedAt: asset.importedAt,
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight,
                byteSize: asset.byteSize,
                sha256: asset.sha256,
                storageKeyOriginal: asset.storageKeyOriginal,
                previewPath: nil,
                syncStatus: "deleted",
                deletedAt: ISO8601DateFormatter().string(from: .now),
                updatedAt: ISO8601DateFormatter().string(from: .now)
            ),
            at: 0
        )
        recentChanges = Array(recentChanges.prefix(maxStoredChanges))
        hostedState = .ready(assetCount: assets.count)
        lastRefreshedAt = .now
        changesCursor = recentChanges.first?.updatedAt ?? changesCursor
        persistChangesState()
    }

    func previewImage(for asset: HostedPhotoAsset) async throws -> UIImage? {
        guard let previewPath = asset.previewPath, !previewPath.isEmpty else {
            return nil
        }

        if let cachedImage = previewImageCache[previewPath] {
            return cachedImage
        }

        guard let baseURL = AppConfig.avAppsAPIBaseURL else {
            return nil
        }

        let client = makeClient(
            baseURL: baseURL,
            authToken: AppConfig.isUsingSelfHostedOverride ? AppConfig.selfHostedAuthToken : nil
        )
        let data = try await client.fetchPreviewData(path: previewPath)

        guard let image = UIImage(data: data) else {
            return nil
        }

        previewImageCache[previewPath] = image
        return image
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

    private func mergedRecentChanges(current: [HostedPhotoAsset], incoming: [HostedPhotoAsset]) -> [HostedPhotoAsset] {
        var seen = Set<String>()
        var merged: [HostedPhotoAsset] = []

        for asset in (incoming + current) {
            let key = "\(asset.assetId)|\(asset.updatedAt)|\(asset.syncStatus)"
            guard seen.insert(key).inserted else { continue }
            merged.append(asset)
        }

        merged.sort { lhs, rhs in
            lhs.updatedAt > rhs.updatedAt
        }

        return Array(merged.prefix(maxStoredChanges))
    }

    private func persistChangesState() {
        if let data = try? JSONEncoder().encode(recentChanges) {
            userDefaults.set(data, forKey: recentChangesKey)
        }

        userDefaults.set(changesCursor, forKey: changesCursorKey)
    }
}

extension HostedSyncController {
    struct ProbeResult {
        let state: HostedState
        let assets: [HostedPhotoAsset]
        let changes: [HostedPhotoAsset]
        let changesCursor: String?
        let lastRefreshedAt: Date?
    }
}
