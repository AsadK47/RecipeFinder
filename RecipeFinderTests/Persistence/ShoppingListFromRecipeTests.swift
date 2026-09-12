import Testing
import Foundation
@testable import RecipeFinder

/// Integration: `ShoppingListManager.addIngredients(from:)` — the path from a
/// `RecipeModel` with `Ingredient` values into the shopping list store.
/// Each test uses isolated `UserDefaults` so no state crosses between runs.
@MainActor
@Suite struct ShoppingListFromRecipeTests {

    private func makeManager() -> ShoppingListManager {
        ShoppingListManager(storage: UserScopedStorage(
            userDefaults: UserDefaults(suiteName: UUID().uuidString)!
        ))
    }

    private func ing(_ name: String, qty: Double = 1.0, unit: String = "") -> Ingredient {
        Ingredient(baseQuantity: qty, unit: unit, name: name)
    }

    private func recipe(name: String = "Test Recipe", ingredients: [Ingredient]) -> RecipeModel {
        RecipeModel(
            id: UUID(),
            name: name,
            category: "Main",
            difficulty: "Basic",
            prepTime: "5 minutes",
            cookingTime: "30 minutes",
            baseServings: 2,
            ingredients: ingredients,
            prePrepInstructions: [],
            instructions: ["Cook"],
            notes: "",
            isSampleRecipe: false
        )
    }

    // MARK: - Core flow

    @Test func addIngredients_allNamesAppearInList() {
        let manager = makeManager()
        let r = recipe(ingredients: [ing("Flour"), ing("Sugar"), ing("Eggs")])

        manager.addIngredients(from: r)

        let names = Set(manager.items.map(\.name))
        #expect(names.contains("Flour"))
        #expect(names.contains("Sugar"))
        #expect(names.contains("Eggs"))
    }

    @Test func addIngredients_itemCount_matchesIngredientCount() {
        let manager = makeManager()
        manager.addIngredients(from: recipe(ingredients: [ing("Butter"), ing("Milk"), ing("Vanilla")]))
        #expect(manager.items.count == 3)
    }

    @Test func addIngredients_emptyRecipe_addsNothing() {
        let manager = makeManager()
        manager.addIngredients(from: recipe(ingredients: []))
        #expect(manager.items.isEmpty)
    }

    // MARK: - Quantity conversion

    @Test func addIngredients_wholeQuantity_preserved() throws {
        let manager = makeManager()
        manager.addIngredients(from: recipe(ingredients: [ing("Butter", qty: 3.0)]))
        let item = try #require(manager.items.first)
        #expect(item.quantity == 3)
    }

    @Test func addIngredients_fractionalQuantity_roundedToNearestInt() throws {
        let manager = makeManager()
        manager.addIngredients(from: recipe(ingredients: [ing("Milk", qty: 1.5)]))
        let item = try #require(manager.items.first)
        #expect(item.quantity == 2)   // round(1.5) == 2
    }

    @Test func addIngredients_subHalfQuantity_floorCappedAtOne() throws {
        let manager = makeManager()
        manager.addIngredients(from: recipe(ingredients: [ing("Vanilla", qty: 0.25)]))
        let item = try #require(manager.items.first)
        #expect(item.quantity == 1)   // max(1, round(0.25)) == 1
    }

    @Test func addIngredients_zeroQuantity_defaultsToOne() throws {
        let manager = makeManager()
        manager.addIngredients(from: recipe(ingredients: [ing("Pinch of salt", qty: 0)]))
        let item = try #require(manager.items.first)
        #expect(item.quantity == 1)
    }

    // MARK: - Duplicate handling (ShoppingListManager merges by name)

    @Test func addIngredients_fromSameRecipeTwice_mergesQuantity() throws {
        let manager = makeManager()
        let r = recipe(ingredients: [ing("Flour", qty: 1.0)])
        manager.addIngredients(from: r)
        manager.addIngredients(from: r)

        #expect(manager.items.count == 1)
        let item = try #require(manager.items.first)
        #expect(item.quantity == 2)
    }

    @Test func addIngredients_sameIngredientTwoRecipes_merges() throws {
        let manager = makeManager()
        manager.addIngredients(from: recipe(name: "Soup", ingredients: [ing("Carrot", qty: 2.0)]))
        manager.addIngredients(from: recipe(name: "Stew", ingredients: [ing("Carrot", qty: 3.0)]))

        #expect(manager.items.count == 1)
        let item = try #require(manager.items.first)
        #expect(item.quantity == 5)
    }

    // MARK: - Check / uncheck

    @Test func newItems_areUnchecked() {
        let manager = makeManager()
        manager.addIngredients(from: recipe(ingredients: [ing("Onion"), ing("Garlic")]))
        #expect(manager.items.allSatisfy { !$0.isChecked })
    }

    @Test func toggleItem_checksAndUnchecks() {
        let manager = makeManager()
        manager.addIngredients(from: recipe(ingredients: [ing("Pepper")]))
        manager.toggleItem(at: 0)
        #expect(manager.items[0].isChecked)
        manager.toggleItem(at: 0)
        #expect(!manager.items[0].isChecked)
    }

    // MARK: - Delete

    @Test func deleteItem_removesFromList() {
        let manager = makeManager()
        manager.addIngredients(from: recipe(ingredients: [ing("Salt"), ing("Pepper")]))
        manager.deleteItem(at: 0)
        #expect(manager.items.count == 1)
    }

    @Test func clearCheckedItems_removesOnlyCheckedItems() {
        let manager = makeManager()
        manager.addIngredients(from: recipe(ingredients: [ing("Salt"), ing("Pepper"), ing("Cumin")]))
        manager.toggleItem(at: 0)    // check first item
        manager.clearCheckedItems()
        #expect(manager.items.count == 2)
        #expect(manager.items.allSatisfy { !$0.isChecked })
    }

    // MARK: - Multiple recipes

    @Test func addIngredients_fromTwoRecipes_allPresent() {
        let manager = makeManager()
        manager.addIngredients(from: recipe(name: "Soup",  ingredients: [ing("Carrot"), ing("Celery")]))
        manager.addIngredients(from: recipe(name: "Salad", ingredients: [ing("Lettuce"), ing("Tomato")]))
        let names = Set(manager.items.map(\.name))
        #expect(names.isSuperset(of: ["Carrot", "Celery", "Lettuce", "Tomato"]))
    }

    // MARK: - Persistence

    @Test func addIngredients_persistsAcrossManagerRestart() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = UserScopedStorage(userDefaults: defaults)
        let first = ShoppingListManager(storage: storage)
        first.addIngredients(from: recipe(ingredients: [ing("Oats", qty: 2.0)]))

        let second = ShoppingListManager(storage: storage)
        #expect(second.items.count == 1)
        #expect(second.items.first?.name == "Oats")
        #expect(second.items.first?.quantity == 2)
    }
}
