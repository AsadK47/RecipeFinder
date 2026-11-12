import Testing
import Foundation
@testable import RecipeFinder

/// Today's "Use it up" row: which kitchen items are going off and which recipe each is paired with.
@Suite struct UseSoonTests {

    private let cal: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_GB")
        cal.timeZone = TimeZone(identifier: "Europe/London") ?? .current
        return cal
    }()

    /// Monday 9 Nov 2026, 10:00 London.
    private var now: Date {
        cal.date(from: DateComponents(year: 2026, month: 11, day: 9, hour: 10)) ?? Date()
    }

    private func item(_ name: String, days: Int?, quantity: Double = 1) -> KitchenInventoryModel {
        KitchenInventoryModel(
            name: name, category: .produce, quantity: quantity, unit: "",
            // Late in the day, so it's the calendar day that counts, not 24-hour blocks.
            expiryDate: days.flatMap { cal.date(byAdding: .day, value: $0, to: now) }
                .flatMap { cal.date(bySettingHour: 23, minute: 0, second: 0, of: $0) }
        )
    }

    private func recipe(_ name: String, _ ingredients: [String], favourite: Bool = false, sample: Bool = false) -> RecipeModel {
        RecipeModel(
            name: name, category: "Main", difficulty: "Basic", prepTime: "5 min", cookingTime: "10 min",
            baseServings: 2, ingredients: ingredients.map { Ingredient(baseQuantity: 1, unit: "", name: $0) },
            prePrepInstructions: [], instructions: ["Cook"], notes: "",
            isFavorite: favourite, isSampleRecipe: sample
        )
    }

    private func pairs(_ items: [KitchenInventoryModel], _ recipes: [RecipeModel], kitchen: [String] = []) -> [UseSoonPair] {
        UseSoon.pairs(items: items, recipes: recipes, kitchenItemNames: kitchen, now: now, calendar: cal)
    }

    // MARK: Which items

    @Test(arguments: [0, 1, 2, 3])
    func itemsGoingOffWithinThreeDaysArePaired(days: Int) {
        let saag = recipe("Saag paneer", ["spinach", "paneer"])
        #expect(pairs([item("Spinach", days: days)], [saag]).map(\.recipe) == [saag])
    }

    @Test(arguments: [-1, 4, 30])
    func itemsExpiredOrFurtherOffAreLeftOut(days: Int) {
        #expect(pairs([item("Spinach", days: days)], [recipe("Saag paneer", ["spinach"])]).isEmpty)
    }

    @Test func itemsWithoutADateOrUsedUpAreLeftOut() {
        let saag = recipe("Saag paneer", ["spinach", "paneer"])
        #expect(pairs([item("Spinach", days: nil), item("Paneer", days: 1, quantity: 0)], [saag]).isEmpty)
    }

    @Test func anItemNoRecipeUsesIsLeftOut() {
        let result = pairs([item("Kale", days: 1), item("Spinach", days: 2)], [recipe("Saag paneer", ["spinach"])])
        #expect(result.map(\.itemNames) == [["Spinach"]])
    }

    @Test func soonestFirstAndCappedAtTheLimit() {
        let items = [item("Milk", days: 3), item("Spinach", days: 0), item("Feta", days: 2), item("Leeks", days: 1)]
        let recipes = [
            recipe("Rice pudding", ["milk"]), recipe("Saag", ["spinach"]),
            recipe("Feta salad", ["feta"]), recipe("Leek soup", ["leeks"])
        ]
        let result = pairs(items, recipes)
        #expect(result.map(\.itemNames) == [["Spinach"], ["Leeks"], ["Feta"]])
        #expect(result.count == UseSoon.limit)
    }

    @Test func theSameIngredientTwiceShowsOnceAtItsSoonestDate() {
        let result = pairs([item("Spinach", days: 3), item("spinach ", days: 1)], [recipe("Saag", ["spinach"])])
        #expect(result.count == 1)
        #expect(result.first?.daysLeft == 1)
    }

    // MARK: Which recipe

    @Test func aRecipeUsingMoreOfWhatsGoingOffWins() {
        // The soup is first by name and the kitchen covers all of it, so only "uses more of what's going off" picks the pie.
        let soup = recipe("A spinach soup", ["spinach", "stock"])
        let pie = recipe("Z spinach and feta pie", ["spinach", "feta", "pastry"])
        let result = pairs([item("Spinach", days: 1), item("Feta", days: 2)], [soup, pie], kitchen: ["Stock"])
        #expect(result.first?.recipe == pie)
    }

    @Test func thenTheRecipeTheKitchenCoversMostOf() {
        // First by name, so only kitchen coverage puts the saag ahead.
        let curry = recipe("A spinach curry", ["spinach", "coconut milk", "lentils"])
        let saag = recipe("Saag paneer", ["spinach", "paneer", "garam masala"])
        let result = pairs([item("Spinach", days: 1)], [curry, saag], kitchen: ["Paneer", "Garam masala"])
        #expect(result.first?.recipe == saag)
    }

    @Test func thenFavouritesThenYourOwnOverSamples() {
        let sample = recipe("A sample", ["spinach"], sample: true)
        let own = recipe("B own", ["spinach"])
        let favourite = recipe("C favourite", ["spinach"], favourite: true)
        #expect(pairs([item("Spinach", days: 1)], [sample, own, favourite]).first?.recipe == favourite)
        #expect(pairs([item("Spinach", days: 1)], [sample, own]).first?.recipe == own)
    }

    @Test func eachItemGetsItsOwnRecipeWhenThereIsOne() {
        let pie = recipe("Spinach and feta pie", ["spinach", "feta"])
        let salad = recipe("Greek salad", ["feta", "tomato"])
        let result = pairs([item("Spinach", days: 1), item("Feta", days: 2)], [pie, salad])
        #expect(result.map(\.recipe) == [pie, salad])
    }

    @Test func anItemWhoseRecipesAreTakenJoinsThatRow() {
        let pie = recipe("Spinach and feta pie", ["spinach", "feta"])
        let result = pairs([item("Spinach", days: 1), item("Feta", days: 2)], [pie])
        #expect(result.count == 1)
        #expect(result.first?.itemNames == ["Spinach", "Feta"])
        #expect(result.first?.message == "Spinach and Feta go off tomorrow")
    }

    @Test func withTheRowsFullAnItemJoinsAShownRecipeThatUsesIt() {
        let items = [item("Spinach", days: 0), item("Leeks", days: 1), item("Feta", days: 2), item("Milk", days: 3)]
        let recipes = [
            recipe("Saag", ["spinach"]), recipe("Leek soup", ["leeks"]),
            recipe("Feta and milk bake", ["feta", "milk"]), recipe("Rice pudding", ["milk"])
        ]
        let result = pairs(items, recipes)
        #expect(result.count == UseSoon.limit)
        #expect(result.last?.itemNames == ["Feta", "Milk"])
    }

    @Test func threeNamesReadAsAList() {
        let traybake = recipe("Traybake", ["leeks", "feta", "spinach"])
        let result = pairs([item("Leeks", days: 1), item("Feta", days: 1), item("Spinach", days: 1)], [traybake])
        #expect(result.first?.message == "Feta, Leeks and Spinach go off tomorrow")
    }

    @Test func wholeWordsOnlySoGingerIsNotGin() {
        #expect(pairs([item("Gin", days: 1)], [recipe("Stir fry", ["ginger"])]).isEmpty)
    }

    // MARK: Wording

    @Test(arguments: [(0, "Spinach goes off today"), (1, "Spinach goes off tomorrow"), (3, "Spinach goes off Thu")])
    func messageSaysWhenItGoesOff(days: Int, expected: String) {
        #expect(pairs([item("Spinach", days: days)], [recipe("Saag", ["spinach"])]).first?.message == expected)
    }
}
