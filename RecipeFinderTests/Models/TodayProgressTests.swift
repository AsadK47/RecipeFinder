import Testing
import Foundation
@testable import RecipeFinder

/// Today's progress row (streak, cooks this week, next badge).
@Suite struct TodayProgressTests {

    private let cal: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_GB")
        cal.firstWeekday = 2
        cal.timeZone = TimeZone(identifier: "Europe/London") ?? .current
        return cal
    }()

    private func date(_ day: Int, month: Int = 11, hour: Int = 12) -> Date {
        cal.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour)) ?? Date()
    }

    private func recipe(_ name: String, sample: Bool = false, cookCount: Int = 0, lastCooked: Date? = nil) -> RecipeModel {
        RecipeModel(
            name: name, category: "Main", difficulty: "Basic", prepTime: "5 min", cookingTime: "10 min",
            baseServings: 2, ingredients: [Ingredient(baseQuantity: 1, unit: "", name: "egg")],
            prePrepInstructions: [], instructions: ["Cook"], notes: "",
            isSampleRecipe: sample, cookCount: cookCount, lastCookedAt: lastCooked
        )
    }

    private func progress(
        _ recipes: [RecipeModel], streak: CookingStreak = .empty, unlocked: Set<BadgeType> = []
    ) -> TodayProgress {
        TodayProgress.make(recipes: recipes, streak: streak, unlockedBadgeIDs: Set(unlocked.map(\.rawValue)))
    }

    // MARK: Progress row

    @Test func streakAndCooksThisWeekComeFromTheStreak() {
        let result = progress([], streak: CookingStreak(currentWeeks: 3, cooksThisWeek: 2))
        #expect(result.streakWeeks == 3)
        #expect(result.cooksThisWeek == 2)
    }

    @Test func nobodyHasCookedYetSoTheFirstCookBadgeIsNext() {
        let result = progress([recipe("Soup", sample: true)])
        #expect(result.nextBadge?.type == .headChef)
        #expect(result.nextBadge?.current == 0)
        #expect(result.nextBadge?.target == 1)
        #expect(result.nextBadge?.text == "1 more cook to Head Chef")
    }

    @Test func earnedBadgesAreSkipped() {
        let cooked = recipe("Soup", cookCount: 3, lastCooked: date(10))
        let result = progress([cooked], streak: CookingStreak(currentWeeks: 1, cooksThisWeek: 1), unlocked: [.headChef])
        #expect(result.nextBadge?.type != .headChef)
    }

    @Test func theClosestBadgeWinsNotTheFirstInTheList() {
        // 4 of 5 cooks of one recipe (80%) beats 4 of 10 total cooks (40%) and 1 of 2 streak weeks (50%).
        let soup = recipe("Soup", cookCount: 4, lastCooked: date(10))
        let result = progress([soup], streak: CookingStreak(currentWeeks: 1, cooksThisWeek: 1), unlocked: [.headChef])
        #expect(result.nextBadge?.type == .sameRecipeFive)
        #expect(result.nextBadge?.text == "1 more cook of one dish to Signature Dish")
    }

    @Test func aTieGoesToTheBadgeWithFewerLeft() {
        // Streak 1/2 (50%) vs cooks 5/10 (50%): the streak needs 1 more, cooks need 5.
        let recipes = (0..<5).map { recipe("R\($0)", cookCount: 1, lastCooked: date(10)) }
        let result = progress(recipes, streak: CookingStreak(currentWeeks: 1, cooksThisWeek: 1), unlocked: [.headChef])
        #expect(result.nextBadge?.type == .streakTwoWeeks)
        #expect(result.nextBadge?.text == "1 more week to On a Roll")
    }

    @Test func libraryBadgesAreNotTodaysNextBadge() {
        // First Bite (1 recipe) ties Head Chef (1 cook) and comes first in the list — but library badges stay on Me.
        let result = progress([], unlocked: [])
        #expect(result.nextBadge?.type == .headChef)
    }

    @Test func aBadgeAlreadyReachedButNotYetShownIsSkipped() {
        // 1 cook reached Head Chef; the unlock just hasn't been recorded yet — don't show "0 more".
        let result = progress([recipe("Soup", cookCount: 1, lastCooked: date(10))])
        #expect(result.nextBadge?.type != .headChef)
        #expect((result.nextBadge?.remaining ?? 0) > 0)
    }

    @Test func everyCookingBadgeEarnedMeansNoNextBadge() {
        let all = Set(BadgeType.allCases)
        #expect(progress([recipe("Soup", cookCount: 2)], unlocked: all).nextBadge == nil)
    }

    // MARK: Link to the trophy shelf (tester feedback: badges from Today)

    @Test func theBadgeRowOpensTheNextBadgesCardOnTheShelf() {
        let result = progress([recipe("Soup", sample: true)])
        #expect(result.badgeShelfRequest == TrophyShelfRequest(badgeID: BadgeType.headChef.rawValue))
    }

    @Test func theBadgeRowFollowsTheClosestBadgeNotTheFirst() {
        let soup = recipe("Soup", cookCount: 4, lastCooked: date(10))
        let result = progress([soup], streak: CookingStreak(currentWeeks: 1, cooksThisWeek: 1), unlocked: [.headChef])
        #expect(result.badgeShelfRequest?.badgeID == BadgeType.sameRecipeFive.rawValue)
    }

    @Test func everyCookingBadgeEarnedMeansNoBadgeRowToFollow() {
        let result = progress([recipe("Soup", cookCount: 2)], unlocked: Set(BadgeType.allCases))
        #expect(result.badgeShelfRequest == nil)
    }

    @Test func theBadgeRowReadsProgressAsWordsForVoiceOver() {
        let soup = recipe("Soup", cookCount: 4, lastCooked: date(10))
        let result = progress([soup], streak: CookingStreak(currentWeeks: 1, cooksThisWeek: 1), unlocked: [.headChef])
        #expect(result.nextBadge?.spokenText == "1 more cook of one dish to Signature Dish, 4 of 5")
    }

    @Test(arguments: [
        (BadgeType.streakFourWeeks, 2, 4, "2 more weeks to Hot Streak"),
        (BadgeType.cuisinesFive, 4, 5, "1 more cuisine to Globetrotter"),
        (BadgeType.ratedTen, 7, 10, "3 more ratings to Critic"),
        (BadgeType.firstCookPhoto, 0, 1, "1 more cook photo to Food Stylist"),
        (BadgeType.cookedTen, 8, 10, "2 more cooks to Home Cook"),
    ])
    func badgeLineSaysWhatToDo(type: BadgeType, current: Int, target: Int, text: String) {
        #expect(TodayProgress.NextBadge(type: type, current: current, target: target).text == text)
    }
}
