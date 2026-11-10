import Testing
@testable import RecipeFinder

/// Missing-amount detection drives the full-width "no amount" row and the "add your amounts" card on recipe detail.
@Suite("Ingredient amount gaps")
struct IngredientAmountGapsTests {

    private func ingredient(_ name: String, _ quantity: Double) -> Ingredient {
        Ingredient(baseQuantity: quantity, unit: "", name: name)
    }

    @Test("A core ingredient with no amount is a gap", arguments: ["self-raising flour", "boneless chicken thighs", "salt"])
    func coreIngredientWithoutAmountIsMissing(name: String) {
        #expect(ingredient(name, 0).isMissingAmount)
    }

    @Test("Ingredients that never need an amount are not gaps", arguments: [
        "salt and pepper", "fresh coriander, to garnish", "oil, for frying", "ice cubes", "icing sugar, to dust",
        "salt, to taste", "chilli flakes, optional", "lukewarm water, for dipping the rice paper"
    ])
    func amountOptionalIngredientsAreNotMissing(name: String) {
        #expect(!ingredient(name, 0).isMissingAmount)
    }

    @Test("An ingredient with an amount is never a gap")
    func ingredientWithAmountIsNotMissing() {
        #expect(!ingredient("flour", 300).isMissingAmount)
    }

    @Test("Mostly missing when at least half the ingredients lack a needed amount")
    func mostlyMissingThreshold() {
        let half = [ingredient("flour", 0), ingredient("sugar", 100)]
        let fewer = [ingredient("flour", 0), ingredient("sugar", 100), ingredient("eggs", 2)]
        let onlyOptional = [ingredient("salt, to taste", 0), ingredient("sugar", 100)]
        #expect(IngredientAmountGaps.isMostlyMissing(half))
        #expect(!IngredientAmountGaps.isMostlyMissing(fewer))
        #expect(!IngredientAmountGaps.isMostlyMissing(onlyOptional))
        #expect(!IngredientAmountGaps.isMostlyMissing([]))
    }

    @Test("An amount-less row offers Add amount only when editing is wired and the amount is needed")
    func addAmountButtonVisibility() {
        let flour = ingredient("flour", 0)
        let none: (quantity: String?, unit: String?) = (nil, nil)
        #expect(IngredientRowView.showsAddAmount(for: flour, amount: none, canEdit: true))
        #expect(!IngredientRowView.showsAddAmount(for: flour, amount: none, canEdit: false))
        #expect(!IngredientRowView.showsAddAmount(for: ingredient("salt, to taste", 0), amount: none, canEdit: true))
        #expect(!IngredientRowView.showsAddAmount(for: ingredient("flour", 300), amount: ("300", "g"), canEdit: true))
    }
}
