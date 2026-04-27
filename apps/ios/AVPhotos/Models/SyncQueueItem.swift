import Foundation

enum SyncQueueItemStatus: String, Codable {
    case pending
    case preparing
    case uploading
    case committing
    case completed
    case failed
}

struct SyncQueueItem: Identifiable, Codable, Equatable {
    let id: String
    let localIdentifier: String
    let filename: String
    let createdAt: Date
    var status: SyncQueueItemStatus
    var lastMessage: String?
    var remoteAssetId: String?
    var attemptCount: Int?
    var lastAttemptAt: Date?
    var completedAt: Date?
}
