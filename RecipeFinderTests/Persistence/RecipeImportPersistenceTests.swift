import Testing
import Foundation
@testable import RecipeFinder

/// Integration across the import → persistence seam: a page parsed by the real
/// pipeline, built into a `RecipeModel`, saved to the Core Data store, and
/// fetched back — proving the handoff (builder mapping + Core Data
/// encode/decode of ingredients and step arrays) preserves the recipe.
@MainActor
@Suite struct RecipeImportPersistenceTests {

    /// Canned fetcher returning one page for one URL (no network).
    private struct FakeFetcher: HTMLFetching {
        let url: String
        let body: String

        func fetch(_ request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse) {
            guard request.url?.absoluteString == url else {
                throw RecipeImportError.invalidResponse
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: [:])!
            return (Data(body.utf8), response)
        }
    }

    @Test func importedWebRecipeSavesAndReloadsIntact() async throws {
        let source = "https://example.com/garlic-butter-chicken"
        let url = try #require(URL(string: source))
        let pipeline = RecipeImportPipeline(fetcher: FakeFetcher(url: source, body: RecipeHTMLFixtures.modernWordPressBlog))
        let controller = PersistenceController(inMemory: true, userID: { "userA" })
        #expect(controller.isStoreLoaded)

        // Parse → build → persist.
        let outcome = try await pipeline.fetchAndParse(from: url)
        let built = RecipeImportBuilder().build(from: outcome.data)
        controller.saveRecipeModel(built)

        // Reload from the store and prove the recipe survived the round trip.
        let fetched = controller.fetchRecipes()
        #expect(fetched.count == 1)
        let stored = try #require(fetched.first)
        #expect(stored.name == "Garlic Butter Chicken")
        #expect(stored.baseServings == 4)
        #expect(stored.ingredients.count == 5)
        #expect(stored.instructions.count == 3)
        #expect(stored.instructions.first?.contains("Pat the chicken dry") == true)
        // buildNotes stamps the source URL and description into notes.
        #expect(stored.notes.contains(source))
        #expect(stored.notes.contains("Juicy pan-seared"))
    }

    // MARK: - mergeRecipes duplicate detection

    @Test func mergeRecipes_withSameId_doesNotDuplicate() {
        let controller = PersistenceController(inMemory: true, userID: { "userA" })
        let id = UUID()
        controller.saveRecipeModel(recipe("Soup", id: id))

        controller.mergeRecipes([recipe("Soup Renamed", id: id)])

        let all = controller.fetchRecipes()
        #expect(all.count == 1)
        #expect(all.first?.name == "Soup")   // original preserved
    }

    @Test func mergeRecipes_withSameName_doesNotDuplicate() {
        let controller = PersistenceController(inMemory: true, userID: { "userA" })
        controller.saveRecipeModel(recipe("Chicken Soup"))

        // Different UUID but same normalised name — should be suppressed.
        controller.mergeRecipes([recipe("  chicken soup  ")])

        #expect(controller.fetchRecipes().count == 1)
        #expect(controller.fetchRecipes().first?.name == "Chicken Soup")
    }

    @Test func mergeRecipes_withGenuinelyNewRecipes_addsAll() {
        let controller = PersistenceController(inMemory: true, userID: { "userA" })
        controller.saveRecipeModel(recipe("Soup"))

        controller.mergeRecipes([recipe("Stew"), recipe("Pie")])

        #expect(controller.fetchRecipes().count == 3)
    }

    @Test func mergeRecipes_doesNotModifyExistingRecipeFields() {
        let controller = PersistenceController(inMemory: true, userID: { "userA" })
        let id = UUID()
        controller.saveRecipeModel(recipe("Lasagne", id: id))

        // Same id with a different name: merge must leave the existing record alone.
        controller.mergeRecipes([recipe("Lasagne Updated", id: id)])

        let fetched = controller.fetchRecipes().first { $0.id == id }
        #expect(fetched?.name == "Lasagne")
    }

    @Test func mergeRecipes_intoEmptyStore_savesAll() {
        let controller = PersistenceController(inMemory: true, userID: { "userA" })

        controller.mergeRecipes([recipe("A"), recipe("B"), recipe("C")])

        #expect(controller.fetchRecipes().count == 3)
    }

    private func recipe(_ name: String, id: UUID = UUID()) -> RecipeModel {
        RecipeModel(
            id: id,
            name: name,
            category: "Main",
            difficulty: "Basic",
            prepTime: "5 minutes",
            cookingTime: "10 minutes",
            baseServings: 2,
            ingredients: [],
            prePrepInstructions: [],
            instructions: ["Cook"],
            notes: "",
            isFavorite: false
        )
    }
}
