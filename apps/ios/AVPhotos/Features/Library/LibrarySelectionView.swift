import Photos
import SwiftUI

struct LibrarySelectionView: View {
    @EnvironmentObject private var permissionController: PhotoPermissionController
    @EnvironmentObject private var localLibraryController: LocalLibraryController
    @EnvironmentObject private var syncQueueController: SyncQueueController

    var body: some View {
        NavigationStack {
            List {
                Section(L10n.string("library.permissions.section")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(permissionController.title)
                            .font(.headline)
                        Text(permissionController.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if permissionController.canRequestAccess {
                            Button(L10n.string("library.permissions.request")) {
                                permissionController.requestAccess()
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button(L10n.string("library.permissions.refresh")) {
                                permissionController.refresh()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 6)
                }

                if permissionController.status == .authorized || permissionController.status == .limited {
                    Section(L10n.string("library.selected.section")) {
                        if localLibraryController.selectedAssets.isEmpty {
                            Text(L10n.string("library.selected.empty"))
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(localLibraryController.selectedAssets) { asset in
                                assetRow(asset)
                            }

                            Button(L10n.string("library.selected.enqueue")) {
                                syncQueueController.enqueue(localLibraryController.selectedAssets)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    Section(L10n.string("library.recent.section")) {
                        if localLibraryController.isLoading {
                            ProgressView()
                        } else if localLibraryController.recentAssets.isEmpty {
                            Text(L10n.string("library.recent.empty"))
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(localLibraryController.recentAssets) { asset in
                                Button {
                                    localLibraryController.toggleSelection(for: asset)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: localLibraryController.selectedAssetIDs.contains(asset.localIdentifier) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(localLibraryController.selectedAssetIDs.contains(asset.localIdentifier) ? .green : .secondary)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(asset.filename)
                                                .foregroundStyle(.primary)
                                            Text(assetSubtitle(for: asset))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Section(L10n.string("library.boundary.section")) {
                    Text(L10n.string("library.boundary.selective"))
                    Text(L10n.string("library.boundary.hosted"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(AVPhotosTheme.shellBackground.ignoresSafeArea())
            .navigationTitle("AV Photos")
            .task {
                localLibraryController.refreshIfAuthorized(status: permissionController.status)
            }
            .onChange(of: permissionController.status) { _, newStatus in
                localLibraryController.refreshIfAuthorized(status: newStatus)
            }
        }
    }

    private func assetRow(_ asset: LocalPhotoAsset) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(asset.filename)
                .font(.headline)
            Text(assetSubtitle(for: asset))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func assetSubtitle(for asset: LocalPhotoAsset) -> String {
        let dateText: String

        if let creationDate = asset.creationDate {
            dateText = creationDate.formatted(date: .abbreviated, time: .omitted)
        } else {
            dateText = L10n.string("library.asset.unknownDate")
        }

        return "\(dateText) • \(asset.pixelWidth)x\(asset.pixelHeight)"
    }
}
