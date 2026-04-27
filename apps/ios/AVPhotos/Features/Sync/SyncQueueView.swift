import SwiftUI

struct SyncQueueView: View {
    @EnvironmentObject private var hostedSyncController: HostedSyncController
    @EnvironmentObject private var syncQueueController: SyncQueueController

    var body: some View {
        NavigationStack {
            List {
                Section(L10n.string("sync.queue.section")) {
                    if syncQueueController.items.isEmpty {
                        ContentUnavailableView(
                            L10n.string("sync.queue.empty.title"),
                            systemImage: "tray",
                            description: Text(L10n.string("sync.queue.empty.detail"))
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

                        Button(syncQueueController.isSyncing ? L10n.string("sync.queue.syncing") : L10n.string("sync.queue.sync")) {
                            Task {
                                await syncQueueController.syncPending()
                                await hostedSyncController.refresh()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(syncQueueController.isSyncing)
                    }
                }

                Section(L10n.string("sync.hosted.section")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(statusTitle)
                            .font(.headline)
                        Text(statusDetail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button(L10n.string("sync.hosted.refresh")) {
                            Task {
                                await hostedSyncController.refresh()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 6)
                }

                if !hostedSyncController.assets.isEmpty {
                    Section(L10n.string("sync.hosted.assets")) {
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

                Section(L10n.string("sync.flow.section")) {
                    Label(L10n.string("sync.flow.step1"), systemImage: "1.circle")
                    Label(L10n.string("sync.flow.step2"), systemImage: "2.circle")
                    Label(L10n.string("sync.flow.step3"), systemImage: "3.circle")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AVPhotosTheme.shellBackground.ignoresSafeArea())
            .navigationTitle(L10n.string("tab.sync"))
            .task {
                await hostedSyncController.refresh()
            }
        }
    }

    private var statusTitle: String {
        switch hostedSyncController.hostedState {
        case .notConfigured:
            L10n.string("sync.hosted.status.notConfigured")
        case .checking:
            L10n.string("sync.hosted.status.checking")
        case .authRequired:
            L10n.string("sync.hosted.status.authRequired")
        case .forbidden:
            L10n.string("sync.hosted.status.forbidden")
        case .ready(let assetCount):
            assetCount == 0
                ? L10n.string("sync.hosted.status.readyEmpty")
                : L10n.string("sync.hosted.status.readyCount", assetCount)
        case .failed:
            L10n.string("sync.hosted.status.failed")
        }
    }

    private var statusDetail: String {
        switch hostedSyncController.hostedState {
        case .notConfigured:
            L10n.string("sync.hosted.detail.notConfigured")
        case .checking:
            L10n.string("sync.hosted.detail.checking")
        case .authRequired:
            L10n.string("sync.hosted.detail.authRequired")
        case .forbidden(let message):
            message
        case .ready:
            L10n.string("sync.hosted.detail.ready")
        case .failed(let message):
            message
        }
    }
}
