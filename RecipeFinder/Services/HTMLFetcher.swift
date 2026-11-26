import Foundation

/// Abstraction over the importer's network fetch so it can be tested offline with a fake returning canned HTML/redirects/errors.
protocol HTMLFetching: Sendable {
    func fetch(_ request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse)
}

/// Live implementation backed by `URLSession`. Ephemeral, like `URLSessionRemoteImageFetcher`: cookies and cached
/// responses from recipe sites stay in memory while the app runs and are never written to disk. One session for the
/// app, so connections are reused between imports and refreshes.
/// Streams the body like the picture fetcher, so a huge page or one that drips bytes forever is cut off
/// (`pageTooLarge` / `timedOut`) before it fills memory — the Share extension runs this fetch under a much tighter
/// memory limit than the app.
struct URLSessionHTMLFetcher: HTMLFetching {
    /// Internal (not private) so `HTMLFetcherTests` can check its configuration.
    let session: URLSession
    /// Largest page body kept; recipe pages are well under 2 MB of HTML.
    let maxBytes: Int
    /// Whole-fetch limit. `URLRequest.timeoutInterval` only bounds the gap between packets, so a page that keeps
    /// sending a byte now and then would otherwise never end.
    let totalTimeout: Duration

    static let ephemeralSession = URLSession(configuration: .ephemeral)
    static let defaultMaxBytes = 5 * 1024 * 1024
    static let defaultTotalTimeout: Duration = .seconds(60)

    init(
        session: URLSession = URLSessionHTMLFetcher.ephemeralSession,
        maxBytes: Int = URLSessionHTMLFetcher.defaultMaxBytes,
        totalTimeout: Duration = URLSessionHTMLFetcher.defaultTotalTimeout
    ) {
        self.session = session
        self.maxBytes = maxBytes
        self.totalTimeout = totalTimeout
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
        let limit = totalTimeout
        return try await withThrowingTaskGroup(of: (data: Data, response: HTTPURLResponse).self) { group in
            group.addTask { try await readCapped(request) }
            group.addTask {
                try await Task.sleep(for: limit)
                throw RecipeImportError.timedOut
            }
            defer { group.cancelAll() }
            guard let first = try await group.next() else { throw RecipeImportError.invalidResponse }
            return first
        }
    }

    /// Reads the body as it arrives, throwing `pageTooLarge` as soon as it passes `maxBytes` (or when the declared
    /// `Content-Length` already does). Non-2xx bodies are read too, so callers see the status unchanged.
    private func readCapped(_ request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse) {
        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RecipeImportError.invalidResponse
        }
        if http.expectedContentLength > Int64(maxBytes) { throw RecipeImportError.pageTooLarge }
        var data = Data()
        data.reserveCapacity(Int(max(0, min(http.expectedContentLength, Int64(maxBytes)))))
        for try await byte in bytes {
            data.append(byte)
            if data.count > maxBytes { throw RecipeImportError.pageTooLarge }
        }
        return (data, http)
    }
}
