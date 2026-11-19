import Testing
@testable import RecipeFinder

@Suite("StepIngredientMatcher")
struct StepIngredientMatcherTests {

    private func ingredients(_ names: [String]) -> [Ingredient] {
        names.map { Ingredient(baseQuantity: 1, unit: "", name: $0) }
    }

    private func used(_ step: String, _ names: [String]) -> [Int] {
        StepIngredientMatcher.indices(usedIn: step, from: ingredients(names))
    }

    @Test("A step lists the ingredients it names, in recipe order")
    func namesInRecipeOrder() {
        let names = ["plain flour", "butter", "caster sugar", "eggs"]
        #expect(used("Beat the butter and sugar, then fold in the flour.", names) == [0, 1, 2])
    }

    @Test("A step that names no ingredient lists none")
    func noIngredients() {
        #expect(used("Preheat the oven to 180°C.", ["plain flour", "butter"]).isEmpty)
    }

    @Test("Amounts, prep notes and brackets in the ingredient line don't stop a match")
    func matchesOnMainName() {
        let names = ["2 cloves garlic, minced", "1 red onion (finely chopped)", "fresh basil"]
        #expect(used("Fry the onion and garlic, then tear over the basil.", names) == [0, 1, 2])
    }

    @Test("Singular and plural forms match each other", arguments: [
        ("Crack the egg into the bowl.", "eggs"),
        ("Add the eggs one at a time.", "egg"),
        ("Halve the tomato.", "tomatoes"),
        ("Roast the tomatoes.", "tomato"),
        ("Scatter the berries on top.", "berry"),
        ("Top with a berry.", "berries"),
    ])
    func plurals(step: String, name: String) {
        #expect(used(step, [name]) == [0])
    }

    @Test("A word inside a longer word isn't a match")
    func wordBoundaries() {
        // "oil" in "boil", "egg" in "eggplant", "rice" in "price".
        #expect(used("Bring to the boil, check the price.", ["olive oil", "rice"]).isEmpty)
        #expect(used("Slice the eggplant.", ["eggs"]).isEmpty)
    }

    @Test("A step may use the head word of a longer name ('the onion' for 'red onion')")
    func headWord() {
        #expect(used("Soften the onion.", ["red onion"]) == [0])
        #expect(used("Heat the oil in a pan.", ["olive oil"]) == [0])
    }

    @Test("The full name wins over another ingredient's head word")
    func fullNameClaimsHeadWord() {
        // "sesame oil" is named in full, so "oil" there doesn't also pull in the olive oil.
        #expect(used("Drizzle with sesame oil.", ["olive oil", "sesame oil"]) == [1])
    }

    @Test("Generic head words alone don't match ('powder', 'sauce', 'juice')")
    func genericHeadWordsSkipped() {
        #expect(used("Stir in the sauce.", ["soy sauce", "fish sauce"]).isEmpty)
        #expect(used("Add the powder.", ["chilli powder"]).isEmpty)
        #expect(used("Add the soy sauce.", ["soy sauce", "fish sauce"]) == [0])
    }

    @Test("Matching ignores case")
    func caseInsensitive() {
        #expect(used("ADD THE BUTTER.", ["Butter"]) == [0])
    }

    @Test("Blank ingredient names and blank steps are skipped")
    func blanks() {
        #expect(used("Add the butter.", ["", "  ", "butter"]) == [2])
        #expect(used("   ", ["butter"]).isEmpty)
    }

    @Test("Each ingredient is listed once however often the step names it")
    func listedOnce() {
        #expect(used("Add half the butter, then the rest of the butter.", ["butter"]) == [0])
    }

    // MARK: - CookingPlan

    @Test("The plan maps each item to its ingredients; the ingredient list itself has none")
    func planPerItem() {
        let plan = CookingPlan(prePrep: ["Chop the onion."], steps: ["Preheat the oven.", "Fry the onion in butter."])
        let list = ingredients(["butter", "onion"])
        let perItem = plan.ingredientIndices(from: list)
        #expect(perItem == [[], [1], [], [0, 1]])
    }
}
