import Foundation

/// Abstraction over the importer's network fetch so it can be tested offline with a fake returning canned HTML/redirects/errors.
protocol HTMLFetching: Sendable {
    func fetch(_ request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse)
}

/// Live implementation backed by `URLSession`. Ephemeral, like `URLSessionRemoteImageFetcher`: cookies and cached
/// responses from recipe sites stay in memory while the app runs and are never written to disk. One session for the
/// app, so connections are reused between imports and refreshes.
struct URLSessionHTMLFetcher: HTMLFetching {
    /// Internal (not private) so `HTMLFetcherTests` can check its configuration.
    let session: URLSession

    static let ephemeralSession = URLSession(configuration: .ephemeral)

    init(session: URLSession = URLSessionHTMLFetcher.ephemeralSession) {
        self.session = session
    }

    /// Reset: builds before the import went ephemeral kept recipe sites' cookies and cached pages in the app's
    /// shared jar and on-disk cache; nothing else in the app uses them.
    static func clearSharedSessionData(
        cookies: HTTPCookieStorage = .shared,
        cache: URLCache = .shared
    ) {
        cookies.removeCookies(since: .distantPast)
        cache.removeAllCachedResponses()
    }

    func fetch(_ request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RecipeImportError.invalidResponse
        }
        return (data, http)
    }
}
