import Foundation
import Testing
@testable import RecipeFinder

/// Trophy shelf on Me: badges grouped Cooking / Streaks / Importing / Planning, newest earned first, the swipe order
/// of the badge pager, locked-badge progress text and the "earn it here" route.
@Suite struct BadgeShelfTests {

    private func earned(_ type: BadgeType, daysAgo: Int) -> Badge {
        let base = type.badge
        return Badge(
            id: base.id, title: base.title, description: base.description, icon: base.icon, color: base.color,
            dateEarned: Date(timeIntervalSince1970: 1_800_000_000 - Double(daysAgo) * 86_400),
            isUnlocked: true, howToEarn: base.howToEarn
        )
    }

    /// Every badge as the manager hands them out: earned ones replaced by their stored copy.
    private func all(_ earnedBadges: [Badge]) -> [Badge] {
        let byID = Dictionary(uniqueKeysWithValues: earnedBadges.map { ($0.id, $0) })
        return BadgeType.allCases.map { byID[$0.rawValue] ?? $0.badge }
    }

    // MARK: Grouping

    @Test func groupsAreInShelfOrder() {
        let sections = BadgeShelf.sections(all([]))
        #expect(sections.map(\.group) == [.cooking, .streaks, .importing, .planning])
        #expect(sections.map(\.group.title) == ["Cooking", "Streaks", "Importing", "Planning"])
    }

    @Test func everyBadgeSitsOnTheShelfExactlyOnce() {
        let ids = BadgeShelf.sections(all([])).flatMap(\.badges).map(\.id)
        #expect(ids.count == BadgeType.allCases.count)
        #expect(Set(ids) == Set(BadgeType.allCases.map(\.rawValue)))
    }

    @Test(arguments: [
        (BadgeType.headChef, BadgeGroup.cooking),
        (.cookedHundred, .cooking),
        (.cuisinesFive, .cooking),
        (.sameRecipeFive, .cooking),
        (.ratedTen, .cooking),
        (.firstCookPhoto, .cooking),
        (.streakTwoWeeks, .streaks),
        (.streakFiftyTwoWeeks, .streaks),
        (.welcomeAboard, .importing),
        (.firstRecipe, .importing),
        (.hundredRecipes, .importing),
        (.firstImport, .importing),
        (.firstPhotoImport, .importing),
        (.mealPlanner, .planning),
        (.shoppingExpert, .planning),
    ])
    func badgeLandsInItsGroup(type: BadgeType, group: BadgeGroup) {
        #expect(type.group == group)
    }

    @Test func countsReadEarnedOverTotal() {
        let sections = BadgeShelf.sections(all([earned(.headChef, daysAgo: 3), earned(.cookedTen, daysAgo: 1)]))
        let cooking = sections.first { $0.group == .cooking }
        #expect(cooking?.earnedCount == 2)
        #expect(cooking?.total == 9)
        #expect(cooking?.countText == "2 / 9")
        #expect(BadgeShelf.countText(sections) == "2 / \(BadgeType.allCases.count)")
    }

