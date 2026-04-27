import Foundation

struct HostedHealthResponse: Decodable {
    let status: String
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

struct HostedErrorResponse: Decodable {
    struct ErrorPayload: Decodable {
        let code: String
        let message: String
    }

    let error: ErrorPayload
}
