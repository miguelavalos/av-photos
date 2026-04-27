import Foundation

@MainActor
final class SyncQueueController: ObservableObject {
    @Published private(set) var items: [SyncQueueItem]
    @Published private(set) var isSyncing = false

    private let userDefaults: UserDefaults
    private let queueKey = "avphotos.syncQueue"
    private let deviceIDKey = "avphotos.deviceID"
    private let photoLibraryService: PhotoLibraryService
    private let client: AVPhotosAPIClient?

    init(
        userDefaults: UserDefaults = .standard,
        photoLibraryService: PhotoLibraryService = PhotoLibraryService(),
        client: AVPhotosAPIClient? = AppConfig.avAppsAPIBaseURL.map { AVPhotosAPIClient(baseURL: $0) }
    ) {
        self.userDefaults = userDefaults
        self.photoLibraryService = photoLibraryService
        self.client = client

        if let data = userDefaults.data(forKey: queueKey),
           let decoded = try? JSONDecoder().decode([SyncQueueItem].self, from: data) {
            self.items = decoded
        } else {
            self.items = []
        }
    }

    var deviceID: String {
        if let existing = userDefaults.string(forKey: deviceIDKey) {
            return existing
        }

        let created = UUID().uuidString.lowercased()
        userDefaults.set(created, forKey: deviceIDKey)
        return created
    }

    func enqueue(_ assets: [LocalPhotoAsset]) {
        for asset in assets {
            guard !items.contains(where: { $0.localIdentifier == asset.localIdentifier && $0.status != .completed }) else {
                continue
            }

            items.append(
                SyncQueueItem(
                    id: UUID().uuidString,
                    localIdentifier: asset.localIdentifier,
                    filename: asset.filename,
                    createdAt: .now,
                    status: .pending,
                    lastMessage: nil,
                    remoteAssetId: nil
                )
            )
        }

        persist()
    }

    func syncPending() async {
        guard !isSyncing else { return }
        guard let client else {
            updateAllPendingFailures(message: "Hosted sync is not configured.")
            return
        }

        isSyncing = true
        defer {
            isSyncing = false
            persist()
        }

        for index in items.indices {
            if items[index].status == .completed {
                continue
            }

            do {
                items[index].status = .preparing
                items[index].lastMessage = "Loading local asset metadata"

                let payload = try await photoLibraryService.fetchUploadPayload(for: items[index].localIdentifier)
                let prepare = try await client.prepareUpload(
                    deviceID: deviceID,
                    localIdentifier: payload.asset.localIdentifier,
                    filename: payload.asset.filename,
                    captureTakenAt: payload.captureTakenAt,
                    byteSize: payload.data.count,
                    pixelWidth: payload.asset.pixelWidth,
                    pixelHeight: payload.asset.pixelHeight,
                    sha256: payload.sha256
                )

                items[index].remoteAssetId = prepare.assetId

                if prepare.shouldUpload {
                    items[index].status = .uploading
                    items[index].lastMessage = "Uploading bytes"
                    try await client.uploadPreparedAsset(uploadURLPath: prepare.uploadUrl, data: payload.data)

                    items[index].status = .committing
                    items[index].lastMessage = "Committing remote metadata"
                    _ = try await client.commitUpload(
                        assetID: prepare.assetId,
                        uploadToken: prepare.uploadToken,
                        deviceID: deviceID
                    )
                } else {
                    items[index].lastMessage = "Remote asset already exists"
                }

                items[index].status = .completed
                items[index].lastMessage = "Sync completed"
            } catch {
                items[index].status = .failed
                items[index].lastMessage = error.localizedDescription
            }
        }
    }

    private func updateAllPendingFailures(message: String) {
        for index in items.indices where items[index].status != .completed {
            items[index].status = .failed
            items[index].lastMessage = message
        }

        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            userDefaults.set(data, forKey: queueKey)
        }
    }
}
