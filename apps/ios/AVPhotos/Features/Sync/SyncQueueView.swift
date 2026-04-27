import SwiftUI

struct SyncQueueView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Queue") {
                    ContentUnavailableView(
                        "No Pending Uploads",
                        systemImage: "tray",
                        description: Text("The real queue will appear here once local asset selection and upload orchestration are wired.")
                    )
                }

                Section("Hosted Flow") {
                    Label("Prepare upload in private av-apps", systemImage: "1.circle")
                    Label("Upload bytes to the prepared target", systemImage: "2.circle")
                    Label("Commit metadata and list remote assets", systemImage: "3.circle")
                }
            }
            .navigationTitle("Sync")
        }
    }
}
