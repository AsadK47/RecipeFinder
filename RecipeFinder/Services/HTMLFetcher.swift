import Foundation

/// Abstraction over the importer's network fetch so it can be tested offline with a fake returning canned HTML/redirects/errors.
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
