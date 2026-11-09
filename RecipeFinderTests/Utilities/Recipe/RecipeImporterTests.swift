import Testing
import Foundation
@testable import RecipeFinder

@MainActor
@Suite("RecipeImporter")
struct RecipeImporterTests {

    // MARK: - Fake fetcher

    /// A canned `HTMLFetching` keyed by absolute URL string, so tests can
    /// script status codes, redirects, and response bodies with no network.
    struct FakeFetcher: HTMLFetching {
        struct Stub {
            var status: Int = 200
            var headers: [String: String] = [:]
            var body: String = ""
            /// Raw bytes to return verbatim; when set, overrides `body` so tests can
            /// script non-UTF-8 payloads (e.g. ISO-8859-1 recipe blogs).
            var bodyData: Data? = nil
        }

        let stubs: [String: Stub]

        func fetch(_ request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse) {
            let key = request.url?.absoluteString ?? ""
            guard let stub = stubs[key] else {
                throw RecipeImporter.ImportError.invalidResponse
            }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: stub.status,
                httpVersion: nil,
                headerFields: stub.headers
            )!
            return (stub.bodyData ?? Data(stub.body.utf8), response)
        }
    }

    // MARK: - Fixtures

    private static let validRecipeHTML = """
    <html><head>
    <script type="application/ld+json">
    {"@context":"https://schema.org","@type":"Recipe","name":"Test Pancakes",
     "recipeIngredient":["1 cup flour","2 eggs"],
     "recipeInstructions":[{"@type":"HowToStep","text":"Mix the ingredients"},
                           {"@type":"HowToStep","text":"Cook on a griddle"}]}
    </script></head><body></body></html>
    """

    /// An accented recipe that can be encoded as ISO-8859-1 (no chars outside
    /// Latin-1, so `data(using: .isoLatin1)` succeeds).
    private static let latin1RecipeHTML = """
    <html><head>
    <script type="application/ld+json">
    {"@context":"https://schema.org","@type":"Recipe","name":"Crème Brûlée",
     "recipeIngredient":["200 ml crème fraîche","1 pincée de sel"],
     "recipeInstructions":[{"@type":"HowToStep","text":"Mélanger"}]}
    </script></head><body></body></html>
    """

    private func makeImporter(
        stubs: [String: FakeFetcher.Stub],
        networkAvailable: Bool = true
    ) -> RecipeImporter {
        RecipeImporter(
            fetcher: FakeFetcher(stubs: stubs),
            isNetworkAvailable: { networkAvailable }
        )
    }

    // MARK: - importRecipe (observable state)

    @Test("Successful import publishes extracted data and clears loading")
    func successfulImportPublishesData() async {
        let url = URL(string: "https://example.com/pancakes")!
        let importer = makeImporter(stubs: [url.absoluteString: .init(body: Self.validRecipeHTML)])

        await importer.importRecipe(from: url)

        #expect(importer.extractedData?.name == "Test Pancakes")
        #expect(importer.extractedData?.rawIngredients == ["1 cup flour", "2 eggs"])
        #expect(importer.errorMessage == nil)
        #expect(importer.isLoading == false)
        #expect(importer.parseConfidence > 0)
    }

    @Test("Offline import sets the network error and extracts nothing")
    func offlineImportSetsError() async {
        let url = URL(string: "https://example.com/pancakes")!
        let importer = makeImporter(
            stubs: [url.absoluteString: .init(body: Self.validRecipeHTML)],
            networkAvailable: false
        )

        await importer.importRecipe(from: url)

        #expect(importer.extractedData == nil)
        #expect(importer.errorMessage == AppError.networkUnavailable.localizedDescription)
        #expect(importer.isLoading == false)
    }

    @Test("A server error surfaces the invalid-response message")
    func serverErrorSurfacesMessage() async {
        let url = URL(string: "https://example.com/boom")!
        let importer = makeImporter(stubs: [url.absoluteString: .init(status: 500)])

        await importer.importRecipe(from: url)

        #expect(importer.extractedData == nil)
        #expect(importer.errorMessage == RecipeImporter.ImportError.invalidResponse.errorDescription)
    }

    // MARK: - fetchAndParse (pure core)

    @Test("fetchAndParse returns the parsed recipe and confidence")
    func fetchAndParseReturnsOutcome() async throws {
        let url = URL(string: "https://example.com/pancakes")!
        let importer = makeImporter(stubs: [url.absoluteString: .init(body: Self.validRecipeHTML)])

        let outcome = try await importer.fetchAndParse(from: url)

        #expect(outcome.data.name == "Test Pancakes")
        #expect(outcome.confidence > 0)
    }

    @Test("fetchAndParse decodes a non-UTF-8 (ISO-8859-1) page instead of failing")
    func fetchAndParseDecodesLatin1() async throws {
        let url = URL(string: "https://example.com/creme")!
        let data = Self.latin1RecipeHTML.data(using: .isoLatin1)!
        // Sanity: these bytes are not valid UTF-8, so the old strict decode failed here.
        #expect(String(data: data, encoding: .utf8) == nil)

        let importer = makeImporter(stubs: [url.absoluteString: .init(
            headers: ["Content-Type": "text/html; charset=iso-8859-1"],
            bodyData: data
        )])

        let outcome = try await importer.fetchAndParse(from: url)

        #expect(outcome.data.name == "Crème Brûlée")
        #expect(outcome.data.rawIngredients.contains { $0.contains("crème fraîche") })
    }

    @Test("fetchAndParse follows a redirect to the final page")
    func fetchAndParseFollowsRedirect() async throws {
        let start = URL(string: "https://example.com/old")!
        let destination = URL(string: "https://example.com/new")!
        let importer = makeImporter(stubs: [
            start.absoluteString: .init(status: 301, headers: ["Location": destination.absoluteString]),
            destination.absoluteString: .init(body: Self.validRecipeHTML),
        ])

        let outcome = try await importer.fetchAndParse(from: start)

        #expect(outcome.data.name == "Test Pancakes")
    }

    @Test("fetchAndParse follows a 308 (permanent) redirect")
    func fetchAndParseFollows308() async throws {
        let start = URL(string: "https://example.com/moved")!
        let destination = URL(string: "https://example.com/final")!
        let importer = makeImporter(stubs: [
            start.absoluteString: .init(status: 308, headers: ["Location": destination.absoluteString]),
            destination.absoluteString: .init(body: Self.validRecipeHTML),
        ])

        let outcome = try await importer.fetchAndParse(from: start)

        #expect(outcome.data.name == "Test Pancakes")
    }

    @Test("fetchAndParse gives up after too many redirects")
    func fetchAndParseTooManyRedirects() async {
        let loop = URL(string: "https://example.com/loop")!
        let importer = makeImporter(stubs: [
            loop.absoluteString: .init(status: 301, headers: ["Location": loop.absoluteString]),
        ])

        await #expect(throws: RecipeImporter.ImportError.tooManyRedirects) {
            _ = try await importer.fetchAndParse(from: loop)
        }
    }

    @Test("fetchAndParse throws when the page has no recipe name")
    func fetchAndParseMissingName() async {
        let url = URL(string: "https://example.com/empty")!
        let importer = makeImporter(stubs: [url.absoluteString: .init(body: "<html><body>nothing here</body></html>")])

        await #expect(throws: RecipeImporter.ImportError.self) {
            _ = try await importer.fetchAndParse(from: url)
        }
    }

    // MARK: - Page text kept for re-import (Import 1/5)

    @Test("link import keeps the page's readable text, without scripts")
    func linkImportKeepsPageText() async throws {
        let url = try #require(URL(string: "https://example.com/pancakes"))
        let html = Self.validRecipeHTML.replacingOccurrences(
            of: "<body></body>", with: "<body><h1>Test Pancakes</h1><p>Grandma's Sunday batch.</p></body>"
        )
        let importer = makeImporter(stubs: [url.absoluteString: .init(body: html)])
        await importer.importRecipe(from: url)

        let pageText = try #require(importer.extractedData?.pageText)
        #expect(pageText.contains("Grandma's Sunday batch."))
        #expect(!pageText.contains("@context"))
    }

    @Test("the built recipe stores the page text as its original import text")
    func builtRecipeCarriesPageText() async throws {
        let url = try #require(URL(string: "https://example.com/pancakes"))
        let html = Self.validRecipeHTML.replacingOccurrences(of: "<body></body>", with: "<body><p>Fluffy.</p></body>")
        let importer = makeImporter(stubs: [url.absoluteString: .init(body: html)])
        await importer.importRecipe(from: url)

        let data = try #require(importer.extractedData)
        #expect(RecipeImportBuilder().build(from: data).sourceText == data.pageText)
    }

    @Test("page text is capped without splitting a character", arguments: [10, 11, 50_000])
    func pageTextIsCapped(limit: Int) {
        let html = "<p>" + String(repeating: "é", count: 40_000) + "</p>"   // 2 UTF-8 bytes per é
        let text = RecipeImportPipeline.pageText(fromHTML: html, limit: limit)
        #expect(text.utf8.count <= limit)
        #expect(text.allSatisfy { $0 == "é" })
    }

    @Test("short page text is kept whole")
    func shortPageTextIsWhole() {
        #expect(RecipeImportPipeline.pageText(fromHTML: "<p>Hello</p>", limit: 50_000) == "Hello")
    }
}
