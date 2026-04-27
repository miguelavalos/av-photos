import Foundation

enum AVPhotosAPIClientError: LocalizedError {
    case notConfigured
    case authRequired
    case forbidden(String)
    case server(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Hosted sync is not configured."
        case .authRequired:
            "A local auth token is required to call hosted AV Photos endpoints."
        case .forbidden(let message):
            message
        case .server(let message):
            message
        case .invalidResponse:
            "The server response could not be decoded."
        }
    }
}

struct AVPhotosAPIClient {
    let baseURL: URL
    let authToken: String?
    let session: URLSession

    init(
        baseURL: URL = AppConfig.avAppsAPIBaseURL ?? URL(string: "http://127.0.0.1")!,
        authToken: String? = AppConfig.authToken,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.authToken = authToken
        self.session = session
    }

    func fetchHealth() async throws -> HostedHealthResponse {
        try await request(path: "/health", method: "GET", requiresAuth: false)
    }

    func listAssets() async throws -> HostedPhotoAssetListResponse {
        try await request(path: "/v1/apps/avphotos/assets", method: "GET", requiresAuth: true)
    }

    func prepareUpload(
        deviceID: String,
        localIdentifier: String,
        filename: String,
        captureTakenAt: String?,
        byteSize: Int,
        pixelWidth: Int,
        pixelHeight: Int,
        sha256: String
    ) async throws -> PreparedUploadResponse {
        try await request(
            path: "/v1/apps/avphotos/assets/prepare-upload",
            method: "POST",
            requiresAuth: true,
            body: PreparedUploadRequest(
                deviceId: deviceID,
                sourceLocalIdentifier: localIdentifier,
                originalFilename: filename,
                mediaType: "image",
                captureTakenAt: captureTakenAt,
                byteSize: byteSize,
                pixelWidth: pixelWidth,
                pixelHeight: pixelHeight,
                sha256: sha256
            )
        )
    }

    func uploadPreparedAsset(uploadURLPath: String, data: Data) async throws {
        struct EmptyResponse: Decodable {}

        let _: EmptyResponse = try await request(
            path: uploadURLPath,
            method: "PUT",
            requiresAuth: true,
            bodyData: data,
            contentType: "application/octet-stream"
        )
    }

    func commitUpload(
        assetID: String,
        uploadToken: String?,
        deviceID: String
    ) async throws -> CommitUploadResponse {
        guard let uploadToken, !uploadToken.isEmpty else {
            throw AVPhotosAPIClientError.server("Upload token is missing for commit.")
        }

        return try await request(
            path: "/v1/apps/avphotos/assets/commit-upload",
            method: "POST",
            requiresAuth: true,
            body: CommitUploadRequest(
                assetId: assetID,
                uploadToken: uploadToken,
                deviceId: deviceID
            )
        )
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        requiresAuth: Bool,
        bodyData: Data? = nil,
        contentType: String? = nil
    ) async throws -> T {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw AVPhotosAPIClientError.notConfigured
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = bodyData

        if requiresAuth {
            guard let authToken, !authToken.isEmpty else {
                throw AVPhotosAPIClientError.authRequired
            }

            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        if let contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AVPhotosAPIClientError.invalidResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            if let serverError = try? JSONDecoder().decode(HostedErrorResponse.self, from: data) {
                switch httpResponse.statusCode {
                case 401:
                    throw AVPhotosAPIClientError.authRequired
                case 403:
                    throw AVPhotosAPIClientError.forbidden(serverError.error.message)
                default:
                    throw AVPhotosAPIClientError.server(serverError.error.message)
                }
            }

            throw AVPhotosAPIClientError.server("Unexpected server response: \(httpResponse.statusCode)")
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw AVPhotosAPIClientError.invalidResponse
        }
    }

    private func request<T: Decodable, Body: Encodable>(
        path: String,
        method: String,
        requiresAuth: Bool,
        body: Body
    ) async throws -> T {
        let encoder = JSONEncoder()
        let data = try encoder.encode(body)
        return try await request(
            path: path,
            method: method,
            requiresAuth: requiresAuth,
            bodyData: data,
            contentType: "application/json"
        )
    }
}
