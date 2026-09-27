import Testing
import Foundation
@testable import RecipeFinder

/// `URLSessionHTMLFetcher` (the live `HTMLFetching`) on the real URLSession path, with a `URLProtocol` stub intercepting every request so no network is needed.
/// `.serialized` is required because `StubURLProtocol` holds its canned response in a `static var` shared across URLProtocol instances.
@Suite("URLSessionHTMLFetcher", .serialized)
struct HTMLFetcherTests {

    // MARK: - URLProtocol stub

    /// Intercepts all URLSession requests and returns a canned response so
    /// `URLSessionHTMLFetcher` can be exercised without hitting the network.
    final class StubURLProtocol: URLProtocol, @unchecked Sendable {
        struct Stub {
            var statusCode: Int = 200
            var headers: [String: String] = [:]
            var body: Data = Data()
            var error: Error?
        }

        nonisolated(unsafe) static var current = Stub()

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            if let error = Self.current.error {
                client?.urlProtocol(self, didFailWithError: error)
                return
            }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: Self.current.statusCode,
                httpVersion: nil,
                headerFields: Self.current.headers
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Self.current.body)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    // MARK: - Helper

    private func makeFetcher() -> URLSessionHTMLFetcher {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSessionHTMLFetcher(session: URLSession(configuration: config))
    }

    // MARK: - Tests

    @Test("200 response returns body data and an HTTPURLResponse")
    func okResponseReturnsDataAndResponse() async throws {
        let expected = Data("hello".utf8)
        StubURLProtocol.current = .init(statusCode: 200, body: expected)
        let fetcher = makeFetcher()

        let (data, response) = try await fetcher.fetch(URLRequest(url: URL(string: "https://example.com")!))

        #expect(response.statusCode == 200)
        #expect(data == expected)
    }

    @Test("Non-200 status codes pass through unchanged")
    func nonOkStatusCodePassesThrough() async throws {
        StubURLProtocol.current = .init(statusCode: 503)
        let fetcher = makeFetcher()

        let (_, response) = try await fetcher.fetch(URLRequest(url: URL(string: "https://example.com")!))

        #expect(response.statusCode == 503)
    }

    @Test("Large body is returned without truncation")
    func largeBodyReturnedIntact() async throws {
        let large = Data(repeating: 0xAB, count: 100_000)
        StubURLProtocol.current = .init(statusCode: 200, body: large)
        let fetcher = makeFetcher()

        let (data, _) = try await fetcher.fetch(URLRequest(url: URL(string: "https://example.com")!))

        #expect(data == large)
    }

    @Test("URLSession error propagates without wrapping")
    func networkErrorPropagates() async {
        StubURLProtocol.current = .init(error: URLError(.notConnectedToInternet))
        let fetcher = makeFetcher()

        await #expect(throws: URLError.self) {
            _ = try await fetcher.fetch(URLRequest(url: URL(string: "https://example.com")!))
        }
    }

    @Test("Response URL matches the request URL")
    func responseURLMatchesRequest() async throws {
        let url = URL(string: "https://example.com/recipe/pancakes")!
        StubURLProtocol.current = .init(statusCode: 200, body: Data("body".utf8))
        let fetcher = makeFetcher()

        let (_, response) = try await fetcher.fetch(URLRequest(url: url))

        #expect(response.url == url)
    }
}
