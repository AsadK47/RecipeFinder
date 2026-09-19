import Foundation

private let logger = AppLogger.logger(category: "UnsplashClient")

/// Fetches a landscape food photo URL from the Unsplash API by keyword.
///
/// Set `UnsplashAccessKey` in `Info.plist` (or via an xcconfig variable) to enable.
/// When the key is absent or empty the client is a no-op and returns `nil` silently —
/// the rest of the app degrades gracefully (placeholder images remain visible).
struct UnsplashClient {

    private static let apiKey: String = {
        Bundle.main.object(forInfoDictionaryKey: "UnsplashAccessKey") as? String ?? ""
    }()

    /// Returns the `regular`-size image URL for a photo matching `query`.
    /// Returns `nil` on any failure (missing key, network error, no results).
    func fetchImageURL(for query: String) async -> URL? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !Self.apiKey.isEmpty, !trimmed.isEmpty else { return nil }

        var components = URLComponents(string: "https://api.unsplash.com/photos/random")!
        components.queryItems = [
            URLQueryItem(name: "query", value: trimmed),
            URLQueryItem(name: "orientation", value: "landscape"),
            URLQueryItem(name: "content_filter", value: "high"),
        ]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        request.setValue("Client-ID \(Self.apiKey)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let photo = try JSONDecoder().decode(UnsplashPhotoResponse.self, from: data)
            return URL(string: photo.urls.regular)
        } catch {
            logger.error("Unsplash fetch failed for '\(trimmed)': \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Response model

private struct UnsplashPhotoResponse: Decodable {
    struct Urls: Decodable {
        let regular: String
    }
    let urls: Urls
}
