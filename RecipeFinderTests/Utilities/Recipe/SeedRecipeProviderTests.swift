import Testing
import Foundation
@testable import RecipeFinder

@Suite("SeedRecipeProvider")
struct SeedRecipeProviderTests {

    // MARK: - Count & completeness

    @Test("recipe count is exactly 6")
    func recipeCount() {
        #expect(SeedRecipeProvider.recipes.count == 6)
    }

    @Test("all recipes are marked isSampleRecipe", arguments: SeedRecipeProvider.recipes)
    func allMarkedSample(recipe: RecipeModel) {
        #expect(recipe.isSampleRecipe)
    }

    @Test("all recipes have a non-empty name", arguments: SeedRecipeProvider.recipes)
    func nonEmptyName(recipe: RecipeModel) {
        #expect(!recipe.name.isEmpty)
    }

    @Test("all recipes have at least one instruction", arguments: SeedRecipeProvider.recipes)
    func hasInstructions(recipe: RecipeModel) {
        #expect(!recipe.instructions.isEmpty)
    }

    @Test("all recipes have at least one ingredient", arguments: SeedRecipeProvider.recipes)
    func hasIngredients(recipe: RecipeModel) {
        #expect(!recipe.ingredients.isEmpty)
    }

    @Test("all recipes have a positive baseServings", arguments: SeedRecipeProvider.recipes)
    func positiveServings(recipe: RecipeModel) {
        #expect(recipe.baseServings > 0)
    }

    // MARK: - Stable UUIDs

    @Test("all UUIDs carry the 5EED0001 seed prefix", arguments: SeedRecipeProvider.recipes)
    func seedUUIDPrefix(recipe: RecipeModel) {
        #expect(recipe.id.uuidString.hasPrefix("5EED0001"))
    }

    @Test("all UUIDs are unique")
    func uniqueUUIDs() {
        let ids = SeedRecipeProvider.recipes.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("UUIDs are stable across successive accesses")
    func stableUUIDs() {
        let first  = SeedRecipeProvider.recipes.map(\.id)
        let second = SeedRecipeProvider.recipes.map(\.id)
        #expect(first == second)
    }

    // MARK: - Specific stable identifiers

    @Test("Spaghetti Bolognese UUID is fixed")
    func spaghettiUUID() {
        let expected = UUID(uuidString: "5EED0001-0000-0000-0000-000000000001")
        let actual = SeedRecipeProvider.recipes.first { $0.name == "Spaghetti Bolognese" }?.id
        #expect(actual == expected)
    }

    @Test("Greek Salad UUID is fixed")
    func greekSaladUUID() {
        let expected = UUID(uuidString: "5EED0001-0000-0000-0000-000000000006")
        let actual = SeedRecipeProvider.recipes.first { $0.name == "Greek Salad" }?.id
        #expect(actual == expected)
    }

    // MARK: - Allergen claims

    @Test("a starter tagged gluten-free names no gluten source", arguments: SeedRecipeProvider.recipes)
    func glutenFreeClaimHolds(recipe: RecipeModel) {
        guard recipe.dietaryInfo.isGlutenFree else { return }
        let text = (recipe.ingredients.map(\.name) + recipe.prePrepInstructions + recipe.instructions + [recipe.notes])
            .joined(separator: " ").lowercased()
        let glutenSources = [
            "bread", "flour", "pasta", "spaghetti", "noodle", "toast", "wheat", "barley", "rye", "spelt", "semolina",
            "bulgur", "couscous", "orzo", "pitta", "naan", "tortilla", "pastry", "soy sauce", "beer", "oats",
        ]
        #expect(glutenSources.filter { text.contains($0) }.isEmpty, "\(recipe.name) claims gluten-free")
    }

    // MARK: - Shipped versions (stale-sample refresh)

    @Test("earlier shipped starter versions belong to today's starters and differ from them")
    func shippedVersionsMatchStarters() throws {
        let current = Dictionary(uniqueKeysWithValues: SeedRecipeProvider.recipes.map { ($0.id, $0) })
        #expect(!SeedRecipeProvider.shippedVersions.isEmpty)
        for old in SeedRecipeProvider.shippedVersions {
            let fresh = try #require(current[old.id])
            #expect(!BundledRecipeCatalog.hasSameContent(old, fresh), "\(old.name)")
        }
    }

    @Test("an untouched starter Greek salad seeded by an older build loses its gluten-free tag on refresh")
    @MainActor
    func oldGreekSaladIsRefreshed() async throws {
        let persistence = PersistenceController(inMemory: true)
        var old = try #require(SeedRecipeProvider.shippedVersions.first { $0.name == "Greek Salad" })
        old.isFavorite = true
        #expect(old.dietaryInfo.isGlutenFree)
        #expect(await persistence.seedRecipes([old]))
        let stored = await persistence.fetchRecipesAsync()
        let sources = try #require(BundledRecipeCatalog.refreshSources(
            bundled: BundledRecipeCatalog.load(), bundledHistory: BundledRecipeCatalog.loadHistory()
        ))
        let updates = BundledRecipeCatalog.sampleUpdates(library: stored, current: sources.current, history: sources.history)
        #expect(updates.count == 1)
        #expect(updates.first?.dietaryInfo.isGlutenFree == false)
        #expect(updates.first?.isFavorite == true)
    }

    @Test("a starter Greek salad the user edited keeps their text")
    func editedGreekSaladIsLeftAlone() throws {
        let old = try #require(SeedRecipeProvider.shippedVersions.first)
        let edited = RecipeModel(
            id: old.id, name: old.name, category: old.category, difficulty: old.difficulty, prepTime: old.prepTime,
            cookingTime: old.cookingTime, baseServings: old.baseServings, ingredients: old.ingredients,
            prePrepInstructions: [], instructions: old.instructions, notes: "No bread — we use rice cakes.",
            dietaryInfo: old.dietaryInfo, isSampleRecipe: true
        )
        let updates = BundledRecipeCatalog.staleSampleRefreshes(
            library: [edited], current: SeedRecipeProvider.recipes, history: SeedRecipeProvider.shippedVersions
        )
        #expect(updates.isEmpty)
    }

    @Test("the refresh version is past 6, so installs that already ran 6 pick up the Greek salad fix")
    func refreshVersionReachesExistingInstalls() {
        #expect(BundledRecipeCatalog.needsSampleRefresh(lastRunVersion: 6))
    }

    @Test("starters alone never complete the refresh when the bundled data is missing")
    func refreshSourcesNeedBundleData() {
        let r = SeedRecipeProvider.recipes[0]
        #expect(BundledRecipeCatalog.refreshSources(bundled: [], bundledHistory: [r]) == nil)
        #expect(BundledRecipeCatalog.refreshSources(bundled: [r], bundledHistory: []) == nil)
        let sources = BundledRecipeCatalog.refreshSources(bundled: [r], bundledHistory: [r], starters: [r], starterHistory: [r])
        #expect(sources?.current.count == 2)
        #expect(sources?.history.count == 2)
    }
}
