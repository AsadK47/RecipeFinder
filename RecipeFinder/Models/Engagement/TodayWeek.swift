import Foundation

/// Today's "This week": the next seven days with what's planned on each, plus a one-tap pick for tomorrow's dinner
/// when tomorrow has none. Pure so the rules are testable; TodayView builds it on each data change.
struct TodayWeek: Equatable {
    struct Day: Equatable, Identifiable {
        /// Start of the day.
        let date: Date
        let isToday: Bool
        /// Meals planned that day (cooked ones too, so a day you planned stays marked), one per meal time, in meal order.
        let mealTimes: [MealTime]
        /// The planned dinner's name, when there is one.
        let dinnerName: String?

        var id: Date { date }
        var isPlanned: Bool { !mealTimes.isEmpty }
    }

    let days: [Day]
    /// A dinner to plan for tomorrow in one tap; nil when tomorrow's dinner is planned or nothing fits.
    let planTomorrow: RecipeModel?

    /// The day "Plan tomorrow" plans for.
    var tomorrow: Date? { days.dropFirst().first?.date }

    static let dayCount = 7
    /// Recipes cooked this recently aren't suggested again for tomorrow.
    static let recentCookDays = 7

    /// - Parameter tonightIDs: recipes Tonight's card can show (hero + Shuffle picks) — left out so the same dish
    ///   isn't offered for today and tomorrow.
    static func make(
        recipes: [RecipeModel],
        plans: [MealPlanModel],
        tonightIDs: Set<UUID>,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> TodayWeek {
        let today = calendar.startOfDay(for: now)
        let days = (0..<dayCount).compactMap { offset -> Day? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            let onDay = plans.filter { $0.isOn(date, calendar: calendar) }
            let mealTimes = Set(onDay.map(\.mealTime)).sorted { $0.sortOrder < $1.sortOrder }
            return Day(
                date: date,
                isToday: offset == 0,
                mealTimes: mealTimes,
                dinnerName: onDay.first { $0.mealTime == .dinner }?.recipeName
            )
        }

        let tomorrowHasDinner = days.dropFirst().first?.mealTimes.contains(.dinner) ?? true
        let pick = tomorrowHasDinner ? nil : tomorrowPick(
            recipes: recipes,
            taken: tonightIDs.union(plansInWeek(plans, days: days, calendar: calendar).map(\.recipeId)),
            cookedSince: calendar.date(byAdding: .day, value: -recentCookDays, to: today) ?? today
        )
        return TodayWeek(days: days, planTomorrow: pick)
    }

    private static func plansInWeek(_ plans: [MealPlanModel], days: [Day], calendar: Calendar) -> [MealPlanModel] {
        plans.filter { plan in days.contains { plan.isOn($0.date, calendar: calendar) } }
    }

    /// Favourites, then your own over samples, then most cooked, then name — skipping anything already on this week's
    /// plan or Tonight's card, and anything cooked in the past `recentCookDays`.
    private static func tomorrowPick(recipes: [RecipeModel], taken: Set<UUID>, cookedSince: Date) -> RecipeModel? {
        recipes
            .filter { recipe in
                guard !taken.contains(recipe.id) else { return false }
                guard let last = recipe.lastCookedAt else { return true }
                return last < cookedSince
            }
            .min { a, b in
                if a.isFavorite != b.isFavorite { return a.isFavorite }
                if a.isSampleRecipe != b.isSampleRecipe { return !a.isSampleRecipe }
                if a.cookCount != b.cookCount { return a.cookCount > b.cookCount }
                return a.name < b.name
            }
    }
}
