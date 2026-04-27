import SwiftUI

@main
struct AVPhotosApp: App {
    @StateObject private var permissionController = PhotoPermissionController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(permissionController)
        }
    }
}
