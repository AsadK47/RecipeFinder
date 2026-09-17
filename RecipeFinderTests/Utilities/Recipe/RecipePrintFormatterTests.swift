import Testing
import Foundation
@testable import RecipeFinder

@Suite struct RecipePrintFormatterTests {
    private func recipe(
        name: String = "Test Recipe",
        ingredients: [Ingredient] = [],
        instructions: [String] = [],
        prePrepInstructions: [String] = [],
        notes: String = "",
        prepTime: String = "10 minutes",
        cookingTime: String = "20 minutes",
        baseServings: Int = 4,
        difficulty: String = "Easy",
        cuisine: String? = nil
    ) -> RecipeModel {
        RecipeModel(
            name: name,
            category: "Main",
            difficulty: difficulty,
            prepTime: prepTime,
            cookingTime: cookingTime,
            baseServings: baseServings,
            ingredients: ingredients,
            prePrepInstructions: prePrepInstructions,
            instructions: instructions,
            notes: notes,
            cuisine: cuisine
        )
    }

    // MARK: - Structure

    @Test func htmlIsValidDocument() {
        let html = RecipePrintFormatter.html(for: recipe())
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("<html>"))
        #expect(html.contains("</html>"))
        #expect(html.contains("</body>"))
    }

    @Test func htmlContainsRecipeName() {
        let html = RecipePrintFormatter.html(for: recipe(name: "Pasta Carbonara"))
        #expect(html.contains("Pasta Carbonara"))
    }

    @Test func htmlContainsServings() {
        let html = RecipePrintFormatter.html(for: recipe(baseServings: 6))
        #expect(html.contains("Serves 6"))
    }

    @Test func htmlContainsPrepAndCookTime() {
        let html = RecipePrintFormatter.html(for: recipe(prepTime: "15 minutes", cookingTime: "30 minutes"))
        #expect(html.contains("Prep: 15 minutes"))
        #expect(html.contains("Cook: 30 minutes"))
    }

    @Test func htmlContainsCuisineWhenPresent() {
        let html = RecipePrintFormatter.html(for: recipe(cuisine: "Italian"))
        #expect(html.contains("Italian"))
    }

    // MARK: - Ingredients

    @Test func htmlContainsIngredientName() {
        let ingredient = Ingredient(baseQuantity: 2, unit: "cups", name: "Flour")
        let html = RecipePrintFormatter.html(for: recipe(ingredients: [ingredient]))
        #expect(html.contains("Flour"))
        #expect(html.contains("cups"))
    }

    @Test func htmlContainsAllIngredients() {
        let ingredients = [
            Ingredient(baseQuantity: 1, unit: "cup", name: "Rice"),
            Ingredient(baseQuantity: 2, unit: "tbsp", name: "Butter"),
            Ingredient(baseQuantity: 0, unit: "", name: "Salt"),
        ]
        let html = RecipePrintFormatter.html(for: recipe(ingredients: ingredients))
        #expect(html.contains("Rice"))
        #expect(html.contains("Butter"))
        #expect(html.contains("Salt"))
    }

    // MARK: - Instructions

    @Test func htmlContainsInstructions() {
        let html = RecipePrintFormatter.html(for: recipe(instructions: ["Mix well", "Bake at 200°C"]))
        #expect(html.contains("Mix well"))
        #expect(html.contains("Bake at 200°C"))
    }

    @Test func htmlIncludesPrePrepWhenPresent() {
        let html = RecipePrintFormatter.html(for: recipe(prePrepInstructions: ["Soak overnight"]))
        #expect(html.contains("Pre-Prep"))
        #expect(html.contains("Soak overnight"))
    }

    @Test func htmlOmitsPrePrepWhenEmpty() {
        let html = RecipePrintFormatter.html(for: recipe(prePrepInstructions: []))
        #expect(!html.contains("Pre-Prep"))
    }

    // MARK: - Notes

    @Test func htmlIncludesPersonalNotesWhenPresent() {
        let html = RecipePrintFormatter.html(for: recipe(notes: "My personal notes\nhttps://example.com"))
        #expect(html.contains("My personal notes"))
        #expect(html.contains("<h2>Notes</h2>"))
    }

    @Test func htmlOmitsNotesSectionWhenEmpty() {
        // notes contains only the import footer URL — notesForDisplay will be empty
        let html = RecipePrintFormatter.html(for: recipe(notes: "Imported · 1 Jan 2026\nhttps://example.com"))
        #expect(!html.contains("<h2>Notes</h2>"))
    }

    // MARK: - HTML escaping

    @Test func htmlEscapesAmpersandInName() {
        let html = RecipePrintFormatter.html(for: recipe(name: "Tom & Jerry Cake"))
        #expect(html.contains("Tom &amp; Jerry Cake"))
        // Raw ampersand must not appear inside the h1 tag.
        let inH1 = html.components(separatedBy: "<h1>").dropFirst().first?.components(separatedBy: "</h1>").first ?? ""
        #expect(!inH1.contains(" & "))
    }

    @Test func htmlEscapesAngleBracketsInName() {
        let html = RecipePrintFormatter.html(for: recipe(name: "<Best> Recipe"))
        #expect(html.contains("&lt;Best&gt;"))
    }

    @Test func htmlEscapesSpecialCharsInIngredients() {
        let ingredient = Ingredient(baseQuantity: 1, unit: "", name: "A & B sauce")
        let html = RecipePrintFormatter.html(for: recipe(ingredients: [ingredient]))
        #expect(html.contains("A &amp; B sauce"))
    }

    @Test func htmlEscapesSpecialCharsInInstructions() {
        let html = RecipePrintFormatter.html(for: recipe(instructions: ["Heat to <200°C> or > 180°C"]))
        #expect(html.contains("&lt;200°C&gt;"))
        #expect(html.contains("&gt; 180°C"))
    }

    @Test func htmlContainsFooter() {
        let html = RecipePrintFormatter.html(for: recipe())
        #expect(html.contains("Printed from RecipeFinder"))
    }
}
