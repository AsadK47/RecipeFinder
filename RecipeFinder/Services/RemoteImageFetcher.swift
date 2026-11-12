import Foundation

/// Why a recipe's web picture couldn't be kept; the import itself never fails because of these.
enum RemoteImageError: LocalizedError, Equatable {
    case unsupportedURL
    case badResponse(statusCode: Int)
    case tooLarge
    case notAnImage

    var errorDescription: String? {
        switch self {
        case .unsupportedURL: "The picture's address isn't a web link."
        case .badResponse(let code): "The website answered \(code) for the picture."
        case .tooLarge: "The picture is too large to keep."
        case .notAnImage: "The link isn't a picture."
        }
    }
}

/// Network seam for downloading a recipe's picture, so the localiser is tested offline with a fake.
protocol RemoteImageFetching: Sendable {
    /// Returns the body, throwing `RemoteImageError.tooLarge` as soon as it passes `maxBytes`.
    func fetchImageData(from url: URL, maxBytes: Int) async throws -> Data
}

/// Live fetcher: streams the body so an oversized or lying `Content-Length` response is cut off at the cap.
struct URLSessionRemoteImageFetcher: RemoteImageFetching {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchImageData(from url: URL, maxBytes: Int) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else { throw RemoteImageError.badResponse(statusCode: 0) }
        guard (200..<300).contains(http.statusCode) else {
            throw RemoteImageError.badResponse(statusCode: http.statusCode)
        }
        if http.expectedContentLength > Int64(maxBytes) { throw RemoteImageError.tooLarge }
        var data = Data()
        data.reserveCapacity(Int(max(0, min(http.expectedContentLength, Int64(maxBytes)))))
        for try await byte in bytes {
            data.append(byte)
            if data.count > maxBytes { throw RemoteImageError.tooLarge }
        }
        return data
    }
}
