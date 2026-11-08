import Testing
import Foundation
@testable import RecipeFinder

/// Pure recipe-ingredient → shopping-line mapping (regression: detail-view "add to groceries" dropped unit + quantity).
@Suite struct RecipeShoppingListTests {

    private func ing(_ name: String, qty: Double, unit: String) -> Ingredient {
        Ingredient(baseQuantity: qty, unit: unit, name: name)
    }

    @Test func carriesUnitAndQuantity() throws {
        let item = try #require(RecipeShoppingList.item(from: ing("flour", qty: 200, unit: "g")))
        #expect(item.quantity == 200)
        #expect(item.unit == "g")
        #expect(!item.name.isEmpty)
    }

    @Test func fractionalQuantityRoundsToNearestWhole() throws {
        let item = try #require(RecipeShoppingList.item(from: ing("milk", qty: 1.5, unit: "cups")))
        #expect(item.quantity == 2)
        #expect(item.unit == "cups")
    }

    @Test func subHalfQuantityFloorsAtOne() throws {
        let item = try #require(RecipeShoppingList.item(from: ing("vanilla", qty: 0.2, unit: "tsp")))
        #expect(item.quantity == 1)
    }

    @Test func unitlessIngredientKeepsEmptyUnit() throws {
        let item = try #require(RecipeShoppingList.item(from: ing("eggs", qty: 3, unit: "")))
        #expect(item.quantity == 3)
        #expect(item.unit == "")
    }

    @Test func emptyNameReturnsNil() {
        #expect(RecipeShoppingList.item(from: ing("", qty: 1, unit: "")) == nil)
    }

    // MARK: - Cupboard measures, unit step-down, scaling

    @Test func cupboardMeasureBecomesOneUnitlessItem() throws {
        let item = try #require(RecipeShoppingList.item(from: ing("salt", qty: 0.125, unit: "tsp")))
        #expect(item.quantity == 1)
        #expect(item.unit == "")   // "Salt", not "1 tsp" rounded up from ⅛
    }

    @Test func fractionalKilogramsStepDownToGrams() throws {
        let item = try #require(RecipeShoppingList.item(from: ing("potatoes", qty: 0.5, unit: "kg")))
        #expect(item.quantity == 500)
        #expect(item.unit == "g")
    }

    @Test func wholeKilogramsKeepTheirUnit() throws {
        let item = try #require(RecipeShoppingList.item(from: ing("potatoes", qty: 2, unit: "kg")))
        #expect(item.quantity == 2)
        #expect(item.unit == "kg")
    }

    @Test func scaleFactorAppliesToTheAmount() throws {
        let item = try #require(RecipeShoppingList.item(from: ing("flour", qty: 200, unit: "g"), scaleFactor: 2))
        #expect(item.quantity == 400)
    }
}
