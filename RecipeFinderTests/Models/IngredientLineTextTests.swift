import Testing
import Foundation
@testable import RecipeFinder

/// Every "amount name" ingredient line — share text, print, editor prefill — reads the name as written and drops a
/// zero amount, like the recipe screen (bug 2026-11-28: share/print showed "0 Salt And Pepper, To Taste").
@Suite("Ingredient line text")
struct IngredientLineTextTests {

    private func recipe(_ ingredients: [Ingredient]) -> RecipeModel {
        RecipeModel(name: "Soup", category: "Main", difficulty: "Basic", prepTime: "5 minutes",
                    cookingTime: "20 minutes", baseServings: 2, ingredients: ingredients,
                    prePrepInstructions: [], instructions: ["Simmer."], notes: "")
    }

    private let toTaste = Ingredient(baseQuantity: 0, unit: "", name: "salt and pepper, to taste")

    @Test("Share text drops a zero amount and keeps the name as written")
    func shareTextLine() {
        let text = recipe([toTaste, Ingredient(baseQuantity: 200, unit: "g", name: "plain flour")]).shareText
        #expect(text.contains("• Salt and pepper, to taste\n"))
        #expect(text.contains("• 200 g Plain flour"))
        #expect(!text.contains("0 Salt"))
    }

    @Test("Print drops a zero amount and keeps the name as written")
    func printLine() {
        let html = RecipePrintFormatter.html(for: recipe([toTaste]))
        #expect(html.contains("<li>Salt and pepper, to taste</li>"))
    }

    @Test("Edit prefill reads back to the same amounts, units and names", arguments: [
        Ingredient(baseQuantity: 0, unit: "", name: "salt and pepper, to taste"),
        Ingredient(baseQuantity: 200, unit: "g", name: "plain flour"),
        Ingredient(baseQuantity: 1.0 / 3.0, unit: "cup", name: "sugar"),
        Ingredient(baseQuantity: 0, unit: "pinch", name: "nutmeg"),
        // No amount, a number in the name: the line must not let the parser lift "200g" out as the amount.
        Ingredient(baseQuantity: 0, unit: "", name: "rice, about 200g")
    ])
    func editPrefillRoundTrips(original: Ingredient) throws {
        let lines = RecipeWizardView.PrefilledRecipeData(recipe: recipe([original])).ingredients ?? []
        let items = IngredientTextBlock.items(from: lines.joined(separator: "\n"))
        let saved = try #require(RecipeWizardBuilder.makeIngredients(from: items).first)
        #expect(lines.first?.hasPrefix("0") == (original.baseQuantity == 0 && original.unit.isEmpty
                                                 && original.displayName.contains(where: \.isNumber)))
        #expect(abs(saved.baseQuantity - original.baseQuantity) < 1e-9)
        #expect(saved.unit == original.unit)
        #expect(saved.displayName == original.displayName)
        #expect(saved.writtenName == original.writtenName)
    }

    @Test("The written amount is unscaled and unconverted, and empty when there is none", arguments: [
        (Ingredient(baseQuantity: 2, unit: "cup", name: "milk"), "2 cups Milk"),
        (Ingredient(baseQuantity: 0.5, unit: "l", name: "stock"), "½ L Stock"),
        (Ingredient(baseQuantity: 3, unit: "", name: "eggs"), "3 Eggs"),
        (Ingredient(baseQuantity: 0, unit: "pinch", name: "nutmeg"), "pinch Nutmeg"),
        (Ingredient(baseQuantity: 0, unit: "", name: "salt and pepper, to taste"), "Salt and pepper, to taste")
    ])
    func writtenLine(ingredient: Ingredient, expected: String) {
        #expect(IngredientLineText.writtenLine(for: ingredient) == expected)
    }

    @Test("The editor line keeps the stored unit and name and drops a zero amount", arguments: [
        (Ingredient(baseQuantity: 2, unit: "cup", name: "milk"), "2 cup milk"),
        (Ingredient(baseQuantity: 0, unit: "", name: "salt and pepper, to taste"), "salt and pepper, to taste"),
        (Ingredient(baseQuantity: 0, unit: "", name: "rice, about 200g"), "0 rice, about 200g")
    ])
    func editorLine(ingredient: Ingredient, expected: String) {
        #expect(IngredientLineText.editorLine(for: ingredient) == expected)
    }

    @Test("The amount-estimate prompt reads the written amount")
    func estimatePromptAmount() throws {
        let request = try #require(AmountEstimateRequest(recipeName: "Soup", servings: 2, ingredients: [
            Ingredient(baseQuantity: 0, unit: "", name: "plain flour"),
            Ingredient(baseQuantity: 2, unit: "cup", name: "milk")
        ], steps: []))
        #expect(request.prompt.contains("2. Milk — 2 cups"))
    }
}
