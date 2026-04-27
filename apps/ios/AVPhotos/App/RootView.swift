import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            LibrarySelectionView()
                .tabItem {
                    Label("Library", systemImage: "photo.on.rectangle")
                }

            SyncQueueView()
                .tabItem {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                }

            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }
        }
    }
}
