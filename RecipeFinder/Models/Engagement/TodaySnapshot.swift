import Foundation

/// Everything Today shows, built once per data change from the stores' current state. Pure so the wiring between the
/// parts (tomorrow's plans, the week's plans, Tonight's picks left out of "Plan tomorrow", no weekly pick for new
/// users) is testable without the view.
struct TodaySnapshot: Equatable {
    let feed: TodayFeed
    let week: TodayWeek
    let progress: TodayProgress
    /// The weekly never-cooked pick; nil for new users, who already get a Starters shelf of uncooked recipes.
    let tryNew: RecipeModel?

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
            progress: TodayProgress.make(recipes: recipes, streak: streak, unlockedBadgeIDs: unlockedBadgeIDs),
            tryNew: feed.isNewUser ? nil : TrySomethingNew.pick(recipes: recipes, now: now, calendar: calendar)
        )
    }
}

extension TodayFeed {
    /// The shelves under Today's cards.
    struct Shelves: Equatable {
        let cookAgain: [RecipeModel]
        let kitchenMatches: [KitchenMatch]
        let rediscover: [RecipeModel]
    }

    /// Shelves without the recipes already on a card above them, so a shuffled-to dish or the weekly pick isn't
    /// repeated below it.
    func shelves(excluding onCards: [UUID?]) -> Shelves {
        let ids = Set(onCards.compactMap { $0 })
        return Shelves(
            cookAgain: cookAgain.filter { !ids.contains($0.id) },
            kitchenMatches: fitsYourKitchen.filter { !ids.contains($0.recipe.id) },
            rediscover: rediscover.filter { !ids.contains($0.id) }
        )
    }
}
