import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var hostedSyncController: HostedSyncController

    var body: some View {
        NavigationStack {
            List {
                Section("Account State") {
                    Label(AppConfig.isHostedAuthConfigured ? "A local hosted auth token is configured." : "Account auth is not wired yet in this public scaffold.", systemImage: "person.badge.key")
                    Label(AppConfig.isHostedSyncConfigured ? "Hosted API base URL is configured locally." : "Hosted API base URL is not configured.", systemImage: "network")
                    Label(remoteStateSummary, systemImage: "externaldrive.badge.icloud")
                }

                Section("Links") {
                    if let accountURL = AppConfig.accountManagementURL {
                        Link(destination: accountURL) {
                            Label("Account Management", systemImage: "person.crop.circle.badge.gear")
                        }
                    }

                    if let termsURL = AppConfig.termsURL {
                        Link(destination: termsURL) {
                            Label("Terms", systemImage: "doc.text")
                        }
                    }

                    if let privacyURL = AppConfig.privacyURL {
                        Link(destination: privacyURL) {
                            Label("Privacy", systemImage: "hand.raised")
                        }
                    }

                    if let openSourceURL = AppConfig.openSourceURL {
                        Link(destination: openSourceURL) {
                            Label("Open Source", systemImage: "chevron.left.forwardslash.chevron.right")
                        }
                    }

                    if let supportURL = AppConfig.supportURL {
                        Link(destination: supportURL) {
                            Label("Support", systemImage: "envelope")
                        }
                    }
                }

                Section("Product Policy") {
                    Text("The public client should remain open-source without donating the hosted Avalsys backend to every user by default.")
                }
            }
            .navigationTitle("Account")
        }
    }

    private var remoteStateSummary: String {
        switch hostedSyncController.hostedState {
        case .notConfigured:
            "Remote hosted sync is currently disabled in local config."
        case .checking:
            "Remote hosted sync is being checked."
        case .authRequired:
            "Remote hosted sync is reachable, but an auth token is missing."
        case .forbidden(let message):
            message
        case .ready(let assetCount):
            "Remote hosted sync is working. Current remote asset count: \(assetCount)."
        case .failed(let message):
            "Remote hosted sync check failed: \(message)"
        }
    }
}
