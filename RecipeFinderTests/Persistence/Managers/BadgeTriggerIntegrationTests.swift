import Testing
import Foundation
@testable import RecipeFinder

/// Integration: manager action → badge earned. Each test injects an isolated BadgeManager (fresh UserDefaults, no singletons), performs the triggering action, and asserts the right badge was queued.
@MainActor
@Suite("Badge trigger integration")
struct BadgeTriggerIntegrationTests {

    // MARK: - Helpers

    private func makeBadgeManager() -> BadgeManager {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        return BadgeManager(storage: LocalStore(userDefaults: defaults))
    }

    private func makeShoppingManager(badgeManager: BadgeManager) -> ShoppingListManager {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        return ShoppingListManager(
            storage: LocalStore(userDefaults: defaults),
            badgeManager: badgeManager
        )
    }

    private func makeMealManager(badgeManager: BadgeManager) -> MealPlanningManager {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        return MealPlanningManager(
            storage: LocalStore(userDefaults: defaults), mealPlanStore: InMemoryMealPlanStore(),
            badgeManager: badgeManager
        )
    }

    private func makePlan(mealTime: MealTime = .dinner) -> MealPlanModel {
        MealPlanModel(
            id: UUID(),
            recipeId: UUID(),
            recipeName: "Pasta",
            date: Date(),
            mealTime: mealTime
        )
    }

    // MARK: - ShoppingListManager → shoppingExpert

    @Test func addItem_awardsSshoppingExpertBadge() {
        let badge = makeBadgeManager()
        let shopping = makeShoppingManager(badgeManager: badge)
        shopping.addItem(name: "Milk")
        #expect(badge.isBadgeUnlocked(BadgeType.shoppingExpert.rawValue))
        #expect(badge.pendingCelebration == .shoppingExpert)
    }

    @Test func addItem_secondCall_doesNotReCelebrate() {
        let badge = makeBadgeManager()
        let shopping = makeShoppingManager(badgeManager: badge)
        shopping.addItem(name: "Milk")
        badge.dismissCelebration()

        shopping.addItem(name: "Eggs")
        // Badge already unlocked; no new celebration queued.
        #expect(badge.pendingCelebration == nil)
    }

    @Test func addItem_updateExistingItem_doesNotAwardBadge() {
        let badge = makeBadgeManager()
        let shopping = makeShoppingManager(badgeManager: badge)

        shopping.addItem(name: "Milk")
        badge.dismissCelebration()

        // Adding the same item again only updates quantity; the badge path is
        // reached only when a *new* item is appended.
        shopping.addItem(name: "Milk")
        #expect(badge.pendingCelebration == nil)
    }

    // MARK: - MealPlanningManager → mealPlanner

    @Test func addMealPlan_awardsMealPlannerBadge() {
        let badge = makeBadgeManager()
        let meals = makeMealManager(badgeManager: badge)
        meals.addMealPlan(makePlan())
        #expect(badge.isBadgeUnlocked(BadgeType.mealPlanner.rawValue))
        #expect(badge.pendingCelebration == .mealPlanner)
    }

    @Test func addMealPlan_secondPlan_doesNotReCelebrate() {
        let badge = makeBadgeManager()
        let meals = makeMealManager(badgeManager: badge)
        meals.addMealPlan(makePlan(mealTime: .breakfast))
        badge.dismissCelebration()

        meals.addMealPlan(makePlan(mealTime: .dinner))
        #expect(badge.pendingCelebration == nil)
    }

    // MARK: - Isolation: managers use their own BadgeManager instance

    @Test func shoppingAndMealManagersAreIsolatedFromEachOther() {
        let badge1 = makeBadgeManager()
        let badge2 = makeBadgeManager()
        let shopping = makeShoppingManager(badgeManager: badge1)
        let meals = makeMealManager(badgeManager: badge2)

        shopping.addItem(name: "Butter")
        meals.addMealPlan(makePlan())

        #expect(badge1.pendingCelebration == .shoppingExpert)
        #expect(badge1.isBadgeUnlocked(BadgeType.shoppingExpert.rawValue))
        #expect(!badge1.isBadgeUnlocked(BadgeType.mealPlanner.rawValue))

        #expect(badge2.pendingCelebration == .mealPlanner)
        #expect(badge2.isBadgeUnlocked(BadgeType.mealPlanner.rawValue))
        #expect(!badge2.isBadgeUnlocked(BadgeType.shoppingExpert.rawValue))
    }
}
