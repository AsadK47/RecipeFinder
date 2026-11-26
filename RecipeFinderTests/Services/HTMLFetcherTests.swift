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
            /// Sends the response, then one byte every 20 ms until the request is cancelled (a page that never ends).
            var drip = false
        }

        private var dripTimer: DispatchSourceTimer?

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
            if Self.current.drip {
                let timer = DispatchSource.makeTimerSource(queue: .global())
                timer.schedule(deadline: .now(), repeating: .milliseconds(20))
                timer.setEventHandler { [weak self] in
                    guard let self else { return }
                    self.client?.urlProtocol(self, didLoad: Data("a".utf8))
                }
                dripTimer = timer
                timer.resume()
                return
            }
            client?.urlProtocol(self, didLoad: Self.current.body)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {
            dripTimer?.cancel()
            dripTimer = nil
        }
    }

    // MARK: - Helper

    private func makeFetcher(
        maxBytes: Int = URLSessionHTMLFetcher.defaultMaxBytes,
        totalTimeout: Duration = URLSessionHTMLFetcher.defaultTotalTimeout
    ) -> URLSessionHTMLFetcher {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSessionHTMLFetcher(
            session: URLSession(configuration: config), maxBytes: maxBytes, totalTimeout: totalTimeout
        )
    }

    private let pageURL = URL(string: "https://example.com/recipe")

    // MARK: - Resource limits (a huge or never-ending page must not fill memory, least of all in the Share extension)

    @Test("By default a page is capped at 5 MB and the whole fetch at 60 seconds")
    func defaultLimits() {
        let fetcher = URLSessionHTMLFetcher()

        #expect(fetcher.maxBytes == 5 * 1024 * 1024)
        #expect(fetcher.totalTimeout == .seconds(60))
    }

    @Test("A body one byte over the cap is cut off as too large")
    func bodyOverCapThrowsPageTooLarge() async throws {
        StubURLProtocol.current = .init(statusCode: 200, body: Data(repeating: 0x61, count: 1_001))
        let fetcher = makeFetcher(maxBytes: 1_000)
        let url = try #require(pageURL)

        await #expect(throws: RecipeImportError.pageTooLarge) {
            _ = try await fetcher.fetch(URLRequest(url: url))
        }
    }

    @Test("A declared Content-Length over the cap is refused before reading the body")
    func declaredLengthOverCapThrowsPageTooLarge() async throws {
        StubURLProtocol.current = .init(
            statusCode: 200, headers: ["Content-Length": "999999999"], body: Data("tiny".utf8)
        )
        let fetcher = makeFetcher(maxBytes: 1_000)
        let url = try #require(pageURL)

        await #expect(throws: RecipeImportError.pageTooLarge) {
            _ = try await fetcher.fetch(URLRequest(url: url))
        }
    }

    @Test("A body exactly at the cap is returned whole")
    func bodyAtCapIsReturned() async throws {
        let body = Data(repeating: 0x61, count: 1_000)
        StubURLProtocol.current = .init(statusCode: 200, body: body)
        let fetcher = makeFetcher(maxBytes: 1_000)
        let url = try #require(pageURL)

        let (data, _) = try await fetcher.fetch(URLRequest(url: url))

        #expect(data == body)
    }

    @Test("A page that keeps sending a byte now and then times out as a whole", .timeLimit(.minutes(1)))
    func drippingPageTimesOut() async throws {
        StubURLProtocol.current = .init(statusCode: 200, drip: true)
        let fetcher = makeFetcher(totalTimeout: .milliseconds(500))
        let url = try #require(pageURL)

        await #expect(throws: RecipeImportError.timedOut) {
            _ = try await fetcher.fetch(URLRequest(url: url))
        }
    }

    @Test("A quick page returns at once, without waiting for the whole-fetch limit", .timeLimit(.minutes(1)))
    func quickPageDoesNotWaitForTimeout() async throws {
        StubURLProtocol.current = .init(statusCode: 200, body: Data("page".utf8))
        let fetcher = makeFetcher(totalTimeout: .seconds(600))
        let url = try #require(pageURL)

        let (data, _) = try await fetcher.fetch(URLRequest(url: url))

        #expect(data == Data("page".utf8))
    }

    @Test("A stalled connection reads as the same timeout the cook can act on")
    func idleTimeoutBecomesTimedOut() async throws {
        StubURLProtocol.current = .init(error: URLError(.timedOut))
        let fetcher = makeFetcher()
        let url = try #require(pageURL)

        await #expect(throws: RecipeImportError.timedOut) {
            _ = try await fetcher.fetch(URLRequest(url: url))
        }
    }

    @Test("Both limits tell the cook to paste the recipe text instead", arguments: [
        RecipeImportError.pageTooLarge, .timedOut
    ])
    func limitMessagesOfferPasting(_ error: RecipeImportError) throws {
        let message = try #require(error.errorDescription)

        #expect(message.contains("paste the text"))
    }

    // MARK: - Tests

    @Test("By default nothing a recipe site sets is kept: no shared cookie jar, no on-disk cache")
    func defaultSessionKeepsNoCookiesOrCacheOnDisk() {
        let configuration = URLSessionHTMLFetcher().session.configuration

        #expect(configuration.httpCookieStorage !== HTTPCookieStorage.shared)
        #expect(configuration.urlCache !== URLCache.shared)
        #expect((configuration.urlCache?.diskCapacity ?? 0) == 0)
    }

    @Test("Reset clears cookies and pages recipe sites left, this run and from older builds")
    func clearingSharedSessionDataEmptiesTheCache() throws {
        let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0, directory: nil)
        let url = try #require(URL(string: "https://example.com/recipe"))
        let request = URLRequest(url: url)
        let response = try #require(HTTPURLResponse(
            url: url, statusCode: 200, httpVersion: nil, headerFields: nil
        ))
        cache.storeCachedResponse(CachedURLResponse(response: response, data: Data("page".utf8)), for: request)
        #expect(cache.cachedResponse(for: request) != nil)
        let jar = try #require(URLSessionConfiguration.ephemeral.httpCookieStorage)
        let cookie = try #require(HTTPCookie(properties: [
            .name: "consent", .value: "yes", .domain: "example.com", .path: "/"
        ]))
        jar.setCookie(cookie)
        #expect(jar.cookies?.isEmpty == false)
        let session = URLSession(configuration: .ephemeral)
        let sessionJar = try #require(session.configuration.httpCookieStorage)
        sessionJar.setCookie(cookie)
        #expect(sessionJar.cookies?.isEmpty == false)

        URLSessionHTMLFetcher.clearSharedSessionData(cookies: jar, cache: cache, session: session)

        #expect(cache.cachedResponse(for: request) == nil)
        #expect(jar.cookies?.isEmpty != false)
        #expect(sessionJar.cookies?.isEmpty != false)
    }

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
