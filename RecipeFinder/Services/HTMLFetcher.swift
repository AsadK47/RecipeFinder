import Foundation

/// Abstraction over the network fetch used by the recipe importer.
///
/// Injecting this (rather than reaching for `URLSession.shared` directly) lets
/// the importer be tested offline with a fake that returns canned HTML,
/// redirects, or errors.
protocol HTMLFetching: Sendable {
    func fetch(_ request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse)
}

/// Live implementation backed by `URLSession`.
struct URLSessionHTMLFetcher: HTMLFetching {
    private let session: URLSession

    init(session: URLSession = .shared) {
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
