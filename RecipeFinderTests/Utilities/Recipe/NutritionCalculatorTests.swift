import Testing
import Foundation
@testable import RecipeFinder

@Suite struct NutritionCalculatorTests {

    // MARK: - Guards

    @Test func emptyIngredientsReturnsNil() {
        #expect(NutritionCalculator.calculate(ingredients: [], servings: 2) == nil)
    }

    @Test func zeroServingsReturnsNil() {
        let i = [Ingredient(baseQuantity: 100, unit: "g", name: "chicken breast")]
        #expect(NutritionCalculator.calculate(ingredients: i, servings: 0) == nil)
    }

    @Test func allUnknownIngredientsBelowCoverageThreshold() {
        let i = [
            Ingredient(baseQuantity: 100, unit: "g", name: "xyzzyplugh foobar"),
            Ingredient(baseQuantity: 100, unit: "g", name: "nonexistent foodstuff"),
        ]
        #expect(NutritionCalculator.calculate(ingredients: i, servings: 1) == nil)
    }

    // MARK: - Weight unit conversions

    @Test(
        "Weight units produce consistent per-gram result for olive oil",
        arguments: [
            ("g",   100.0,  884.0),
            ("kg",    0.1,  884.0),
            ("oz",  3.527,  884.0),
            ("lbs", 0.2205, 884.0),
        ] as [(String, Double, Double)]
    )
    func weightUnitConversion(unit: String, qty: Double, expectedKcal: Double) throws {
        let i = [Ingredient(baseQuantity: qty, unit: unit, name: "olive oil")]
        let result = try #require(NutritionCalculator.calculate(ingredients: i, servings: 1))
        #expect(
            abs(Double(result.calories) - expectedKcal) < 20,
            "Expected ~\(Int(expectedKcal)) kcal for ~100g olive oil via \(unit), got \(result.calories)"
        )
    }

    // MARK: - Volume unit conversions

    @Test func cupOfSugarCalculatesCalories() throws {
        // 1 cup ≈ 240 ml; sugar density ≈ 0.85 g/ml → ~204 g × 387 kcal/100 g ≈ 789 kcal
        let i = [Ingredient(baseQuantity: 1, unit: "cup", name: "sugar")]
        let result = try #require(NutritionCalculator.calculate(ingredients: i, servings: 1))
        #expect(result.calories > 600 && result.calories < 950)
    }

    @Test func tablespoonOfOliveOilCalculatesCalories() throws {
        // 1 tbsp ≈ 15 ml × 0.9 g/ml = 13.5 g × 884 kcal/100 g ≈ 119 kcal
        let i = [Ingredient(baseQuantity: 1, unit: "tbsp", name: "olive oil")]
        let result = try #require(NutritionCalculator.calculate(ingredients: i, servings: 1))
        #expect(result.calories > 100 && result.calories < 140)
    }

    // MARK: - Count unit conversions

    @Test func cloveOfGarlicCalculatesCalories() throws {
        // 1 clove garlic ≈ 5 g × 149 kcal/100 g ≈ 7 kcal
        let i = [Ingredient(baseQuantity: 1, unit: "clove", name: "garlic")]
        let result = try #require(NutritionCalculator.calculate(ingredients: i, servings: 1))
        #expect(result.calories >= 3 && result.calories <= 15)
    }

    @Test func unitlessCountIngredientFallsBackToPieceWeight() throws {
        // "1 onion" with unit "" → treated as 1 piece ≈ 150 g × 40 kcal/100 g ≈ 60 kcal
        let i = [Ingredient(baseQuantity: 1, unit: "", name: "onion")]
        let result = try #require(NutritionCalculator.calculate(ingredients: i, servings: 1))
        #expect(result.calories > 40 && result.calories < 100)
    }

    // MARK: - Serving scaling

    @Test func servingsScaleCaloriesCorrectly() throws {
        let i = [Ingredient(baseQuantity: 200, unit: "g", name: "chicken breast")]
        let result4 = try #require(NutritionCalculator.calculate(ingredients: i, servings: 4))
        let result1 = try #require(NutritionCalculator.calculate(ingredients: i, servings: 1))
        // 4 servings = 50 g each; 1 serving = 200 g → should be ~4× difference
        #expect(result4.calories < result1.calories)
        #expect(abs(Double(result4.calories) * 4.0 - Double(result1.calories)) < 20)
    }

    // MARK: - Macros

    @Test func chickenBreastMacrosAreReasonable() throws {
        // 200 g chicken breast, 2 servings → 100 g per serving
        // ~165 kcal, ~31 g protein, ~0 g carbs, ~3.6 g fat per 100 g
        let i = [Ingredient(baseQuantity: 200, unit: "g", name: "chicken breast")]
        let result = try #require(NutritionCalculator.calculate(ingredients: i, servings: 2))
        #expect(result.calories >= 150 && result.calories <= 185)
        #expect(result.protein >= 25 && result.protein <= 38)
        #expect(result.carbs < 5)
        #expect(result.fat < 8)
    }

    // MARK: - Coverage

    @Test func partialCoverageReflectedInResult() throws {
        let i = [
            Ingredient(baseQuantity: 200, unit: "g", name: "chicken breast"),
            Ingredient(baseQuantity: 100, unit: "g", name: "unknownxyzzy"),
        ]
        let result = try #require(NutritionCalculator.calculate(ingredients: i, servings: 1))
        #expect(result.coverage == 0.5)
    }

    @Test func fullCoverageWhenAllIngredientsKnown() throws {
        let i = [
            Ingredient(baseQuantity: 200, unit: "g", name: "chicken breast"),
            Ingredient(baseQuantity: 1, unit: "tbsp", name: "olive oil"),
        ]
        let result = try #require(NutritionCalculator.calculate(ingredients: i, servings: 1))
        #expect(result.coverage == 1.0)
    }

    // MARK: - Fuzzy name matching

    @Test(
        "Common adjective-qualified names resolve to a known ingredient",
        arguments: [
            "fresh garlic",
            "minced garlic",
            "garlic cloves",
            "crushed garlic",
            "diced onion",
            "frozen peas",
            "canned chickpeas",
        ]
    )
    func fuzzyMatchCommonModifiers(name: String) {
        let i = [Ingredient(baseQuantity: 100, unit: "g", name: name)]
        #expect(
            NutritionCalculator.calculate(ingredients: i, servings: 1) != nil,
            "Expected '\(name)' to resolve to a known ingredient"
        )
    }
}
