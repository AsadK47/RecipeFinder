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

/// Queue behaviour against an isolated, throwaway `UserDefaults` suite (never the real App Group).
@Suite struct SharedImportInboxQueueTests {

    private static func freshDefaults() -> UserDefaults? {
        UserDefaults(suiteName: "SharedImportInboxQueueTests.\(UUID().uuidString)")
    }

    private static func extracted(_ name: String, ingredients: [String] = ["1 egg"], steps: [String] = ["mix"]) -> ExtractedRecipeData {
        ExtractedRecipeData(
            name: name, description: nil, matchedIngredients: [], rawIngredients: ingredients,
            rawText: "1 egg", instructions: steps, sourceURL: URL(string: "https://x.test")!,
            cookTimeMinutes: nil, prepTimeMinutes: nil, servings: nil,
            difficulty: nil, category: nil, cuisine: nil, imageURL: nil
        )
    }

    @Test func secondShareDoesNotOverwriteFirst() {
        let defaults = Self.freshDefaults()
        SharedImportInbox.storeURL("https://a.test", in: defaults)
        SharedImportInbox.storeURL("https://b.test", in: defaults)
        #expect(SharedImportInbox.consumePayloads(from: defaults) == [.url("https://a.test"), .url("https://b.test")])
    }

    @Test func keepsOrderAcrossKinds() {
        let defaults = Self.freshDefaults()
        SharedImportInbox.storeExtractedRecipe(Self.extracted("Soup"), in: defaults)
        SharedImportInbox.storeText("2 eggs, whisk", in: defaults)
        SharedImportInbox.storeText("see https://c.test/recipe", in: defaults)
        #expect(SharedImportInbox.consumePayloads(from: defaults) == [
            .extracted(Self.extracted("Soup")), .text("2 eggs, whisk"), .url("https://c.test/recipe"),
        ])
    }

    @Test func consumingEmptiesTheInbox() {
        let defaults = Self.freshDefaults()
        SharedImportInbox.storeURL("https://a.test", in: defaults)
        _ = SharedImportInbox.consumePayloads(from: defaults)
        #expect(SharedImportInbox.consumePayloads(from: defaults).isEmpty)
    }

    @Test func drainsLegacySingleSlotBeforeQueue() {
        let defaults = Self.freshDefaults()
        defaults?.set("https://old.test", forKey: "pendingSharedImportURL")
        SharedImportInbox.storeURL("https://new.test", in: defaults)
        #expect(SharedImportInbox.consumePayloads(from: defaults) == [.url("https://old.test"), .url("https://new.test")])
    }

    @Test func missingAppGroupStoresNothing() {
        #expect(SharedImportInbox.storeExtractedRecipe(Self.extracted("Soup"), in: nil) == false)
        #expect(SharedImportInbox.consumePayloads(from: nil).isEmpty)
    }

    @Test(arguments: [
        (["1 egg"], ["mix"], true),
        ([], ["mix"], false),
        (["1 egg"], [], false),
    ])
    func onlyCompleteRecipesAreHandedOverAsSaved(ingredients: [String], steps: [String], expected: Bool) {
        #expect(SharedImportInbox.isCompleteRecipe(Self.extracted("Soup", ingredients: ingredients, steps: steps)) == expected)
    }
}
