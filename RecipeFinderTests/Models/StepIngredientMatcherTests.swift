import Testing
@testable import RecipeFinder

@Suite("StepIngredientMatcher")
struct StepIngredientMatcherTests {

    private func ingredients(_ names: [String]) -> [Ingredient] {
        names.map { Ingredient(baseQuantity: 1, unit: "", name: $0) }
    }

    private func uses(_ step: String, _ names: [String]) -> [StepIngredientMatcher.Use] {
        StepIngredientMatcher.uses(in: step, from: ingredients(names))
    }

    private func used(_ step: String, _ names: [String]) -> [Int] {
        uses(step, names).map(\.index)
    }

    // MARK: - Names

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
        ("Add the chilli.", "green chillies"),
        ("Add the chillies.", "chilli"),
        ("Slice the peach.", "peaches"),
        ("Add the radishes.", "radish"),
    ])
    func plurals(step: String, name: String) {
        #expect(used(step, [name]) == [0])
    }

    @Test("A word inside a longer word isn't a match")
    func wordBoundaries() {
        // "oil" in "boil", "rice" in "price", "egg" in "eggplant".
        #expect(used("Bring to the boil, check the price.", ["olive oil", "rice"]).isEmpty)
        #expect(used("Slice the eggplant.", ["eggs"]).isEmpty)
    }

    @Test("A step may use the head word of a longer name ('the onion' for 'red onion')")
    func headWord() {
        #expect(used("Soften the onion.", ["red onion"]) == [0])
        #expect(used("Heat the oil in a pan.", ["olive oil"]) == [0])
    }

    @Test("A step may use the last two words of a longer name ('soy sauce' for 'light soy sauce')")
    func lastTwoWords() {
        #expect(used("Add the soy sauce.", ["light soy sauce"]) == [0])
    }

    @Test("A cut is named by its meat ('the chicken' for 'chicken breast', 'the cinnamon' for a stick)")
    func cutWords() {
        #expect(used("Add the chicken and cinnamon.", ["chicken breast, cut into strips", "cinnamon stick"]) == [0, 1])
    }

    // MARK: - Longer names win

    @Test("A longer name claims its words from a shorter one", arguments: [
        ("Drizzle with sesame oil.", ["olive oil", "sesame oil"], [1]),
        ("Add the spring onions.", ["onion", "spring onions"], [1]),
        ("Stir in the garlic powder.", ["garlic", "garlic powder"], [1]),
        ("Mix the soy sauce and red pepper flakes.", ["red bell pepper", "light soy sauce"], [1]),
        ("Fry the spring onions, then scatter over more spring onions.", ["onion", "spring onions"], [1]),
        ("Drizzle with sesame oil and toss; finish with sesame oil.", ["olive oil", "sesame oil"], [1]),
    ])
    func longerNameWins(step: String, names: [String], expected: [Int]) {
        #expect(used(step, names) == expected)
    }

    @Test("A word that starts another ingredient isn't that word's ingredient", arguments: [
        ("Stir in the tomato paste.", ["ripe tomatoes"]),
        ("Add the chilli flakes.", ["red chilli"]),
        ("Pour in the coconut milk.", ["shredded coconut"]),
        ("Add the chicken stock.", ["chicken thighs"]),
    ])
    func compoundIsAnotherIngredient(step: String, names: [String]) {
        #expect(used(step, names).isEmpty)
    }

    @Test("'Garlic cloves' is garlic, not the spice cloves")
    func garlicCloves() {
        #expect(used("Add 2 chopped garlic cloves.", ["garlic", "cloves"]) == [0])
        #expect(used("Toast the cloves.", ["garlic", "cloves"]) == [1])
    }

    @Test("Generic head words alone don't match ('sauce', 'powder')")
    func genericHeadWordsSkipped() {
        #expect(used("Stir in the sauce.", ["soy sauce", "fish sauce"]).isEmpty)
        #expect(used("Add the powder.", ["chilli powder"]).isEmpty)
        #expect(used("Add the soy sauce.", ["soy sauce", "fish sauce"]) == [0])
    }

    @Test("Either side of an 'or' names the ingredient; a bare adjective borrows the head ('white or rice vinegar')")
    func alternatives() {
        #expect(used("Add the water.", ["vegetable stock or water"]) == [0])
        #expect(used("Add the white vinegar.", ["white or rice vinegar"]) == [0])
        #expect(used("Whisk the egg whites.", ["white or rice vinegar"]).isEmpty)
    }

    @Test("'Without oil' doesn't list the oil")
    func negation() {
        #expect(used("Put the chicken in a pot without oil.", ["chicken", "oil"]) == [0])
    }

    // MARK: - Amounts

    @Test("A step that sets its own amount says so", arguments: [
        "Heat 1 tbsp oil in a wok.",
        "Add the remaining oil.",
        "Add half the oil.",
        "Add ½ the oil.",
    ])
    func stepGivesAmount(step: String) {
        #expect(uses(step, ["oil"]) == [.init(index: 0, stepGivesAmount: true)])
    }

    @Test("A step with no amount of its own uses the recipe's amount")
    func recipeAmount() {
        #expect(uses("Heat the oil.", ["oil"]) == [.init(index: 0, stepGivesAmount: false)])
        // A number in an earlier clause isn't this ingredient's amount.
        #expect(uses("Bake for 20 minutes, then add the oil.", ["oil"]) == [.init(index: 0, stepGivesAmount: false)])
    }

    @Test("Another ingredient's amount isn't this one's ('2 eggs and the butter')")
    func neighbourAmount() {
        #expect(uses("Add 2 eggs and the butter.", ["eggs", "butter"])
            == [.init(index: 0, stepGivesAmount: true), .init(index: 1, stepGivesAmount: false)])
        #expect(uses("Add half the butter and sugar.", ["butter", "sugar"])
            == [.init(index: 0, stepGivesAmount: true), .init(index: 1, stepGivesAmount: false)])
    }

    // MARK: - Edges

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

    // MARK: - Real bundled recipe steps (Chicken Chow Mein, Tofu Stir Fry)

    @Test("A bundled stir-fry step lists what it uses and nothing it doesn't")
    func bundledChowMeinStep() {
        let names = ["dried medium egg noodles", "chicken breast, cut into 1 cm strips", "oil", "onion, sliced",
                     "jalapeño chilli, finely chopped", "fresh ginger, peeled and grated", "garlic, finely chopped",
                     "chilli powder", "chilli and garlic sauce", "spring onions, finely chopped"]
        let step = "Add the chicken, chilli, ginger and garlic and cook for about 25 minutes, until the chicken is "
            + "cooked through and only a little moisture is left."
        #expect(used(step, names) == [1, 4, 5, 6])
        #expect(used("Add the chilli and garlic sauce and sriracha and stir-fry for another 2-3 minutes.", names) == [8])
    }

    @Test("A bundled sauce step doesn't read 'pepper flakes' as the bell pepper")
    func bundledTofuSauceStep() {
        let names = ["vegetable stock or water", "soy sauce", "brown sugar", "cornstarch", "red pepper flakes, optional",
                     "oil, divided", "firm tofu, drained and cubed", "red bell pepper, julienned"]
        let step = "Mix all the sauce ingredients (stock, soy sauce, sugar, cornstarch and pepper flakes) until combined."
        #expect(used(step, names) == [1, 2, 3, 4])
    }

    // MARK: - CookingPlan

    @Test("The plan maps each item to its ingredients; the ingredient list itself has none")
    func planPerItem() {
        let plan = CookingPlan(prePrep: ["Chop the onion."], steps: ["Preheat the oven.", "Fry the onion in butter."])
        let perItem = plan.ingredientUses(from: ingredients(["butter", "onion"])).map { $0.map(\.index) }
        #expect(perItem == [[], [1], [], [0, 1]])
    }

    // MARK: - Lines shown under a step

    @MainActor
    @Test("Lines show the recipe amount, scaled, or just the name when the step sets its own")
    func lines() {
        let list = [Ingredient(baseQuantity: 100, unit: "g", name: "butter"),
                    Ingredient(baseQuantity: 2, unit: "tbsp", name: "oil")]
        let shown = CookingStepIngredients.lines(
            for: [.init(index: 0, stepGivesAmount: false), .init(index: 1, stepGivesAmount: true),
                  .init(index: 5, stepGivesAmount: false)],
            in: list, scaleFactor: 2, system: .metric)
        #expect(shown == ["200 g \(list[0].displayName)", list[1].displayName])
    }
}
