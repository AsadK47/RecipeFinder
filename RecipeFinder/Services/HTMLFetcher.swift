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

    /// Reset: clears what recipe sites left this run (the ephemeral session's in-memory jar and cache) and what
    /// builds before the import went ephemeral kept in the app's shared jar and on-disk cache.
    static func clearSharedSessionData(
        cookies: HTTPCookieStorage = .shared,
        cache: URLCache = .shared,
        session: URLSession = URLSessionHTMLFetcher.ephemeralSession
    ) {
        for jar in [cookies, session.configuration.httpCookieStorage].compactMap({ $0 }) {
            jar.removeCookies(since: .distantPast)
        }
        cache.removeAllCachedResponses()
        session.configuration.urlCache?.removeAllCachedResponses()
    }

    func fetch(_ request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RecipeImportError.invalidResponse
        }
        return (data, http)
    }
}
