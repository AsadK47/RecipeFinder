import Foundation
import Testing
@testable import RecipeFinder

/// Me's hero: the stats strip (meals cooked · week streak · cuisines tried), and its wording.
@Suite("MeStats")
struct MeStatsTests {

    private func recipe(_ name: String, cookCount: Int = 0, cuisine: String? = nil,
                        category: String = "Main", sample: Bool = false) -> RecipeModel {
        RecipeModel(
            name: name, category: category, difficulty: "Easy", prepTime: "10 min", cookingTime: "20 min",
            baseServings: 2, ingredients: [], prePrepInstructions: [], instructions: ["Cook"], notes: "",
            isSampleRecipe: sample, cookCount: cookCount, cuisine: cuisine
        )
    }

    private func value(_ stats: [MeStat], _ kind: MeStat.Kind) -> Int? {
        stats.first { $0.kind == kind }?.value
    }

    @Test("the strip reads meals, then streak, then cuisines")
    func order() {
        let stats = MeStats.strip(meals: 1, streakWeeks: 1, cuisines: 1)
        #expect(stats.map(\.kind) == [.meals, .streak, .cuisines])
    }

    @Test("meals cooked counts every cook, including repeats of one dish")
    func mealsCountRepeats() {
        let stats = MeStats.strip(recipes: [recipe("Dal", cookCount: 3), recipe("Soup", cookCount: 2),
                                            recipe("Pie")], streakWeeks: 0)
        #expect(value(stats, .meals) == 5)
    }

    @Test("a starter recipe the cook has made counts as a meal")
    func starterRecipeCooked() {
        let stats = MeStats.strip(recipes: [recipe("Soup", cookCount: 1, sample: true)], streakWeeks: 0)
        #expect(value(stats, .meals) == 1)
    }

    @Test("cuisines tried counts distinct cuisines of cooked dishes, ignoring case and uncooked ones")
    func cuisinesDistinct() {
        let stats = MeStats.strip(recipes: [
            recipe("Dal", cookCount: 1, cuisine: "Indian"),
            recipe("Korma", cookCount: 2, cuisine: " indian "),
            recipe("Ragu", cookCount: 1, cuisine: "Italian"),
            recipe("Pho", cuisine: "Vietnamese"),
        ], streakWeeks: 0)
        #expect(value(stats, .cuisines) == 2)
    }

    @Test("the strip matches the badge counts for the same library")
    func matchesBadgeMetrics() {
        let recipes = [recipe("Dal", cookCount: 4, cuisine: "Indian"), recipe("Cake", cookCount: 1, category: "Baking")]
        let metrics = BadgeMetrics.from(recipes: recipes, streakWeeks: 6)
        let stats = MeStats.strip(recipes: recipes, streakWeeks: 6)
        #expect(value(stats, .meals) == metrics.recipesCooked)
        #expect(value(stats, .streak) == metrics.weeklyStreak)
        #expect(value(stats, .cuisines) == metrics.cuisinesCooked)
    }

    @Test("labels follow the number", arguments: [
        (1, "meal", "cuisine"),
        (0, "meals", "cuisines"),
        (12, "meals", "cuisines"),
    ])
    func labels(count: Int, meals: String, cuisines: String) {
        let stats = MeStats.strip(meals: count, streakWeeks: count, cuisines: count)
        #expect(stats.map(\.label) == [meals, "week streak", cuisines])
    }

    @Test("VoiceOver hears each stat as one phrase", arguments: [
        (1, "1 meal cooked, 1 week streak, 1 cuisine tried"),
        (3, "3 meals cooked, 3 week streak, 3 cuisines tried"),
    ])
    func spoken(count: Int, expected: String) {
        #expect(MeStats.spokenSummary(MeStats.strip(meals: count, streakWeeks: count, cuisines: count)) == expected)
    }

    @Test("negative counts from bad data show as zero")
    func negativesClampToZero() {
        let stats = MeStats.strip(meals: -2, streakWeeks: -1, cuisines: -3)
        #expect(stats.map(\.value) == [0, 0, 0])
    }

    @Test("a new cook has not cooked yet; one meal is enough to show the strip")
    func hasCooked() {
        #expect(!MeStats.hasCooked(MeStats.strip(recipes: [recipe("Dal")], streakWeeks: 0)))
        #expect(MeStats.hasCooked(MeStats.strip(recipes: [recipe("Dal", cookCount: 1)], streakWeeks: 0)))
    }

    @Test("a live streak shows the strip even when no recipe still carries a cook (cooked recipe deleted)")
    func streakAloneShowsStrip() {
        #expect(MeStats.hasCooked(MeStats.strip(meals: 0, streakWeeks: 3, cuisines: 0)))
    }
}
