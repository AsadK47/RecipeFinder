import Testing
import Foundation
@testable import RecipeFinder

@Suite("SmartCollection matching rules")
struct SmartCollectionTests {

    // MARK: - Fixtures

    private func recipe(
        prepTime: String = "0 min",
        cookingTime: String = "0 min",
        difficulty: String = "Easy",
        ingredientNames: [String] = ["ingredient"],
        isVegetarian: Bool = false,
        rating: Int = 0,
        lastCookedAt: Date? = nil
    ) -> RecipeModel {
        var r = RecipeModel(
            name: "Test",
            category: "Test",
            difficulty: difficulty,
            prepTime: prepTime,
            cookingTime: cookingTime,
            baseServings: 2,
            currentServings: 2,
            ingredients: ingredientNames.map { Ingredient(baseQuantity: 1.0, unit: "", name: $0) },
            prePrepInstructions: [],
            instructions: [],
            notes: ""
        )
        r.dietaryInfo = DietaryInfo(isVegetarian: isVegetarian)
        r.rating = rating
        r.lastCookedAt = lastCookedAt
        return r
    }

    // MARK: - Quick Meals (≤ 30 min total)

    @Test("Matches recipe with total time exactly 30 min")
    func quickMeals_matchesAt30Minutes() {
        let r = recipe(prepTime: "10 min", cookingTime: "20 min")
        #expect(SmartCollection.quickMeals.matches(r))
    }

    @Test("Excludes recipe with total time over 30 min")
    func quickMeals_excludesOver30Minutes() {
        let r = recipe(prepTime: "15 min", cookingTime: "20 min")
        #expect(!SmartCollection.quickMeals.matches(r))
    }

    @Test("Excludes recipe with zero total time (no time specified)")
    func quickMeals_excludesZeroTotalTime() {
        let r = recipe(prepTime: "0 min", cookingTime: "0 min")
        #expect(!SmartCollection.quickMeals.matches(r))
    }

    // MARK: - Easy Recipes

    @Test("Matches recipe with difficulty 'Easy'")
    func easyRecipes_matchesEasyDifficulty() {
        let r = recipe(difficulty: "Easy")
        #expect(SmartCollection.easyRecipes.matches(r))
    }

    @Test("Is case-insensitive for difficulty")
    func easyRecipes_matchesMixedCase() {
        let r = recipe(difficulty: "EASY")
        #expect(SmartCollection.easyRecipes.matches(r))
    }

    @Test("Excludes recipe with difficulty 'Medium'")
    func easyRecipes_excludesMedium() {
        let r = recipe(difficulty: "Medium")
        #expect(!SmartCollection.easyRecipes.matches(r))
    }

    // MARK: - Vegetarian

    @Test("Matches recipe flagged as vegetarian")
    func vegetarian_matchesFlag() {
        let r = recipe(isVegetarian: true)
        #expect(SmartCollection.vegetarian.matches(r))
    }

    @Test("Excludes recipe not flagged as vegetarian")
    func vegetarian_excludesNonVegetarian() {
        let r = recipe(isVegetarian: false)
        #expect(!SmartCollection.vegetarian.matches(r))
    }

    // MARK: - Highly Rated (≥ 4 stars)

    @Test("Matches recipe with rating exactly 4")
    func highRated_matchesFourStars() {
        let r = recipe(rating: 4)
        #expect(SmartCollection.highRated.matches(r))
    }

    @Test("Matches recipe with rating 5")
    func highRated_matchesFiveStars() {
        let r = recipe(rating: 5)
        #expect(SmartCollection.highRated.matches(r))
    }

    @Test("Excludes recipe with rating 3")
    func highRated_excludesThreeStars() {
        let r = recipe(rating: 3)
        #expect(!SmartCollection.highRated.matches(r))
    }

    @Test("Excludes unrated recipe (0 stars)")
    func highRated_excludesUnrated() {
        let r = recipe(rating: 0)
        #expect(!SmartCollection.highRated.matches(r))
    }

    // MARK: - Recently Cooked (within 30 days)

    @Test("Matches recipe cooked today")
    func recentlyCooked_matchesCokedToday() {
        let r = recipe(lastCookedAt: Date())
        #expect(SmartCollection.recentlyCooked.matches(r))
    }

    @Test("Matches recipe cooked exactly 30 days ago")
    func recentlyCooked_matchesAt30Days() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let r = recipe(lastCookedAt: thirtyDaysAgo)
        #expect(SmartCollection.recentlyCooked.matches(r))
    }

    @Test("Excludes recipe never cooked")
    func recentlyCooked_excludesNeverCooked() {
        let r = recipe(lastCookedAt: nil)
        #expect(!SmartCollection.recentlyCooked.matches(r))
    }

    @Test("Excludes recipe cooked 31 days ago")
    func recentlyCooked_excludesOver30Days() {
        let thirtyone = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        let r = recipe(lastCookedAt: thirtyone)
        #expect(!SmartCollection.recentlyCooked.matches(r))
    }

    // MARK: - Few Ingredients (1–5)

    @Test("Matches recipe with exactly 5 ingredients")
    func fewIngredients_matchesFiveIngredients() {
        let r = recipe(ingredientNames: ["a", "b", "c", "d", "e"])
        #expect(SmartCollection.fewIngredients.matches(r))
    }

    @Test("Excludes recipe with 6 ingredients")
    func fewIngredients_excludesSixIngredients() {
        let r = recipe(ingredientNames: ["a", "b", "c", "d", "e", "f"])
        #expect(!SmartCollection.fewIngredients.matches(r))
    }

    @Test("Excludes recipe with no ingredients")
    func fewIngredients_excludesEmptyIngredients() {
        let r = recipe(ingredientNames: [])
        #expect(!SmartCollection.fewIngredients.matches(r))
    }

    // MARK: - recipes(from:)

    @Test("Returns only matching recipes from a mixed list")
    func recipesFrom_filtersCorrectly() {
        let quick = recipe(prepTime: "5 min", cookingTime: "10 min")
        let slow = recipe(prepTime: "30 min", cookingTime: "60 min")
        let results = SmartCollection.quickMeals.recipes(from: [quick, slow])
        #expect(results.count == 1)
        #expect(results.first?.prepTime == "5 min")
    }

    @Test("Returns empty when no recipes match")
    func recipesFrom_returnsEmptyWhenNoMatch() {
        let hard = recipe(difficulty: "Hard")
        let results = SmartCollection.easyRecipes.recipes(from: [hard])
        #expect(results.isEmpty)
    }
}
