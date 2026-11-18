import Foundation
import Testing
@testable import RecipeFinder

/// Me's taste fingerprint: which traits a recipe has, and how cooks weight them.
@Suite("TasteFingerprint")
struct TasteFingerprintTests {

    private func recipe(_ name: String, category: String = "Main", prep: String = "20 min", cook: String = "40 min",
                        ingredients: [String] = [], instructions: [String] = ["Cook"], tags: [String] = [],
                        cookCount: Int = 1) -> RecipeModel {
        RecipeModel(
            name: name, category: category, difficulty: "Easy", prepTime: prep, cookingTime: cook,
            baseServings: 2,
            ingredients: ingredients.map { Ingredient(baseQuantity: 1, unit: "", name: $0) },
            prePrepInstructions: [], instructions: instructions, notes: "", tags: tags, cookCount: cookCount
        )
    }

    private func traits(_ recipe: RecipeModel) -> Set<TasteTrait> {
        TasteFingerprint.traits(of: recipe)
    }

    // MARK: - Traits of one recipe

    @Test("a chilli in the ingredients makes a dish spicy")
    func chilliIngredientIsSpicy() {
        #expect(traits(recipe("Chicken Karahi", ingredients: ["green chillies", "chicken"])).contains(.spicy))
    }

    @Test("a plain dish has no traits")
    func plainDishHasNone() {
        #expect(traits(recipe("Boiled Rice", ingredients: ["rice", "water"])).isEmpty)
    }

    @Test("a 'Spicy' tag counts, whatever its case")
    func spicyTag() {
        #expect(traits(recipe("Rice", tags: ["  spicy "])).contains(.spicy))
    }

    @Test("an optional, mild, sweet or colouring chilli doesn't make a dish spicy", arguments: [
        "sriracha sauce, optional", "kashmiri chilli powder", "mild chilli powder", "sweet chilli sauce",
    ])
    func notHotChilli(line: String) {
        #expect(!traits(recipe("Mac and Cheese", ingredients: [line, "macaroni"])).contains(.spicy))
    }

    @Test("a sweet or mild chilli in the name isn't spicy; other heat in the name still is", arguments: [
        ("Sweet Chilli Chicken", false), ("Sweet Chili Salmon", false), ("Mild Chilli Beef", false),
        ("Sweet-Chilli Prawns", false), ("Sweet  Chilli Tofu", false),
        ("Sweet Chilli Jalfrezi", true), ("Chilli Chicken", true),
    ])
    func notHotChilliName(name: String, spicy: Bool) {
        #expect(traits(recipe(name)).contains(.spicy) == spicy)
    }

    @Test("buffalo mozzarella isn't spicy; buffalo wings are")
    func buffalo() {
        #expect(!traits(recipe("Buffalo Mozzarella Salad")).contains(.spicy))
        #expect(traits(recipe("Buffalo Wings")).contains(.spicy))
    }

    @Test("hot chocolate isn't spicy")
    func hotChocolateIsNotSpicy() {
        #expect(!traits(recipe("Hot Chocolate", category: "Drink", ingredients: ["milk", "cocoa"])).contains(.spicy))
    }

    @Test("soups, stews and curries are comforting", arguments: [
        ("Tomato Soup", "Soup"), ("Beef Stew", "Main"), ("Chicken Curries", "Main"), ("Chana Dal", "Main"),
        ("Mac and Cheese", "Main"),
    ])
    func comforting(name: String, category: String) {
        #expect(traits(recipe(name, category: category)).contains(.comforting))
    }

    @Test("a soup by category is comforting, whatever its name")
    func soupCategory() {
        #expect(traits(recipe("Pho Ga", category: "Soup")).contains(.comforting))
    }

    @Test("a short word doesn't match inside a longer one")
    func dalNotInsideMedallions() {
        #expect(!traits(recipe("Pork Medallions")).contains(.comforting))
    }

