import Foundation

/// Everything Today shows, built once per data change from the stores' current state. Pure so the wiring between the
/// parts (tomorrow's plans, the week's plans, Tonight's picks left out of "Plan tomorrow") is testable without the view.
struct TodaySnapshot: Equatable {
    let feed: TodayFeed
    /// The next meal's day, one line.
    let day: TodayDayStrip
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
        eatAt: Int = TonightTiming.defaultEatAt,
        now: Date,
        calendar: Calendar = .current
    ) -> TodaySnapshot {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let todaysPlans = plansOn(now)
        let tomorrowsPlans = tomorrow == now ? [] : plansOn(tomorrow)
        let feed = TodayFeed.make(
            recipes: recipes,
            todaysPlans: todaysPlans,
            kitchenItemNames: kitchenItemNames,
            tomorrowsPlans: tomorrowsPlans,
            inventoryItems: inventoryItems,
            eatAt: eatAt,
            now: now,
            calendar: calendar
        )
        let weekPlans = (0..<TodayWeek.dayCount).flatMap { offset in
            calendar.date(byAdding: .day, value: offset, to: now).map(plansOn) ?? []
        }
        let isTomorrow = feed.nextMeal.isTomorrow
        return TodaySnapshot(
            feed: feed,
            day: TodayDayStrip.make(
                plans: isTomorrow ? tomorrowsPlans : todaysPlans, recipes: recipes, nextMeal: feed.nextMeal,
                day: isTomorrow ? tomorrow : now, calendar: calendar
            ),
            week: TodayWeek.make(
                recipes: recipes, plans: weekPlans,
                tonightIDs: Set(feed.tonightOptions.map(\.recipe.id)), now: now, calendar: calendar
            ),
            progress: TodayProgress.make(recipes: recipes, streak: streak, unlockedBadgeIDs: unlockedBadgeIDs)
        )
    }
}
