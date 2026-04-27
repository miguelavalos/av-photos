import SwiftUI

@main
struct AVPhotosApp: App {
    @StateObject private var permissionController = PhotoPermissionController()
    @StateObject private var hostedSyncController = HostedSyncController()
    @StateObject private var localLibraryController = LocalLibraryController()
    @StateObject private var syncQueueController = SyncQueueController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(permissionController)
                .environmentObject(hostedSyncController)
                .environmentObject(localLibraryController)
                .environmentObject(syncQueueController)
        }
    }
}
