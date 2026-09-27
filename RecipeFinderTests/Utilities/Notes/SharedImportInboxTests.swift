import Testing
import Foundation
@testable import RecipeFinder

/// Pure payload-resolution logic of `SharedImportInbox` — precedence of extracted recipe over link over plain text — without touching the App Group `UserDefaults`.
@Suite struct SharedImportInboxTests {

    private static func extracted(_ name: String) -> ExtractedRecipeData {
        ExtractedRecipeData(
            name: name, description: nil, matchedIngredients: [], rawIngredients: ["1 egg"],
            rawText: "1 egg", instructions: ["mix"], sourceURL: URL(string: "https://x.test")!,
            cookTimeMinutes: nil, prepTimeMinutes: nil, servings: nil,
            difficulty: nil, category: nil, cuisine: nil, imageURL: nil
        )
    }

    private static func encoded(_ data: ExtractedRecipeData) throws -> Data {
        try JSONEncoder().encode(data)
    }

    @Test func extractedRecipe_takesPrecedence() throws {
        let payload = SharedImportInbox.resolvePayload(
            recipeData: try Self.encoded(Self.extracted("Soup")),
            urlString: "https://example.com",
            text: "some text"
        )
        guard case let .extracted(data) = payload else {
            Issue.record("expected .extracted, got \(String(describing: payload))")
            return
        }
        #expect(data.name == "Soup")
    }

    @Test func corruptRecipeData_fallsThroughToURL() {
        let payload = SharedImportInbox.resolvePayload(
            recipeData: Data("not a recipe".utf8),
            urlString: "https://example.com",
            text: nil
        )
        #expect(payload == .url("https://example.com"))
    }

    @Test func urlBeatsText_whenNoRecipe() {
        let payload = SharedImportInbox.resolvePayload(
            recipeData: nil, urlString: "https://example.com", text: "text"
        )
        #expect(payload == .url("https://example.com"))
    }

    @Test func textContainingLink_isTreatedAsURL() {
        let payload = SharedImportInbox.resolvePayload(
            recipeData: nil, urlString: nil,
            text: "Check this out https://cooking.test/recipe yum"
        )
        #expect(payload == .url("https://cooking.test/recipe"))
    }

    @Test func plainTextWithNoLink_staysText() {
        let payload = SharedImportInbox.resolvePayload(
            recipeData: nil, urlString: nil, text: "just a plain recipe note"
        )
        #expect(payload == .text("just a plain recipe note"))
    }

    @Test func nothing_returnsNil() {
        #expect(SharedImportInbox.resolvePayload(recipeData: nil, urlString: nil, text: nil) == nil)
    }

    @Test func emptyStrings_returnNil() {
        #expect(SharedImportInbox.resolvePayload(recipeData: nil, urlString: "", text: "") == nil)
    }
}
