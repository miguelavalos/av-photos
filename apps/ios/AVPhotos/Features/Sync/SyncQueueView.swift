import SwiftUI

struct SyncQueueView: View {
    @EnvironmentObject private var hostedSyncController: HostedSyncController
    @EnvironmentObject private var syncQueueController: SyncQueueController

    var body: some View {
        NavigationStack {
            List {
                Section("Queue") {
                    if syncQueueController.items.isEmpty {
                        ContentUnavailableView(
                            "No Pending Uploads",
                            systemImage: "tray",
                            description: Text("Select local photos in the Library tab and add them to the queue.")
                        )
                    } else {
                        ForEach(syncQueueController.items) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.filename)
                                    .font(.headline)
                                Text(item.status.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if let lastMessage = item.lastMessage {
                                    Text(lastMessage)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Button(syncQueueController.isSyncing ? "Syncing..." : "Sync Pending Items") {
                            Task {
                                await syncQueueController.syncPending()
                                await hostedSyncController.refresh()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(syncQueueController.isSyncing)
                    }
                }

                Section("Hosted Status") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(statusTitle)
                            .font(.headline)
                        Text(statusDetail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Refresh Hosted State") {
                            Task {
                                await hostedSyncController.refresh()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 6)
                }

                if !hostedSyncController.assets.isEmpty {
                    Section("Remote Assets") {
                        ForEach(hostedSyncController.assets.prefix(10)) { asset in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(asset.originalFilename)
                                    .font(.headline)
                                Text("\(asset.pixelWidth)x\(asset.pixelHeight) • \(asset.byteSize) bytes • \(asset.syncStatus)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Hosted Flow") {
                    Label("Prepare upload in private av-apps", systemImage: "1.circle")
                    Label("Upload bytes to the prepared target", systemImage: "2.circle")
                    Label("Commit metadata and list remote assets", systemImage: "3.circle")
                }
            }
            .navigationTitle("Sync")
            .task {
                await hostedSyncController.refresh()
            }
        }
    }

    private var statusTitle: String {
        switch hostedSyncController.hostedState {
        case .notConfigured:
            "Hosted sync is not configured"
        case .checking:
            "Checking hosted sync"
        case .authRequired:
            "Hosted sync needs an auth token"
        case .forbidden:
            "Hosted sync is configured but not entitled"
        case .ready(let assetCount):
            "Hosted sync is reachable"
            + (assetCount == 0 ? " with no remote assets yet" : " with \(assetCount) remote assets")
        case .failed:
            "Hosted sync check failed"
        }
    }

    private var statusDetail: String {
        switch hostedSyncController.hostedState {
        case .notConfigured:
            "Set `AVPHOTOS_AVAPPS_API_BASE_URL` in your local config to point the app at a hosted or self-hosted backend."
        case .checking:
            "The app is checking backend reachability and remote asset access."
        case .authRequired:
            "Set `AVPHOTOS_AUTH_TOKEN` locally if you want this public client to call authenticated hosted endpoints during development."
        case .forbidden(let message):
            message
        case .ready:
            "The backend is reachable and the app can decode the remote AV Photos asset list."
        case .failed(let message):
            message
        }
    }
}
