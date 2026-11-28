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
        ("Braise for 1-3/2 hours", 60),
        ("Simmer 10-15 minutes", 10),
        ("Braise for 3 1/2-4 hours", 210),
    ])
    func dashedMixedNumber(text: String, minutes: Int) {
        #expect(CookingPlan.timerMinutes(in: text) == minutes)
    }

    // Challenger 2026-11-27: web/JSON-LD text writes fractions with U+2044 "⁄" and dashes as U+2011 "‑" / U+2212 "−";
    // they fell through to the wrong amount (1-1⁄2 → 120 min, 1‑1/2 → 30, 1-½ → 60).
    @Test("fraction slashes, non-breaking hyphens and a dash before ½ read as the plain amount", arguments: [
        ("Bake 1-1\u{2044}2 hours", 90),
        ("Bake 1 1\u{2044}2 hours", 90),
        ("Roast 1\u{2011}1/2 hours", 90),
        ("Roast 1\u{2212}1/2 hours", 90),
        ("Bake 1-\u{BD} hours", 90),
        ("Bake 2\u{2013}\u{BC} hours", 135),
        ("Simmer 10\u{2011}15 minutes", 10),
        ("Simmer 10\u{2212}15 minutes", 10),
        ("Simmer 10\u{2012}15 minutes", 10),
        ("Roast 1\u{2010}1/2 hours", 90),
        ("Bake 1\u{2011}\u{BD} hours", 90),
        ("Bake 1\u{2014}\u{BD} hours", 90),                     // em dash, as ingredient amounts read it
        ("Bake 11\u{2044}2 hours", 90),
        ("Bake 13\u{2044}4 hours", 105),
        ("Rest 3\u{2044}4 hour", 45),
    ])
    func unicodeFractionsAndDashes(text: String, minutes: Int) {
        #expect(CookingPlan.timerMinutes(in: text) == minutes)
    }

    // Reviewer 2026-11-27: number words stopped at twelve, so "forty-five minutes" matched "five" → a 5-min timer.
    @Test("teens, tens and hyphenated or spaced compounds read as the whole number", arguments: [
        ("Roast for forty-five minutes", 45),
        ("Simmer twenty-one minutes", 21),
        ("Bake for forty five minutes", 45),
        ("Rest for fifteen minutes", 15),
        ("Braise for ninety minutes", 90),
        ("Simmer for thirty to forty minutes", 30),
        ("Cook twenty-five or thirty minutes", 25),
        ("Bake for thirty-five and a half minutes", 36),
        ("Prove for sixty minutes", 60),
        ("Rest for Twenty-Five Minutes", 25),
        ("Simmer for fifteen and a half hours", 930),
        ("Roast forty\u{2013}five minutes", 45),
        ("Roast forty\u{2014}five minutes", 45),
        ("Roast for 1 hour forty-five minutes", 105),
        ("Simmer for thirty to forty-five minutes", 30),
        ("Roast for fourty-five minutes", 45),
        ("Rest thirteen minutes", 13), ("Rest fourteen minutes", 14), ("Rest sixteen minutes", 16),
        ("Rest seventeen minutes", 17), ("Rest eighteen minutes", 18), ("Rest nineteen minutes", 19),
        ("Roast fifty minutes", 50), ("Roast seventy minutes", 70), ("Roast eighty minutes", 80),
        ("Shape into twenty\nOne hour later bake", 60),
    ])
    func tensNumberWords(text: String, minutes: Int) {
        #expect(CookingPlan.timerMinutes(in: text) == minutes)
    }

    @Test("words and numbers that aren't an amount of time stay nil", arguments: [
        "Leave for a few minutes",
        "Bring 2 to the boil",
        "Cut into 2-3 cm pieces",
        "Serve with a handful of herbs",
        "Add half the sugar",
        "Simmer for umpteen and a half hours",
        "Roast for a hundred and twenty minutes",
        "Roast for one hundred twenty minutes",
        "Leave for a forty-five-minute rest",
    ])
    func notADuration(text: String) {
        #expect(CookingPlan.timerMinutes(in: text) == nil)
    }

    // Reviewer 2026-11-28: a short seconds-only beat before the real timer hid it ("twenty seconds" → nil,
    // "30 seconds" → 1). An under-a-minute first duration gives way to the next separate one; alone, it stays.
    @Test("a seconds-only first duration gives way to a later real one", arguments: [
        ("Whisk for twenty seconds, then simmer for 10 minutes", 10),
        ("Stir for 30 seconds, then simmer 10 minutes", 10),
        ("Fry for 45 seconds, then rest 2 minutes, then bake 30 minutes", 2),
        ("Blitz 20 seconds, then 15 seconds more, then simmer 5 minutes", 5),
        ("Whisk 20 seconds, then 40 seconds, then simmer 10 minutes", 10),
        ("Warm the milk for 30 seconds until hot. Sprinkle over the yeast and leave 5 minutes until foamy.", 5),
        ("Knock back for 10 seconds, divide into 8. Cover and rise for 1 hour until doubled.", 60),
        ("Toast for 1 minute 30 seconds, then rest 5 minutes", 2),
        ("Microwave for 1 minute, then 30 seconds more", 1),
        ("Stir for 30 seconds", 1),
    ])
    func secondsFirst(text: String, minutes: Int) {
        #expect(CookingPlan.timerMinutes(in: text) == minutes)
    }

    @Test("a seconds first duration keeps its timer before a range end or a limit", arguments: [
        ("Toast the spices 30 seconds to 2 minutes, until fragrant", 1),
        ("Cook 45 seconds or 3 minutes", 1),
        ("Whisk 30 seconds until frothy; serve within 10 minutes", 1),
        ("Whisk 30 seconds, then serve within 10 minutes", 1),
        ("Rest for 30 seconds before serving in 2 minutes", 1),
        ("Fry for 45 seconds, rest 2 minutes", 1),
        ("Sear for 45 seconds to 2 minutes per side", 1),
        ("Blanch 30 seconds to 1½ minutes", 1),
        ("Blend for 30 seconds until smooth. The dressing keeps in the fridge for up to 48 hours.", 1),
        ("Sear for 30 seconds. Ready in 20 minutes in total.", 1),
    ])
    func secondsFirstKept(text: String, minutes: Int) {
        #expect(CookingPlan.timerMinutes(in: text) == minutes)
    }

    @Test("seconds-only durations with no longer next step stay as before", arguments: [
        "Blitz for 20 seconds",
        "Blitz for 20 seconds, then 20 seconds more",
        "Blitz 20 seconds; the dressing keeps up to 2 hours",
    ])
    func secondsOnly(text: String) {
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
