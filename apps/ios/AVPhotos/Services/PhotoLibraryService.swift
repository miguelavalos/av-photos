import CryptoKit
import Foundation
import Photos

struct LocalPhotoUploadPayload {
    let asset: LocalPhotoAsset
    let data: Data
    let captureTakenAt: String?
    let sha256: String
}

enum PhotoLibraryServiceError: LocalizedError {
    case assetNotFound
    case imageDataUnavailable

    var errorDescription: String? {
        switch self {
        case .assetNotFound:
            "The local photo asset could not be found."
        case .imageDataUnavailable:
            "The selected asset did not return image data."
        }
    }
}

struct PhotoLibraryService {
    func fetchRecentAssets(limit: Int = 24) -> [LocalPhotoAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = limit

        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [LocalPhotoAsset] = []

        fetchResult.enumerateObjects { asset, _, _ in
            let filename = PHAssetResource.assetResources(for: asset).first?.originalFilename ?? "Image"
            assets.append(
                LocalPhotoAsset(
                    localIdentifier: asset.localIdentifier,
                    filename: filename,
                    creationDate: asset.creationDate,
                    pixelWidth: asset.pixelWidth,
                    pixelHeight: asset.pixelHeight
                )
            )
        }

        return assets
    }

    func fetchUploadPayload(for localIdentifier: String) async throws -> LocalPhotoUploadPayload {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else {
            throw PhotoLibraryServiceError.assetNotFound
        }

        let filename = PHAssetResource.assetResources(for: asset).first?.originalFilename ?? "Image"
        let data = try await requestImageData(for: asset)

        return LocalPhotoUploadPayload(
            asset: LocalPhotoAsset(
                localIdentifier: asset.localIdentifier,
                filename: filename,
                creationDate: asset.creationDate,
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight
            ),
            data: data,
            captureTakenAt: asset.creationDate.map(Self.isoString),
            sha256: Self.sha256Hex(for: data)
        )
    }

    private func requestImageData(for asset: PHAsset) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                guard let data else {
                    continuation.resume(throwing: PhotoLibraryServiceError.imageDataUnavailable)
                    return
                }

                continuation.resume(returning: data)
            }
        }
    }

    private static func sha256Hex(for data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func isoString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
