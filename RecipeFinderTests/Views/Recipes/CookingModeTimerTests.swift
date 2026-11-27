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
        ("Roast for 1-1½ hours", 60),
        ("Bake 20 or 25 minutes", 20),
        ("Simmer 1½ hours 15 minutes", 105),
        ("Rest for a half hour", 30),
        ("In a second bowl, whisk the eggs, then bake for 20 minutes", 20),
        ("Add a second layer of pasta and bake 30 minutes", 30),
        ("Simmer on low for about 2 1/2 hours", 150),
        ("Braise for 3 1/2-4 hours", 210),
        ("Rest for 1/2 hour", 30),
        ("Roast for 1¾ hours", 105),
        ("Simmer 20—25 minutes", 20),
        ("Bake at gas mark 4 - 25 minutes", 25),
        ("Step 3 – 20 minutes", 20),
    ])
    func wordsFractionsAndRanges(text: String, minutes: Int) {
        #expect(CookingPlan.timerMinutes(in: text) == minutes)
    }

    // Reviewer 2026-11-26: "and a half" was dropped or read alone ("1 and a half hours" → 30) — undercooking risk.
    // Half a minute rounds to the nearest whole minute, as every other timer does.
    @Test("'and a half' adds half of the amount's unit", arguments: [
        ("Simmer for 1 and a half hours", 90),
        ("Braise for 2 and a half hours", 150),
        ("Roast for an hour and a half", 90),
        ("Bake for 1 hour and a half, then rest", 90),
        ("Cook for a minute and a half, stirring", 2),
        ("Simmer 10 and a half minutes", 11),
        ("Braise for two and a half hours", 150),
        ("Simmer for one and a half hours", 90),
        ("Simmer 20 minutes and a half cup of stock", 20),
    ])
    func andAHalf(text: String, minutes: Int) {
        #expect(CookingPlan.timerMinutes(in: text) == minutes)
    }

    // Reviewer 2026-11-26: US recipes write 1½ as "1-1/2"; it was read as the range 1–½ → a 60-min timer for 90.
    // A dash before a proper fraction joins a mixed number; a dash before a whole number is still a range.
    @Test("a dash before a fraction is a mixed number, not a range", arguments: [
        ("Bake for 1-1/2 hours", 90),
        ("Simmer 2-1/2 hours, stirring now and then", 150),
        ("Roast 1–1/4 hours", 75),
        ("Braise for 1-1/2 to 2 hours", 90),
        ("Simmer 10-15 minutes", 10),
        ("Braise for 3 1/2-4 hours", 210),
    ])
    func dashedMixedNumber(text: String, minutes: Int) {
        #expect(CookingPlan.timerMinutes(in: text) == minutes)
    }

    @Test("words and numbers that aren't an amount of time stay nil", arguments: [
        "Leave for a few minutes",
        "Bring 2 to the boil",
        "Cut into 2-3 cm pieces",
        "Serve with a handful of herbs",
        "Add half the sugar",
        "Simmer for fifteen and a half hours",
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