    @Test func newestEarnedComesFirstThenLockedInEarningOrder() {
        let sections = BadgeShelf.sections(all([
            earned(.headChef, daysAgo: 10),
            earned(.cuisinesFive, daysAgo: 1),
            earned(.cookedTen, daysAgo: 5),
        ]))
        let ids = sections.first { $0.group == .cooking }?.badges.map(\.id) ?? []
        #expect(Array(ids.prefix(3)) == [BadgeType.cuisinesFive, .cookedTen, .headChef].map(\.rawValue))
        // Locked ones follow in the order you'd earn them (the list order), not by date.
        #expect(Array(ids.dropFirst(3)) == [
            BadgeType.cookedTwentyFive, .cookedFifty, .cookedHundred, .sameRecipeFive, .ratedTen, .firstCookPhoto,
        ].map(\.rawValue))
    }

    @Test func anEarnedBadgeWithoutADateSitsAfterDatedOnesButBeforeLocked() {
        let undated = Badge(id: BadgeType.headChef.rawValue, title: "Head Chef", description: "", icon: "x",
                            color: "orange", dateEarned: nil, isUnlocked: true)
        let ids = BadgeShelf.sections(all([undated, earned(.cookedTen, daysAgo: 2)]))
            .first { $0.group == .cooking }?.badges.map(\.id) ?? []
        #expect(Array(ids.prefix(3)) == [BadgeType.cookedTen, .headChef, .cookedTwentyFive].map(\.rawValue))
    }

    @Test func unknownStoredBadgesAreLeftOff() {
        let stray = Badge(id: "retired_badge", title: "Old", description: "", icon: "x", color: "blue",
                          dateEarned: Date(), isUnlocked: true)
        let ids = BadgeShelf.sections(all([]) + [stray]).flatMap(\.badges).map(\.id)
        #expect(!ids.contains("retired_badge"))
    }

    // MARK: Pager

    @Test func pagerSwipesThroughTheShelfInShelfOrder() {
        let sections = BadgeShelf.sections(all([earned(.mealPlanner, daysAgo: 1)]))
        let pager = BadgeShelf.pagerOrder(sections)
        #expect(pager.map(\.id) == sections.flatMap(\.badges).map(\.id))
        #expect(pager.first?.id == BadgeType.headChef.rawValue)
        #expect(pager.last?.id == BadgeType.shoppingExpert.rawValue)
    }

    @Test func pagerOpensOnTheTappedBadge() {
        let pager = BadgeShelf.pagerOrder(BadgeShelf.sections(all([])))
        let index = BadgeShelf.startIndex(of: BadgeType.streakFourWeeks.rawValue, in: pager)
        #expect(pager[index].id == BadgeType.streakFourWeeks.rawValue)
        #expect(BadgeShelf.startIndex(of: "missing", in: pager) == 0)
    }

    // MARK: Locked progress

    @Test(arguments: [
        (BadgeType.cookedTen, "7 / 10 cooks"),
        (.streakFourWeeks, "3 / 4 weeks"),
        (.tenRecipes, "6 / 10 recipes"),
        (.cuisinesFive, "2 / 5 cuisines"),
        (.sameRecipeFive, "4 / 5 cooks of one dish"),
        (.ratedTen, "1 / 10 rated"),
    ])
    func progressReadsCurrentOverTargetWithAUnit(type: BadgeType, text: String) {
        let metrics = BadgeMetrics(recipesCollected: 6, recipesCooked: 7, weeklyStreak: 3, cuisinesCooked: 2,
                                   sameRecipeCooked: 4, recipesRated: 1, cookPhotos: 0)
        #expect(type.progressText(for: metrics) == text)
    }

    @Test func firstStepBadgesCountFromZero() {
        #expect(BadgeType.firstCookPhoto.progressText(for: BadgeMetrics()) == "0 / 1 photos")
        #expect(BadgeType.headChef.progressText(for: BadgeMetrics()) == "0 / 1 cooks")
    }

    @Test func progressNeverOverflowsTheTarget() {
        let metrics = BadgeMetrics(recipesCooked: 40)
        #expect(BadgeType.cookedTen.progressText(for: metrics) == "10 / 10 cooks")
        #expect(BadgeType.cookedTen.progressFraction(for: metrics) == 1)
    }

    @Test func progressFractionIsShareDone() {
        #expect(BadgeType.cookedTen.progressFraction(for: BadgeMetrics(recipesCooked: 7)) == 0.7)
        #expect(BadgeType.mealPlanner.progressFraction(for: BadgeMetrics()) == nil)
    }

    @Test(arguments: [BadgeType.mealPlanner, .shoppingExpert, .firstImport, .firstPhotoImport, .welcomeAboard])
    func oneOffBadgesHaveNoCount(type: BadgeType) {
        #expect(type.progressText(for: BadgeMetrics(recipesCollected: 3)) == nil)
    }

    // MARK: Earn here

    @Test(arguments: [
        (BadgeType.headChef, BadgeEarnAction.cook),
        (.cookedFifty, .cook),
        (.cuisinesFive, .cook),
        (.sameRecipeFive, .cook),
        (.streakTwelveWeeks, .cook),
        (.ratedTen, .rate),
        (.firstCookPhoto, .rate),
        (.firstRecipe, .addRecipe),
        (.hundredRecipes, .addRecipe),
        (.firstImport, .addRecipe),
        (.firstPhotoImport, .addRecipe),
        (.mealPlanner, .plan),
        (.shoppingExpert, .groceries),
    ])
    func lockedBadgeOffersARouteToEarnIt(type: BadgeType, action: BadgeEarnAction) {
        #expect(type.earnAction == action)
    }

    @Test func welcomeHasNoRouteBecauseYouEarnItByJoining() {
        #expect(BadgeType.welcomeAboard.earnAction == nil)
    }

    @Test(arguments: [
        (BadgeEarnAction.cook, AppTab.today, "Pick something to cook"),
        (.rate, .recipes, "Open your recipes"),
        (.addRecipe, .recipes, "Add a recipe"),
        (.plan, .plan, "Plan a meal"),
        (.groceries, .groceries, "Open groceries"),
    ])
    func earnActionOpensItsTab(action: BadgeEarnAction, tab: AppTab, title: String) {
        #expect(action.tab == tab)
        #expect(action.title == title)
        #expect(AppTab.destination(for: action.notification) == tab)
    }
}
