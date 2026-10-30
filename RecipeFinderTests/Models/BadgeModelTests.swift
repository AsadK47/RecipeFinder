import Testing
import SwiftUI
@testable import RecipeFinder

@Suite("BadgeModel")
struct BadgeModelTests {

    // MARK: - BadgeType.requiredCount

    @Test(arguments: [
        (BadgeType.firstRecipe,        1),
        (BadgeType.fiveRecipes,        5),
        (BadgeType.tenRecipes,         10),
        (BadgeType.twentyFiveRecipes,  25),
        (BadgeType.fiftyRecipes,       50),
        (BadgeType.hundredRecipes,     100),
    ])
    func requiredCount_countBased(type: BadgeType, expected: Int) {
        #expect(type.requiredCount == expected)
    }

    @Test(arguments: [
        BadgeType.welcomeAboard,
        BadgeType.mealPlanner,
        BadgeType.shoppingExpert,
        BadgeType.firstImport,
        BadgeType.firstPhotoImport,
        BadgeType.headChef,
    ])
    func requiredCount_triggerBasedBadgesAreZero(type: BadgeType) {
        #expect(type.requiredCount == 0)
    }

    @Test func requiredCount_thresholdsAreStrictlyIncreasing() {
        let countBased: [BadgeType] = [
            .firstRecipe, .fiveRecipes, .tenRecipes,
            .twentyFiveRecipes, .fiftyRecipes, .hundredRecipes,
        ]
        let counts = countBased.map(\.requiredCount)
        for i in 1..<counts.count {
            #expect(counts[i] > counts[i - 1])
        }
    }

    // MARK: - BadgeType.badge invariants (all cases)

    @Test(arguments: BadgeType.allCases)
    func badge_idMatchesRawValue(type: BadgeType) {
        #expect(type.badge.id == type.rawValue)
    }

    @Test(arguments: BadgeType.allCases)
    func badge_defaultIsLockedAndUnearned(type: BadgeType) {
        let badge = type.badge
        #expect(!badge.isUnlocked)
        #expect(badge.dateEarned == nil)
    }

    @Test(arguments: BadgeType.allCases)
    func badge_allFieldsNonEmpty(type: BadgeType) {
        let badge = type.badge
        #expect(!badge.title.isEmpty)
        #expect(!badge.icon.isEmpty)
        #expect(!badge.color.isEmpty)
        #expect(!badge.howToEarn.isEmpty)
    }

    // MARK: - New trigger-based badge types

    @Test func firstImport_hasExpectedProperties() {
        let badge = BadgeType.firstImport.badge
        #expect(badge.id == "first_import")
        #expect(badge.icon == "link.circle.fill")
        #expect(badge.color == "blue")
    }

    @Test func firstPhotoImport_hasExpectedProperties() {
        let badge = BadgeType.firstPhotoImport.badge
        #expect(badge.id == "first_photo_import")
        #expect(badge.icon == "camera.circle.fill")
        #expect(badge.color == "purple")
    }

    @Test func headChef_hasExpectedProperties() {
        let badge = BadgeType.headChef.badge
        #expect(badge.id == "head_chef")
        #expect(badge.icon == "frying.pan.fill")
        #expect(badge.color == "orange")
    }

    // MARK: - Badge.color(for:)

    @Test(arguments: [
        ("purple", Color.purple),
        ("green",  Color.green),
        ("mint",   Color.mint),
        ("blue",   Color.blue),
        ("orange", Color.orange),
        ("yellow", Color.yellow),
        ("gold",   Color.yellow),
        ("teal",   Color.teal),
        ("indigo", Color.indigo),
    ])
    func colorFor_namedColors(name: String, expected: Color) {
        #expect(Badge.color(for: name) == expected)
    }

    @Test(arguments: ["", "crimson", "PURPLE"])
    func colorFor_unknownFallsBackToGray(name: String) {
        #expect(Badge.color(for: name) == .gray)
    }

    // MARK: - BadgeMetrics aggregation

    private func recipe(category: String = "Main", cuisine: String? = nil,
                        cookCount: Int = 0, rating: Int = 0, photos: [String] = []) -> RecipeModel {
        RecipeModel(
            name: "R", category: category, difficulty: "Basic",
            prepTime: "5 minutes", cookingTime: "5 minutes", baseServings: 1,
            ingredients: [], prePrepInstructions: [], instructions: ["Do"],
            notes: "", cookCount: cookCount, rating: rating, cuisine: cuisine, photoNames: photos
        )
    }

    @Test func metrics_aggregateLibrary() {
        let recipes = [
            recipe(category: "Main", cuisine: "Italian", cookCount: 3, rating: 5, photos: ["a.jpg"]),
            recipe(category: "Main", cuisine: "Thai", cookCount: 2, rating: 4),
            recipe(category: "Dessert", cuisine: "Italian", cookCount: 1),  // Italian again → not a new cuisine
            recipe(category: "Snack", cuisine: nil, cookCount: 0)           // uncooked → excluded from cuisines
        ]
        let m = BadgeMetrics.from(recipes: recipes, streakWeeks: 7)
        #expect(m.recipesCollected == 4)
        #expect(m.recipesCooked == 6)        // 3 + 2 + 1 + 0
        #expect(m.weeklyStreak == 7)
        #expect(m.sameRecipeCooked == 3)     // the most-cooked single recipe
        #expect(m.recipesRated == 2)
        #expect(m.cookPhotos == 1)
        #expect(m.cuisinesCooked == 2)       // Italian + Thai (uncooked snack excluded)
    }

    /// Starter recipes aren't collected by the user — counting them awarded First Bite / Getting Hungry on a first cook.
    @Test func metrics_recipesCollectedExcludesStarterRecipes() {
        var starter = recipe(cookCount: 1)
        starter.isSampleRecipe = true
        let m = BadgeMetrics.from(recipes: [starter, starter, recipe()], streakWeeks: 0)
        #expect(m.recipesCollected == 1)
        #expect(m.recipesCooked == 2)   // cooking a starter still counts as cooking
    }

    @Test func metrics_cuisineFallsBackToCategoryWhenCuisineMissing() {
        let recipes = [recipe(category: "Korean", cuisine: nil, cookCount: 1)]
        #expect(BadgeMetrics.from(recipes: recipes, streakWeeks: 0).cuisinesCooked == 1)
    }

    // MARK: - progress(for:)

    @Test func progress_countsTowardThreshold() {
        var m = BadgeMetrics(); m.recipesCooked = 7
        let p = BadgeType.cookedTen.progress(for: m)
        #expect(p?.current == 7)
        #expect(p?.target == 10)
    }

    @Test func progress_capsAtTarget() {
        var m = BadgeMetrics(); m.recipesCooked = 50
        #expect(BadgeType.cookedTen.progress(for: m)?.current == 10)
    }

    @Test func progress_nilForEventBadge() {
        #expect(BadgeType.firstImport.progress(for: BadgeMetrics()) == nil)
    }

    // MARK: - New cook-centric criteria

    @Test(arguments: [BadgeType.cookedTen, .streakTwoWeeks, .cuisinesFive, .sameRecipeFive, .ratedTen, .firstCookPhoto])
    func cookingBadges_haveZeroRequiredCount(type: BadgeType) {
        #expect(type.requiredCount == 0)  // not collection badges → excluded from the recipe-count path
    }
}
