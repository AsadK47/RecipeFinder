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
}
