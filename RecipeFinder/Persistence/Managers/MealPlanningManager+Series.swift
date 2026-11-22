import Foundation

/// Weekly-series rules for `MealPlanningManager`: which copy of a repeating meal leads its series, which past plans
/// Clear Past Plans takes, what a new week is filled with, and each series' reminder time. Static functions of the
/// plans (no store access), so tests call them directly.
extension MealPlanningManager {
    /// Plans on days before today: one-offs, and every copy of a weekly meal except the newest of its series (weekday +
    /// meal time), which `propagateRecurring` copies forward. Dinners cooked on their day stay as the week's history
    /// (`MealPlanModel.wasCooked`); cook counts live on the recipe, so nothing cooked is lost either way.
    nonisolated static func pastPlans(
        _ plans: [MealPlanModel], now: Date, recipes: [RecipeModel] = [], calendar: Calendar = .current
    ) -> Set<UUID> {
        let today = calendar.startOfDay(for: now)
        let newestOfSeries = Set(newestRecurringCopies(plans, calendar: calendar))
        return Set(plans.filter {
            $0.date < today && !newestOfSeries.contains($0.id) && !$0.wasCooked(in: recipes, calendar: calendar)
        }.map(\.id))
    }

    /// The newest copy of each weekly series (weekday + meal time) — the one later weeks are copied from.
    nonisolated static func newestRecurringCopies(_ plans: [MealPlanModel], calendar: Calendar = .current) -> [UUID] {
        var newest: [SeriesKey: MealPlanModel] = [:]
        for plan in plans where plan.isRecurring {
            let key = SeriesKey(plan, calendar: calendar)
            if newest[key].map({ plan.date > $0.date }) ?? true { newest[key] = plan }
        }
        return newest.values.map(\.id)
    }

    /// A planner slot: the day (start of day) and meal time — one dish each.
    struct SlotKey: Hashable {
        let day: Date
        let mealTime: MealTime

        init(day: Date, mealTime: MealTime) {
            self.day = day
            self.mealTime = mealTime
        }

        init(_ plan: MealPlanModel, calendar: Calendar = .current) {
            self.init(day: calendar.startOfDay(for: plan.date), mealTime: plan.mealTime)
        }
    }

    /// A weekly series: same weekday and meal time (how `propagateRecurring` matches templates).
    struct SeriesKey: Hashable {
        let weekday: Int
        let mealTime: MealTime

        init(weekday: Int, mealTime: MealTime) {
            self.weekday = weekday
            self.mealTime = mealTime
        }

        init(_ plan: MealPlanModel, calendar: Calendar) {
            self.init(weekday: calendar.component(.weekday, from: plan.date), mealTime: plan.mealTime)
        }
    }

    /// The copies `propagateRecurring` adds to the week from `startDate`: each empty slot whose weekday and meal time
    /// match a weekly series takes that series' newest copy from before the week (still weekly, same servings, notes
    /// and reminder). Slots already planned are left alone, so running it twice adds nothing.
    nonisolated static func weeklyCopies(
        of plans: [MealPlanModel], forWeekStarting startDate: Date, calendar cal: Calendar = .current
    ) -> [MealPlanModel] {
        let start = cal.startOfDay(for: startDate)
        guard let end = cal.date(byAdding: .day, value: 7, to: start) else { return [] }

        let templates = plans.filter { $0.isRecurring && $0.date < start }
        guard !templates.isEmpty else { return [] }

        // O(1) occupied-slot lookup instead of O(P) contains per slot.
        let occupiedSlots = Set(plans.map { SlotKey($0, calendar: cal) })

        // Template lookup by series keeping the most recent, so the inner loop is O(1).
        var templateBySeries: [SeriesKey: MealPlanModel] = [:]
        for template in templates {
            let key = SeriesKey(template, calendar: cal)
            if templateBySeries[key].map({ template.date > $0.date }) ?? true {
                templateBySeries[key] = template
            }
        }

        var newEntries: [MealPlanModel] = []
        var newOccupied: Set<SlotKey> = []

        for dayOffset in 0..<7 {
            guard let candidate = cal.date(byAdding: .day, value: dayOffset, to: start),
                  candidate < end else { continue }
            let targetWeekday = cal.component(.weekday, from: candidate)

            for mealTime in MealTime.allCases {
                let slot = SlotKey(day: candidate, mealTime: mealTime)
                guard !occupiedSlots.contains(slot) && !newOccupied.contains(slot) else { continue }

                guard let template = templateBySeries[SeriesKey(weekday: targetWeekday, mealTime: mealTime)]
                else { continue }

                newEntries.append(MealPlanModel(
                    recipeId: template.recipeId,
                    recipeName: template.recipeName,
                    date: candidate,
                    mealTime: mealTime,
                    servings: template.servings,
                    notes: template.notes,
                    isRecurring: true,
                    reminderTime: template.reminderTime
                ))
                newOccupied.insert(slot)
            }
        }
        return newEntries
    }

    /// Each weekly series' reminder time, read from its newest copy (the one that rings); nil = the cook has none.
    nonisolated static func seriesReminderTimes(_ plans: [MealPlanModel]) -> [SeriesKey: Date?] {
        let newest = Set(newestRecurringCopies(plans))
        var times: [SeriesKey: Date?] = [:]
        // updateValue, not subscript assignment: assigning nil to a `Date?`-valued subscript would drop the key.
        for plan in plans where newest.contains(plan.id) {
            times.updateValue(plan.reminderTime, forKey: SeriesKey(plan, calendar: .current))
        }
        return times
    }
}
