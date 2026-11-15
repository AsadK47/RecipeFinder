import Foundation

/// Abstraction over the importer's network fetch so it can be tested offline with a fake returning canned HTML/redirects/errors.
protocol HTMLFetching: Sendable {
    func fetch(_ request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse)
}

/// Live implementation backed by `URLSession`. Ephemeral, like `URLSessionRemoteImageFetcher`: cookies and cached
/// responses from recipe sites stay in memory for this importer and are never written to disk, so nothing outlives
/// the import (Reset has nothing to clear).
struct URLSessionHTMLFetcher: HTMLFetching {
    let session: URLSession

    init(session: URLSession = URLSession(configuration: .ephemeral)) {
        self.session = session
    }

    func fetch(_ request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw RecipeImportError.invalidResponse
        }
        return (data, http)
    }
}
