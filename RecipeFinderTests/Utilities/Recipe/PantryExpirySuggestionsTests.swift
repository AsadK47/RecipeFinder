import Testing
import Foundation
@testable import RecipeFinder

@Suite("PantryExpirySuggestions")
struct PantryExpirySuggestionsTests {

    // MARK: - Fixtures

    private func recipe(name: String = "Test Recipe", ingredientNames: [String]) -> RecipeModel {
        RecipeModel(
            name: name,
            category: "Test",
            difficulty: "Easy",
            prepTime: "10 min",
            cookingTime: "20 min",
            baseServings: 4,
            currentServings: 4,
            ingredients: ingredientNames.map { Ingredient(baseQuantity: 1.0, unit: "", name: $0) },
            prePrepInstructions: [],
            instructions: [],
            notes: ""
        )
    }

    private func inventoryItem(name: String, daysUntilExpiry: Int) -> KitchenInventoryModel {
        KitchenInventoryModel(
            name: name,
            category: .produce,
            quantity: 1,
            unit: "piece",
            expiryDate: Calendar.current.date(byAdding: .day, value: daysUntilExpiry, to: Date())
        )
    }

    // MARK: - No expiring items

    @Test("Returns empty when no inventory items expire within 3 days")
    func returnsEmptyWhenNoExpiringItems() {
        let r = recipe(ingredientNames: ["chicken", "tomato"])
        let farAway = inventoryItem(name: "Chicken", daysUntilExpiry: 30)
        let results = PantryExpirySuggestions.matches(recipes: [r], inventoryItems: [farAway])
        #expect(results.isEmpty)
    }

    @Test("Returns empty when inventory is empty")
    func returnsEmptyWhenInventoryIsEmpty() {
        let r = recipe(ingredientNames: ["chicken"])
        let results = PantryExpirySuggestions.matches(recipes: [r], inventoryItems: [])
        #expect(results.isEmpty)
    }

    @Test("Returns empty when no recipe uses an expiring item")
    func returnsEmptyWhenNoRecipeMatchesExpiringItems() {
        let r = recipe(ingredientNames: ["pasta", "cheese"])
        let expiring = inventoryItem(name: "Salmon", daysUntilExpiry: 1)
        let results = PantryExpirySuggestions.matches(recipes: [r], inventoryItems: [expiring])
        #expect(results.isEmpty)
    }

    // MARK: - Matching recipes

    @Test("Returns recipe whose ingredient matches an expiring item")
    func returnsMatchingRecipeForExpiringItem() {
        let r = recipe(name: "Chicken Stir Fry", ingredientNames: ["chicken breast", "peppers"])
        let expiring = inventoryItem(name: "Chicken Breast", daysUntilExpiry: 1)
        let results = PantryExpirySuggestions.matches(recipes: [r], inventoryItems: [expiring])
        #expect(results.count == 1)
        #expect(results.first?.recipe.name == "Chicken Stir Fry")
    }

    @Test("Populates expiringItems with the matched inventory name")
    func populatesExpiringItemsCorrectly() {
        let r = recipe(ingredientNames: ["chicken breast", "peppers"])
        let expiring = inventoryItem(name: "Chicken Breast", daysUntilExpiry: 2)
        let results = PantryExpirySuggestions.matches(recipes: [r], inventoryItems: [expiring])
        #expect(results.first?.expiringItems == ["Chicken Breast"])
    }

    @Test("Excludes non-matching recipes when one expiring item is present")
    func excludesNonMatchingRecipes() {
        let matching = recipe(name: "Salmon Bowl", ingredientNames: ["salmon", "rice"])
        let nonMatching = recipe(name: "Pasta", ingredientNames: ["pasta", "cheese"])
        let expiring = inventoryItem(name: "Salmon", daysUntilExpiry: 2)
        let results = PantryExpirySuggestions.matches(
            recipes: [matching, nonMatching],
            inventoryItems: [expiring]
        )
        #expect(results.count == 1)
        #expect(results.first?.recipe.name == "Salmon Bowl")
    }

    @Test("Only lists expiring items in the match, not items with distant expiry")
    func expiringItemsExcludesNonExpiringInventory() {
        let r = recipe(ingredientNames: ["salmon", "tomato", "pasta"])
        let expiringSalmon = inventoryItem(name: "Salmon", daysUntilExpiry: 1)
        let freshPasta = inventoryItem(name: "Pasta", daysUntilExpiry: 100)
        let results = PantryExpirySuggestions.matches(
            recipes: [r],
            inventoryItems: [expiringSalmon, freshPasta]
        )
        #expect(results.first?.expiringItems == ["Salmon"])
    }

    // MARK: - Cap

    @Test("Returns at most maxSuggestions results")
    func capsAtMaxSuggestions() {
        let recipes = (0..<10).map { recipe(name: "Recipe \($0)", ingredientNames: ["chicken"]) }
        let expiring = inventoryItem(name: "Chicken", daysUntilExpiry: 1)
        let results = PantryExpirySuggestions.matches(recipes: recipes, inventoryItems: [expiring])
        #expect(results.count <= PantryExpirySuggestions.maxSuggestions)
    }

    // MARK: - Edge cases

    @Test("Item expiring today (0 days) is included")
    func includesItemExpiringToday() {
        let r = recipe(ingredientNames: ["beef"])
        let expiringToday = inventoryItem(name: "Beef", daysUntilExpiry: 0)
        let results = PantryExpirySuggestions.matches(recipes: [r], inventoryItems: [expiringToday])
        #expect(results.count == 1)
    }

    @Test("Already-expired item (negative days) is excluded from suggestions")
    func excludesAlreadyExpiredItems() {
        let r = recipe(ingredientNames: ["beef"])
        let expired = inventoryItem(name: "Beef", daysUntilExpiry: -1)
        let results = PantryExpirySuggestions.matches(recipes: [r], inventoryItems: [expired])
        #expect(results.isEmpty)
    }

    @Test("Item expiring in exactly 3 days is included")
    func includesItemExpiringInThreeDays() {
        let r = recipe(ingredientNames: ["milk"])
        let threeDays = inventoryItem(name: "Milk", daysUntilExpiry: 3)
        let results = PantryExpirySuggestions.matches(recipes: [r], inventoryItems: [threeDays])
        #expect(results.count == 1)
    }

    @Test("Item expiring in 4 days is excluded")
    func excludesItemExpiringInFourDays() {
        let r = recipe(ingredientNames: ["milk"])
        let fourDays = inventoryItem(name: "Milk", daysUntilExpiry: 4)
        let results = PantryExpirySuggestions.matches(recipes: [r], inventoryItems: [fourDays])
        #expect(results.isEmpty)
    }
}
