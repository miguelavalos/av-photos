import Photos
import SwiftUI

struct LibrarySelectionView: View {
    @EnvironmentObject private var permissionController: PhotoPermissionController
    @EnvironmentObject private var localLibraryController: LocalLibraryController
    @EnvironmentObject private var syncQueueController: SyncQueueController

    var body: some View {
        NavigationStack {
            List {
                Section("Photo Library") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(permissionController.title)
                            .font(.headline)
                        Text(permissionController.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if permissionController.canRequestAccess {
                            Button("Request Access") {
                                permissionController.requestAccess()
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button("Refresh Status") {
                                permissionController.refresh()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 6)
                }

                if permissionController.status == .authorized || permissionController.status == .limited {
                    Section("Selected For Sync") {
                        if localLibraryController.selectedAssets.isEmpty {
                            Text("No local photos are selected yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(localLibraryController.selectedAssets) { asset in
                                assetRow(asset)
                            }

                            Button("Add Selected To Sync Queue") {
                                syncQueueController.enqueue(localLibraryController.selectedAssets)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    Section("Recent Local Photos") {
                        if localLibraryController.isLoading {
                            ProgressView()
                        } else if localLibraryController.recentAssets.isEmpty {
                            Text("No local photo assets were loaded.")
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

                Section("V1 Product Boundary") {
                    Text("AV Photos starts with selective sync. The app should help you choose exactly what to upload instead of assuming the full camera roll.")
                    Text("Hosted sync is intended for Pro access. Self-hosted compatibility should remain possible without depending on the Avalsys production backend.")
                }
            }
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
            dateText = "Unknown date"
        }

        return "\(dateText) • \(asset.pixelWidth)x\(asset.pixelHeight)"
    }
}
