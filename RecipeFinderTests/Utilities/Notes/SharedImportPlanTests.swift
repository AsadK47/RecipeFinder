import Testing
import Foundation
@testable import RecipeFinder

/// Routing of the share extension's inbox on the Recipes tab and the gate for silently saving a finished recipe.
@Suite struct SharedImportPlanTests {

    private static func extracted(_ name: String) -> ExtractedRecipeData {
        ExtractedRecipeData(
            name: name, description: nil, matchedIngredients: [], rawIngredients: ["1 egg"],
            rawText: "1 egg", instructions: ["mix"], sourceURL: URL(fileURLWithPath: "/x"),
            cookTimeMinutes: nil, prepTimeMinutes: nil, servings: nil,
            difficulty: nil, category: nil, cuisine: nil, imageURL: nil
        )
    }

    private static func recipe(
        _ name: String, ingredients: [String] = ["egg"], steps: [String] = ["Whisk"]
    ) -> RecipeModel {
        RecipeModel(
            name: name, category: "Main", difficulty: "Basic", prepTime: "5 min", cookingTime: "10 min",
            baseServings: 2,
            ingredients: ingredients.map { Ingredient(baseQuantity: 1, unit: "", name: $0) },
            prePrepInstructions: [], instructions: steps, notes: ""
        )
    }

    // MARK: - Routing

    @Test func emptyInboxDoesNothing() {
        let plan = SharedImportPlan(payloads: [])
        #expect(plan.extracted.isEmpty)
        #expect(plan.interactive == nil)
        #expect(plan.requeued.isEmpty)
    }

    @Test func everyFinishedRecipeIsSaved() {
        let plan = SharedImportPlan(payloads: [.extracted(Self.extracted("Soup")), .extracted(Self.extracted("Stew"))])
        #expect(plan.extracted.map { $0.name } == ["Soup", "Stew"])
        #expect(plan.interactive == nil)
        #expect(plan.requeued.isEmpty)
    }

    @Test func firstLinkOpensASheetAndLaterSharesWaitInOrder() {
        let plan = SharedImportPlan(payloads: [
            .url("https://a.test"), .text("pasta"), .extracted(Self.extracted("Soup")), .url("https://b.test")
        ])
        #expect(plan.interactive == .url("https://a.test"))
        #expect(plan.requeued == [.text("pasta"), .url("https://b.test")])
        #expect(plan.extracted.map { $0.name } == ["Soup"])
    }

    @Test func textFirstOpensTheWizardAndALaterLinkWaits() {
        let plan = SharedImportPlan(payloads: [.text("2 eggs, whisk"), .url("https://a.test")])
        #expect(plan.interactive == .text("2 eggs, whisk"))
        #expect(plan.requeued == [.url("https://a.test")])
    }

    @Test func aFinishedRecipeBeforeALinkDoesNotTakeTheSheet() {
        let plan = SharedImportPlan(payloads: [.extracted(Self.extracted("Soup")), .url("https://a.test")])
        #expect(plan.interactive == .url("https://a.test"))
        #expect(plan.requeued.isEmpty)
    }

    // MARK: - Verdict

    @Test func newCompleteRecipeIsAdded() {
        #expect(SharedImportPlan.verdict(for: Self.recipe("Soup"), existingNames: ["Stew"]) == .add)
    }

    @Test(arguments: ["Soup", "soup", "  SOUP ", "Soup "])
    func sameNameIgnoringCaseAndSpacesIsADuplicate(existing: String) {
        #expect(SharedImportPlan.verdict(for: Self.recipe(" Soup"), existingNames: [existing]) == .duplicate)
    }

    @Test func nameDifferingByANewlineIsNotADuplicate() {
        // Pins the original rule: only spaces are trimmed, so a trailing newline makes a different name.
        #expect(SharedImportPlan.verdict(for: Self.recipe("Soup\n"), existingNames: ["Soup"]) == .add)
    }

    @Test func missingIngredientsOrStepsIsIncomplete() {
        #expect(SharedImportPlan.verdict(for: Self.recipe("Soup", ingredients: []), existingNames: []) == .incomplete)
        #expect(SharedImportPlan.verdict(for: Self.recipe("Soup", steps: []), existingNames: []) == .incomplete)
    }

    @Test func duplicateWinsOverIncomplete() {
        let half = Self.recipe("Soup", ingredients: [], steps: [])
        #expect(SharedImportPlan.verdict(for: half, existingNames: ["soup"]) == .duplicate)
    }
}