    @Test("an 'Instant Pot' dish isn't comforting for the pot alone")
    func instantPotIsNotComforting() {
        #expect(!traits(recipe("Instant Pot Rice")).contains(.comforting))
    }

    @Test("30 minutes or less in total is quick; longer or unknown isn't", arguments: [
        ("10 min", "20 min", true), ("10 min", "21 min", false), ("", "", false),
    ])
    func quick(prep: String, cook: String, isQuick: Bool) {
        #expect(traits(recipe("Rice", prep: prep, cook: cook)).contains(.quick) == isQuick)
    }

    @Test("a 'Quick' tag makes a long recipe quick")
    func quickTag() {
        #expect(traits(recipe("Rice", prep: "1 hour", cook: "1 hour", tags: ["Quick"])).contains(.quick))
    }

    @Test("baked goods by name are baking")
    func bakedGoodsByName() {
        #expect(traits(recipe("Banana Bread", category: "Dessert")).contains(.baking))
        #expect(traits(recipe("Chocolate Brownies", category: "Dessert")).contains(.baking))
    }

    @Test("a dessert whose method bakes is baking")
    func dessertThatBakes() {
        #expect(traits(recipe("Apple Thing", category: "Dessert", instructions: ["Bake for 30 minutes"]))
            .contains(.baking))
    }

    @Test("baking powder or a baking tray in a pancake's method isn't baking")
    func bakingPowderIsNotBaking() {
        let pancakes = recipe("American Pancakes", category: "Breakfast", ingredients: ["baking powder"],
                              instructions: ["Whisk the flour and baking powder", "Fry on a baking tray-sized pan"])
        #expect(!traits(pancakes).contains(.baking))
    }

    @Test("steamed buns and cakes aren't baking; baked buns are", arguments: [
        ("Black Sesame Steamed Buns", false), ("Bao Buns", false), ("Radish Cake", false), ("Milk Buns", true),
    ])
    func steamedIsNotBaking(name: String, isBaking: Bool) {
        #expect(traits(recipe(name, category: "Dessert")).contains(.baking) == isBaking)
    }

    @Test("a baked dinner isn't baking")
    func bakedDinnerIsNotBaking() {
        #expect(!traits(recipe("Tuna Pasta Bake", instructions: ["Bake for 30 minutes"])).contains(.baking))
    }

    @Test("a salad is fresh")
    func saladIsFresh() {
        #expect(traits(recipe("Greek Salad", category: "Side")).contains(.fresh))
    }

    @Test("three fresh ingredients make a dish fresh; two don't")
    func freshIngredients() {
        let three = recipe("Fish", ingredients: ["lime", "fresh coriander", "cucumber"])
        let two = recipe("Fish", ingredients: ["lime", "fresh coriander", "salt"])
        #expect(traits(three).contains(.fresh))
        #expect(!traits(two).contains(.fresh))
    }

    @Test("dried, ground or bottled herbs and citrus aren't fresh")
    func driedIsNotFresh() {
        let curry = recipe("Nihari", ingredients: ["coriander powder", "coriander seeds", "avocado oil",
                                                   "dried parsley", "mint sauce", "lemon juice"])
        #expect(!traits(curry).contains(.fresh))
    }

    @Test("the same fresh ingredient twice counts once")
    func freshWordsAreDistinct() {
        #expect(!traits(recipe("Fish", ingredients: ["lemon juice", "lemon wedges", "lime"])).contains(.fresh))
    }

    @Test("one recipe can have several traits")
    func severalTraits() {
        let dish = recipe("Spicy Chicken Soup", category: "Soup", prep: "5 min", cook: "20 min")
        #expect(traits(dish) == [.spicy, .comforting, .quick])
    }

    // MARK: - Fingerprint over the cook's history

    @Test("nothing cooked → empty, every trait at zero")
    func nothingCooked() {
        let taste = TasteFingerprint.from(recipes: [recipe("Beef Stew", cookCount: 0)])
        #expect(taste.isEmpty)
        #expect(taste.totalCooks == 0)
        #expect(taste.shares.map(\.trait) == TasteTrait.allCases)
        #expect(taste.shares.allSatisfy { $0.cooks == 0 && $0.share == 0 && $0.recipeIDs.isEmpty })
        #expect(taste.strongest == nil)
    }

    @Test("shares are weighted by how often each dish was cooked")
    func weightedByCooks() {
        let stew = recipe("Beef Stew", cookCount: 3)
        let rice = recipe("Boiled Rice", cookCount: 1)
        let taste = TasteFingerprint.from(recipes: [stew, rice])
        #expect(taste.totalCooks == 4)
        #expect(taste.share(.comforting)?.cooks == 3)
        #expect(taste.share(.comforting)?.percent == 75)
        #expect(taste.share(.spicy)?.share == 0)
    }

    @Test("uncooked recipes in the library don't count")
    func uncookedIgnored() {
        let taste = TasteFingerprint.from(recipes: [recipe("Beef Stew", cookCount: 1),
                                                    recipe("Greek Salad", cookCount: 0)])
        #expect(taste.share(.fresh)?.cooks == 0)
        #expect(taste.share(.comforting)?.share == 1)
    }

    @Test("a trait's recipes are listed most cooked first, then by name")
    func recipesOrdered() {
        let stew = recipe("Beef Stew", cookCount: 1)
        let curry = recipe("Lamb Curry", cookCount: 4)
        let soup = recipe("Apple Soup", category: "Soup", cookCount: 1)
        let taste = TasteFingerprint.from(recipes: [stew, curry, soup])
        #expect(taste.share(.comforting)?.recipeIDs == [curry.id, soup.id, stew.id])
    }

    @Test("the headline names the biggest trait with its count")
    func headline() {
        let taste = TasteFingerprint.from(recipes: [recipe("Spicy Noodles", cookCount: 6),
                                                    recipe("Boiled Rice", cookCount: 4)])
        #expect(taste.headline == "You lean towards spicy food — 6 of 10 meals")
    }

    @Test("a tie goes by a fixed order, so the headline is stable", arguments: [
        ("Greek Salad", "Beef Stew", TasteTrait.comforting), ("Spicy Rice", "Beef Stew", TasteTrait.comforting),
        ("Spicy Rice", "Greek Salad", TasteTrait.fresh),
    ])
    func tieOrder(first: String, second: String, winner: TasteTrait) {
        let taste = TasteFingerprint.from(recipes: [recipe(first, cookCount: 2), recipe(second, cookCount: 2)])
        #expect(taste.strongest?.trait == winner)
    }

    @Test("cooked meals with no trait yet hide the card, not five empty bars")
    func noTraitIsEmpty() {
        let taste = TasteFingerprint.from(recipes: [recipe("Boiled Rice", cookCount: 1)])
        #expect(taste.totalCooks == 1)
        #expect(taste.isEmpty)
        #expect(taste.headline == nil)
    }

    @Test("a trait's recipes come back in its order, skipping ones deleted since")
    func recipesBehindTrait() {
        let stew = recipe("Beef Stew", cookCount: 1)
        let curry = recipe("Lamb Curry", cookCount: 4)
        let rice = recipe("Boiled Rice", cookCount: 2)
        let taste = TasteFingerprint.from(recipes: [stew, curry, rice])
        #expect(taste.recipes(behind: .comforting, in: [rice, stew, curry]).map(\.id) == [curry.id, stew.id])
        #expect(taste.recipes(behind: .comforting, in: [rice, stew]).map(\.id) == [stew.id])
        #expect(taste.recipes(behind: .fresh, in: [rice, stew, curry]).isEmpty)
    }

    @Test("one meal reads 'meal', not 'meals'")
    func singularMeal() {
        let taste = TasteFingerprint.from(recipes: [recipe("Beef Stew", cookCount: 1)])
        #expect(taste.headline == "You lean towards comfort food — 1 of 1 meal")
    }
}
