import Foundation
import Testing
@testable import RecipeFinder

/// Me's hero: the stats strip (dinners cooked · week streak · cuisines tried), and its wording.
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

    @Test("the strip reads dinners, then streak, then cuisines")
    func order() {
        let stats = MeStats.strip(dinners: 1, streakWeeks: 1, cuisines: 1)
        #expect(stats.map(\.kind) == [.dinners, .streak, .cuisines])
    }

    @Test("dinners cooked counts every cook, including repeats of one dish")
    func dinnersCountsRepeats() {
        let stats = MeStats.strip(recipes: [recipe("Dal", cookCount: 3), recipe("Soup", cookCount: 2),
                                            recipe("Pie")], streakWeeks: 0)
        #expect(value(stats, .dinners) == 5)
    }

    @Test("a starter recipe the cook has made counts as a dinner")
    func starterRecipeCooked() {
        let stats = MeStats.strip(recipes: [recipe("Soup", cookCount: 1, sample: true)], streakWeeks: 0)
        #expect(value(stats, .dinners) == 1)
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
        #expect(value(stats, .dinners) == metrics.recipesCooked)
        #expect(value(stats, .streak) == metrics.weeklyStreak)
        #expect(value(stats, .cuisines) == metrics.cuisinesCooked)
    }

    @Test("labels follow the number", arguments: [
        (1, "dinner", "cuisine"),
        (0, "dinners", "cuisines"),
        (12, "dinners", "cuisines"),
    ])
    func labels(count: Int, dinners: String, cuisines: String) {
        let stats = MeStats.strip(dinners: count, streakWeeks: count, cuisines: count)
        #expect(stats.map(\.label) == [dinners, "week streak", cuisines])
    }

    @Test("VoiceOver hears each stat as one phrase", arguments: [
        (1, "1 dinner cooked, 1 week streak, 1 cuisine tried"),
        (3, "3 dinners cooked, 3 week streak, 3 cuisines tried"),
    ])
    func spoken(count: Int, expected: String) {
        #expect(MeStats.spokenSummary(MeStats.strip(dinners: count, streakWeeks: count, cuisines: count)) == expected)
    }

    @Test("negative counts from bad data show as zero")
    func negativesClampToZero() {
        let stats = MeStats.strip(dinners: -2, streakWeeks: -1, cuisines: -3)
        #expect(stats.map(\.value) == [0, 0, 0])
    }

    @Test("a new cook has not cooked yet; one dinner is enough to show the strip")
    func hasCooked() {
        #expect(!MeStats.hasCooked(MeStats.strip(recipes: [recipe("Dal")], streakWeeks: 0)))
        #expect(MeStats.hasCooked(MeStats.strip(recipes: [recipe("Dal", cookCount: 1)], streakWeeks: 0)))
    }
}
