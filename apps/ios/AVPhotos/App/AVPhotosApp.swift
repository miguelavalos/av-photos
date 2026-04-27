import SwiftUI

@main
struct AVPhotosApp: App {
    @StateObject private var permissionController = PhotoPermissionController()
    @StateObject private var hostedSyncController = HostedSyncController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(permissionController)
                .environmentObject(hostedSyncController)
        }
    }
}
