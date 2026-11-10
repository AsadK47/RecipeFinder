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

/// "Estimate amounts": the request the on-device model sees and how accepted estimates merge back. The FoundationModels
/// call itself is exempt (Apple framework internals) — tested here through the `IngredientAmountEstimating` seam.
@Suite("Ingredient amount estimates")
struct IngredientAmountEstimateTests {

    private let ingredients = [
        Ingredient(baseQuantity: 0, unit: "", name: "plain flour"),
        Ingredient(baseQuantity: 100, unit: "g", name: "caster sugar"),
        Ingredient(baseQuantity: 0, unit: "", name: "salt, to taste"),
        Ingredient(baseQuantity: 0, unit: "", name: "eggs")
    ]

    private func request(steps: [String] = ["Mix", "Bake"]) -> AmountEstimateRequest? {
        AmountEstimateRequest(recipeName: "Sponge", servings: 8, ingredients: ingredients, steps: steps)
    }

    @Test("No request when nothing is missing")
    func noRequestWithoutGaps() {
        let complete = [Ingredient(baseQuantity: 2, unit: "", name: "eggs")]
        #expect(AmountEstimateRequest(recipeName: "Eggs", servings: 1, ingredients: complete, steps: []) == nil)
    }

    @Test("Only real gaps are marked missing, not to-taste lines")
    func missingIndicesSkipOptional() throws {
        #expect(try #require(request()).missingIndices == [0, 3])
    }

    @Test("Prompt lists every ingredient numbered, with known amounts and gaps marked")
    func promptShape() throws {
        let prompt = try #require(request()).prompt
        #expect(prompt.contains("Recipe: Sponge (serves 8)"))
        #expect(prompt.contains("1. Plain flour — MISSING"))
        #expect(prompt.contains("2. Caster sugar — 100 g"))
        #expect(prompt.contains("3. Salt, to taste — no amount needed"))
        #expect(prompt.contains("4. Eggs — MISSING"))
        #expect(prompt.contains("Method:\n- Mix\n- Bake"))
    }

    @Test("Long methods are capped to fit the on-device context")
    func stepsCapped() throws {
        let steps = (1...20).map { "Step \($0)" }
        #expect(try #require(request(steps: steps)).steps.count == AmountEstimateRequest.maxSteps)
    }

    @Test("Accepted estimates fill gaps and keep the ingredient's id and name")
    func applyFillsGaps() {
        let result = AmountEstimateApplier.apply(
            [AmountEstimate(index: 0, quantity: 200, unit: " g "), AmountEstimate(index: 3, quantity: 3, unit: "")],
            to: ingredients
        )
        #expect(result[0].baseQuantity == 200)
        #expect(result[0].unit == "g")
        #expect(result[0].id == ingredients[0].id)
        #expect(result[0].displayName == ingredients[0].displayName)
        #expect(result[3].baseQuantity == 3)
    }

    @Test("Estimates never overwrite given amounts, optional lines, bad values or unknown rows", arguments: [
        AmountEstimate(index: 1, quantity: 500, unit: "g"),   // sugar already has 100 g
        AmountEstimate(index: 2, quantity: 1, unit: "tsp"),   // salt, to taste
        AmountEstimate(index: 0, quantity: 0, unit: "g"),
        AmountEstimate(index: 0, quantity: -5, unit: "g"),
        AmountEstimate(index: 0, quantity: .infinity, unit: "g"),
        AmountEstimate(index: 9, quantity: 1, unit: "")
    ])
    func applyIgnoresInvalid(estimate: AmountEstimate) {
        let result = AmountEstimateApplier.apply([estimate], to: ingredients)
        #expect(result.map(\.baseQuantity) == ingredients.map(\.baseQuantity))
        #expect(result.map(\.unit) == ingredients.map(\.unit))
    }

    @Test("First estimate for an ingredient wins")
    func firstEstimateWins() {
        let result = AmountEstimateApplier.apply(
            [AmountEstimate(index: 0, quantity: 200, unit: "g"), AmountEstimate(index: 0, quantity: 50, unit: "g")],
            to: ingredients
        )
        #expect(result[0].baseQuantity == 200)
    }

    @Test("Devices without the on-device model decline")
    func unavailableDeclines() async throws {
        let request = try #require(request())
        #expect(try await UnavailableIngredientAmountEstimator().estimateAmounts(for: request) == nil)
    }
}
