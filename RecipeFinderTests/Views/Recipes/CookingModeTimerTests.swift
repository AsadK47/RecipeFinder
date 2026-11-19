import Testing
@testable import RecipeFinder

/// The cook-mode step-timer extractor only counts numbers with an explicit time
/// unit, so temperatures and counts don't get read as a duration.
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
        #expect(CookingPlan.timerMinutes(in: "Broil for 4-5 minutes, then serve within 6 minutes") == 5)
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
        #expect(line.hasPrefix("200 "))
        #expect(line.hasSuffix(" \(flour.displayName)"))
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
