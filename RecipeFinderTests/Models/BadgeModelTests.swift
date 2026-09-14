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
}
