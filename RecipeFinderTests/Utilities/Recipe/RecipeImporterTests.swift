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
            return (Data(stub.body.utf8), response)
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
}
