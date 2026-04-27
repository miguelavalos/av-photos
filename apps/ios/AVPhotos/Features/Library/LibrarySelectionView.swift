import Photos
import SwiftUI

struct LibrarySelectionView: View {
    @EnvironmentObject private var permissionController: PhotoPermissionController

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

                Section("V1 Product Boundary") {
                    Text("AV Photos starts with selective sync. The app should help you choose exactly what to upload instead of assuming the full camera roll.")
                    Text("Hosted sync is intended for Pro access. Self-hosted compatibility should remain possible without depending on the Avalsys production backend.")
                }

                Section("Next Client Work") {
                    Label("Selected local assets list", systemImage: "checklist")
                    Label("Persisted sync queue", systemImage: "externaldrive.badge.icloud")
                    Label("Prepare-upload and commit-upload integration", systemImage: "arrow.up.doc")
                }
            }
            .navigationTitle("AV Photos")
        }
    }
}
