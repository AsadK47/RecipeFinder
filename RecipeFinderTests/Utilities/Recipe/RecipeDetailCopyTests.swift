import Testing
@testable import RecipeFinder

// Characterisation tests: pin the recipe detail's timer and cook-history copy before those views moved out of
// RecipeDetailView+Content (Smell Batch A slice 2). Strings match what the screen showed before the move.
@Suite struct RecipeDetailCopyTests {

    @Test(arguments: [(30, "Start 30-min timer"), (90, "Start 90-min timer"), (1, "Start 1-min timer"),
                      (0, "Start a timer"), (-5, "Start a timer")])
    func timerStartTitle(minutes: Int, expected: String) {
        #expect(RecipeDetailCopy.timerStartTitle(minutes: minutes) == expected)
    }

    @Test(arguments: [(30, "Starts a 30 minute timer"), (0, "Start a cooking timer"), (-1, "Start a cooking timer")])
    func timerStartHint(minutes: Int, expected: String) {
        #expect(RecipeDetailCopy.timerStartHint(minutes: minutes) == expected)
    }

    @Test(arguments: [(0, "Not cooked yet"), (1, "Cooked 1 time"), (2, "Cooked 2 times"), (12, "Cooked 12 times")])
    func cookCountLabel(count: Int, expected: String) {
        #expect(RecipeDetailCopy.cookCount(count) == expected)
    }

    @Test(arguments: [(0, false), (1, true), (5, true)])
    func ratingShowsOnlyOnceCooked(count: Int, expected: Bool) {
        #expect(RecipeDetailCopy.showsRating(cookCount: count) == expected)
    }

    @Test(arguments: [(59, [0, 59]), (60, [1, 0]), (90, [1, 30]), (125, [2, 5])])
    func timerStartSplitsHoursAndMinutes(minutes: Int, expected: [Int]) {
        let start = RecipeDetailCopy.timerStart(minutes: minutes)
        #expect(start.map { [$0.hours, $0.minutes] } == expected)
    }

    @Test(arguments: [0, -3])
    func noCookTimeOpensThePicker(minutes: Int) {
        #expect(RecipeDetailCopy.timerStart(minutes: minutes) == nil)
    }

    // Slice 3: the facts card (prep, cook, difficulty, category, cuisine) moved to RecipeFactsCard.

    @Test(arguments: [("15 minutes", "15 min"), ("1 minute", "1 min"), ("2 hours", "2 hr"), ("1 hour", "1 hr"),
                      ("1 hr 30 min", "1 hr 30 min"), ("Not set", "Not set")])
    func factTimesAreShortened(display: String, expected: String) {
        #expect(RecipeDetailCopy.shortTime(display) == expected)
    }

    private func recipe(prep: String = "15 minutes", cook: String = "90 minutes", cuisine: String?) -> RecipeModel {
        RecipeModel(name: "Stew", category: "Main course", difficulty: "Intermediate", prepTime: prep,
                    cookingTime: cook, baseServings: 4, ingredients: [], prePrepInstructions: [],
                    instructions: [], notes: "", cuisine: cuisine)
    }

    @Test func factsListPrepCookDifficultyCategoryInOrder() {
        let facts = RecipeDetailCopy.facts(for: recipe(cuisine: nil))
        #expect(facts.map { $0.kind } == [.prep, .cook, .difficulty, .category])
        #expect(facts.map { $0.value } == ["15 min", "1 hr 30 min", "Intermediate", "Main course"])
        #expect(facts.map { $0.kind.label } == ["Prep", "Cook", "Difficulty", "Category"])
    }

    @Test func cuisineIsTheFifthFactWhenSet() {
        let facts = RecipeDetailCopy.facts(for: recipe(cuisine: "Italian"))
        #expect(facts.map { $0.kind } == [.prep, .cook, .difficulty, .category, .cuisine])
        #expect(facts.last?.value == "Italian")
    }

    @Test func emptyCuisineAddsNoFact() {
        #expect(RecipeDetailCopy.facts(for: recipe(cuisine: "")).count == 4)
    }

    @Test func missingTimesReadNotSet() {
        let facts = RecipeDetailCopy.facts(for: recipe(prep: "", cook: "", cuisine: nil))
        #expect(facts.prefix(2).map { $0.value } == ["Not set", "Not set"])
    }

    @Test(arguments: [(RecipeFactKind.prep, "clock"), (.cook, "flame"), (.difficulty, "chart.bar"),
                      (.category, "fork.knife"), (.cuisine, "globe")])
    func factIconsUnchanged(kind: RecipeFactKind, icon: String) {
        #expect(kind.icon == icon)
    }
}
