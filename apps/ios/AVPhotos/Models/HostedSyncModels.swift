import Foundation

struct HostedHealthResponse: Decodable {
    let ok: Bool
    let environment: String?
}

struct HostedPhotoAsset: Decodable, Identifiable {
    let assetId: String
    let deviceId: String
    let sourceLocalIdentifier: String
    let originalFilename: String
    let mediaType: String
    let captureTakenAt: String?
    let importedAt: String
    let pixelWidth: Int
    let pixelHeight: Int
    let byteSize: Int
    let sha256: String
    let storageKeyOriginal: String
    let syncStatus: String
    let deletedAt: String?
    let updatedAt: String

    var id: String { assetId }
}

struct HostedPhotoAssetListResponse: Decodable {
    let assets: [HostedPhotoAsset]
    let generatedAt: String
}

struct HostedPhotoAssetChangesResponse: Decodable {
    let changes: [HostedPhotoAsset]
    let cursor: String?
    let generatedAt: String
}

struct PreparedUploadRequest: Encodable {
    let deviceId: String
    let sourceLocalIdentifier: String
    let originalFilename: String
    let mediaType: String
    let captureTakenAt: String?
    let byteSize: Int
    let pixelWidth: Int
    let pixelHeight: Int
    let sha256: String
}

struct PreparedUploadResponse: Decodable {
    let assetId: String
    let uploadJobId: String?
    let uploadToken: String?
    let uploadUrl: String?
    let storageKey: String
    let shouldUpload: Bool
    let assetAlreadyExists: Bool
    let preparedAt: String
}

struct CommitUploadRequest: Encodable {
    let assetId: String
    let uploadToken: String
    let deviceId: String
}

struct CommitUploadResponse: Decodable {
    let asset: HostedPhotoAsset
    let committedAt: String
}

struct DeleteHostedAssetResponse: Decodable {
    let assetId: String
    let deleted: Bool
    let deletedAt: String
}

struct HostedErrorResponse: Decodable {
    struct ErrorPayload: Decodable {
        let code: String
        let message: String
    }

    let error: ErrorPayload
}
