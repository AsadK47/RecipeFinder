import Testing
import Foundation
@testable import RecipeFinder

@Suite struct BackupMergeTests {

    /// A minimal `Identifiable` sample for exercising the generic union merge,
    /// independent of any specific store model.
    private struct Sample: Identifiable, Equatable {
        let id: UUID
        let title: String
    }

    private static func sample(_ title: String, id: UUID = UUID()) -> Sample {
        Sample(id: id, title: title)
    }

    private static func recipe(_ name: String, id: UUID = UUID()) -> RecipeModel {
        RecipeModel(name: name, category: "Main", difficulty: "Basic", prepTime: "5 min",
                    cookingTime: "10 min", baseServings: 2, ingredients: [],
                    prePrepInstructions: [], instructions: ["step"], notes: "")
    }

    private static func badge(_ id: String, earned: Date? = nil) -> Badge {
        Badge(id: id, title: id, description: "", icon: "", color: "green", dateEarned: earned, isUnlocked: earned != nil)
    }

    // MARK: - merged(existing:incoming:) by identity

    @Test func merged_appendsOnlyNewIDs_preservingOrder() {
        let keep = Self.sample("A")
        let dupeID = UUID()
        let existing = [keep, Self.sample("B", id: dupeID)]
        let incoming = [Self.sample("B-again", id: dupeID), Self.sample("C")]

        let result = BackupMerge.merged(existing: existing, incoming: incoming)

        #expect(result.map(\.title) == ["A", "B", "C"]) // dupe id skipped; new appended in order
    }

    @Test func mergedWithAdditions_returnsOnlyAppendedItems() {
        let dupeID = UUID()
        let existing = [Self.sample("A", id: dupeID)]
        let incoming = [Self.sample("A-again", id: dupeID), Self.sample("B"), Self.sample("C")]

        let result = BackupMerge.mergedWithAdditions(existing: existing, incoming: incoming)

        #expect(result.merged.map(\.title) == ["A", "B", "C"])
        #expect(result.added.map(\.title) == ["B", "C"])
    }

    @Test func merged_intoEmpty_returnsIncoming() {
        let incoming = [Self.sample("A"), Self.sample("B")]
        #expect(BackupMerge.merged(existing: [Sample](), incoming: incoming).map(\.title) == ["A", "B"])
    }

    @Test func merged_noIncoming_returnsExistingUnchanged() {
        let existing = [Self.sample("A")]
        #expect(BackupMerge.merged(existing: existing, incoming: []).map(\.id) == existing.map(\.id))
    }

    // MARK: - mergedRecipes: id + normalized-name dedupe

    @Test func mergedRecipes_skipsSameId() {
        let id = UUID()
        let existing = [Self.recipe("Soup", id: id)]
        let incoming = [Self.recipe("Soup", id: id)]
        #expect(BackupMerge.mergedRecipes(existing: existing, incoming: incoming).count == 1)
    }

    @Test func mergedRecipes_skipsSameName_evenWithDifferentId() {
        let existing = [Self.recipe("Chicken Soup")]
        let incoming = [Self.recipe("  chicken soup  ")] // different id, same normalized name
        let result = BackupMerge.mergedRecipes(existing: existing, incoming: incoming)
        #expect(result.count == 1)
        #expect(result.first?.name == "Chicken Soup") // existing kept
    }

    @Test func mergedRecipes_keepsGenuinelyNew() {
        let existing = [Self.recipe("Soup")]
        let incoming = [Self.recipe("Stew"), Self.recipe("Pie")]
        #expect(BackupMerge.mergedRecipes(existing: existing, incoming: incoming).map(\.name) == ["Soup", "Stew", "Pie"])
    }

    // MARK: - mergedBadges: union, existing wins

    @Test func mergedBadges_unionsAndKeepsExistingOnCollision() {
        let mine = Date(timeIntervalSince1970: 1_000)
        let existing = ["first": Self.badge("first", earned: mine)]
        let incoming = [
            "first": Self.badge("first", earned: Date(timeIntervalSince1970: 2_000)), // collision
            "second": Self.badge("second", earned: Date(timeIntervalSince1970: 3_000))
        ]
        let result = BackupMerge.mergedBadges(existing: existing, incoming: incoming)
        #expect(Set(result.keys) == ["first", "second"])
        #expect(result["first"]?.dateEarned == mine) // existing preserved
    }

    @Test func mergedBadgesWithAdditions_reportsOnlyNewIDs() {
        let existing = ["first": Self.badge("first", earned: Date())]
        let incoming = ["first": Self.badge("first"), "second": Self.badge("second")]
        #expect(BackupMerge.mergedBadgesWithAdditions(existing: existing, incoming: incoming).addedIDs == ["second"])
    }

    // MARK: - duplicateRecipeIDs(in:)

    private static func copy(_ name: String, ingredients: [String] = ["egg"], cookCount: Int = 0,
                             isFavorite: Bool = false, isSample: Bool = true) -> RecipeModel {
        RecipeModel(name: name, category: "Main", difficulty: "Basic", prepTime: "5 min", cookingTime: "10 min",
                    baseServings: 2,
                    ingredients: ingredients.map { Ingredient(baseQuantity: 1, unit: "", name: $0) },
                    prePrepInstructions: [], instructions: ["step"], notes: "",
                    isFavorite: isFavorite, isSampleRecipe: isSample, cookCount: cookCount)
    }

    @Test func duplicateRecipeIDs_keepsTheCookedCopyAndRemovesTheRest() {
        let plain1 = Self.copy("Pancakes")
        let cooked = Self.copy("Pancakes", cookCount: 2)
        let plain2 = Self.copy("pancakes ")   // same content, different case/spacing
        let remove = BackupMerge.duplicateRecipeIDs(in: [plain1, cooked, plain2])
        #expect(remove == [plain1.id, plain2.id])
    }

    @Test func duplicateRecipeIDs_ignoresSameNameWithDifferentIngredients() {
        let a = Self.copy("Curry", ingredients: ["chicken"])
        let b = Self.copy("Curry", ingredients: ["chickpeas"])
        #expect(BackupMerge.duplicateRecipeIDs(in: [a, b]).isEmpty)
    }

    @Test func duplicateRecipeIDs_prefersFavouriteThenUsersOwnOverSample() {
        let sample = Self.copy("Soup")
        let own = Self.copy("Soup", isSample: false)
        let favourite = Self.copy("Soup", isFavorite: true)
        #expect(BackupMerge.duplicateRecipeIDs(in: [sample, own, favourite]) == [sample.id, own.id])
        #expect(BackupMerge.duplicateRecipeIDs(in: [sample, own]) == [sample.id])
    }

    @Test func duplicateRecipeIDs_tieKeepsTheFirstCopy() {
        let first = Self.copy("Toast")
        let second = Self.copy("Toast")
        #expect(BackupMerge.duplicateRecipeIDs(in: [first, second]) == [second.id])
    }
}
