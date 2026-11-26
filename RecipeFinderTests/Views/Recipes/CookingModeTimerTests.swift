import Testing
@testable import RecipeFinder

/// The cook-mode step-timer extractor only counts numbers with an explicit time
/// unit, so temperatures and counts don't get read as a duration.
// @MainActor: `CookingIngredientChecklist.line` is a static on a View (main-actor), like BundledRecipeRenderAuditTests.
@MainActor
@Suite("CookingMode step timer + checklist")
struct CookingModeTimerTests {

    @Test("ignores temperatures, reads the real duration")
    func ignoresTemperature() {
        #expect(CookingPlan.timerMinutes(in: "Cook at 350°F for 12 minutes") == 12)
    }

    @Test("sums hours and minutes")
    func sumsHoursAndMinutes() {
        #expect(CookingPlan.timerMinutes(in: "Simmer for 1 hour 30 minutes") == 90)
    }

    @Test("bare numbers / counts are not a timer")
    func bareNumbersIgnored() {
        #expect(CookingPlan.timerMinutes(in: "Whisk 2 eggs and 200 g flour") == nil)
    }

    @Test("no time phrase → nil")
    func noTime() {
        #expect(CookingPlan.timerMinutes(in: "Season to taste") == nil)
    }

    @Test("abbreviations and 'mins' work")
    func abbreviations() {
        #expect(CookingPlan.timerMinutes(in: "Bake 25 mins") == 25)
    }

    @Test("separate mentions aren't summed — the first duration wins (regression: 6h + 48h became a 3240-min timer)")
    func separateMentionsNotSummed() {
        #expect(CookingPlan.timerMinutes(in: "Marinate for at least 6 hours, up to 48 hours") == 360)
        #expect(CookingPlan.timerMinutes(in: "Broil for 4-5 minutes, then serve within 6 minutes") == 4)
    }

    // Owner 2026-11-25 (CHALLENGES 404): word amounts and fractions get a timer; a range takes its lower bound,
    // so the cook checks early rather than finding it overdone.
    @Test("word amounts, fractions and ranges read as a duration (range → lower bound)", arguments: [
        ("Simmer for an hour", 60),
        ("Leave to stand for about an hour", 60),
        ("Rest the dough for half an hour", 30),
        ("Cook for a minute, stirring", 1),
        ("Bake for 1½ hours", 90),
        ("Bake for 1 ½ hours", 90),
        ("Prove for ½ hour", 30),
        ("Braise for 2 to 3 hours", 120),
        ("Simmer 10-15 minutes", 10),
        ("Simmer 10–15 minutes", 10),
        ("Simmer 10 - 15 mins", 10),
        ("Roast for 1-1½ hours", 60),
        ("Bake 20 or 25 minutes", 20),
        ("Simmer 1½ hours 15 minutes", 105),
    ])
    func wordsFractionsAndRanges(text: String, minutes: Int) {
        #expect(CookingPlan.timerMinutes(in: text) == minutes)
    }

    @Test("words and numbers that aren't an amount of time stay nil", arguments: [
        "Leave for a few minutes",
        "Bring 2 to the boil",
        "Cut into 2-3 cm pieces",
        "Serve with a handful of herbs",
        "Add half the sugar",
    ])
    func notADuration(text: String) {
        #expect(CookingPlan.timerMinutes(in: text) == nil)
    }

    @Test("compound durations joined by 'and' still combine")
    func compoundWithAnd() {
        #expect(CookingPlan.timerMinutes(in: "Roast 1 hr and 15 mins") == 75)
    }

    // MARK: - Ingredient checklist line (same amount text as the recipe screen)

    @Test("an ingredient with an amount reads quantity, unit, then name")
    func ingredientLineWithAmount() {
        let flour = Ingredient(baseQuantity: 200, unit: "g", name: "flour")
        let line = CookingIngredientChecklist.line(for: flour, scaleFactor: 1, system: .metric)
        #expect(line == "200 g \(flour.displayName)")
    }

    @Test("an ingredient with no amount is just its name")
    func ingredientLineWithoutAmount() {
        let salt = Ingredient(baseQuantity: 0, unit: "", name: "salt")
        #expect(CookingIngredientChecklist.line(for: salt, scaleFactor: 1, system: .metric) == salt.displayName)
    }

    @Test("the line follows the recipe's scale factor")
    func ingredientLineScales() {
        let eggs = Ingredient(baseQuantity: 2, unit: "", name: "eggs")
        #expect(CookingIngredientChecklist.line(for: eggs, scaleFactor: 2, system: .metric).hasPrefix("4 "))
    }
}
