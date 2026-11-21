import Foundation

/// Everything Today shows, built once per data change from the stores' current state. Pure so the wiring between the
/// parts (tomorrow's plans, the week's plans, Tonight's picks left out of "Plan tomorrow") is testable without the view.
struct TodaySnapshot: Equatable {
    let feed: TodayFeed
    let week: TodayWeek
    let progress: TodayProgress

    /// - Parameter plansOn: the meal plans on a given day (the planner's own lookup, so recurring copies count).
    static func make(
        recipes: [RecipeModel],
        plansOn: (Date) -> [MealPlanModel],
        kitchenItemNames: [String],
        inventoryItems: [KitchenInventoryModel],
        streak: CookingStreak,
        unlockedBadgeIDs: Set<String>,
        now: Date,
        calendar: Calendar = .current
    ) -> TodaySnapshot {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let feed = TodayFeed.make(
            recipes: recipes,
            todaysPlans: plansOn(now),
            kitchenItemNames: kitchenItemNames,
            tomorrowsPlans: tomorrow == now ? [] : plansOn(tomorrow),
            inventoryItems: inventoryItems,
            now: now,
            calendar: calendar
        )
        let weekPlans = (0..<TodayWeek.dayCount).flatMap { offset in
            calendar.date(byAdding: .day, value: offset, to: now).map(plansOn) ?? []
        }
        return TodaySnapshot(
            feed: feed,
            week: TodayWeek.make(
                recipes: recipes, plans: weekPlans,
                tonightIDs: Set(feed.tonightOptions.map(\.recipe.id)), now: now, calendar: calendar
            ),
            progress: TodayProgress.make(recipes: recipes, streak: streak, unlockedBadgeIDs: unlockedBadgeIDs)
        )
    }
}
