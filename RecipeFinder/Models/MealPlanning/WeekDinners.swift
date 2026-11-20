import Foundation

/// Plan's week as seven dinner photos: each night's dinner (and the dish behind it), and "hold = move" — moving a
/// dinner to another night swaps it with the dinner already there, so a night never ends up with two. Pure, so the
/// rules are testable with a fixed calendar.
enum WeekDinners {
    struct Night: Equatable, Identifiable {
        let date: Date
        /// This night's dinner plan, if any (breakfast/lunch/snacks don't count).
        let plan: MealPlanModel?
        /// The dish behind `plan`; nil when there's no plan or the recipe was deleted.
        let recipe: RecipeModel?
        let isToday: Bool
        let isPast: Bool
        var id: Date { date }
    }

    static func nights(
        week: [Date], plans: [MealPlanModel], recipes: [RecipeModel], today: Date, calendar: Calendar = .current
    ) -> [Night] {
        let startOfToday = calendar.startOfDay(for: today)
        return week.map { date in
            let plan = plans.first { $0.isSlot(date, .dinner, calendar: calendar) }
            return Night(
                date: date,
                plan: plan,
                recipe: plan.flatMap { $0.recipe(in: recipes) },
                isToday: calendar.isDate(date, inSameDayAs: today),
                isPast: calendar.startOfDay(for: date) < startOfToday
            )
        }
    }

    /// The nights a dinner can move to, in week order: every other night from tonight on (a missed dinner can move
    /// forward; nothing moves into the past). A missed dinner only moves onto an empty night — a swap would send that
    /// night's dinner into the past. Repeating dinners don't move (yet): the weekly copy would refill the night they
    /// left, planning the dish twice.
    static func moveTargets(from night: Night, in nights: [Night]) -> [Night] {
        guard night.plan?.isRecurring != true else { return [] }
        return nights.filter { target in
            target.date != night.date && !target.isPast
                && target.plan?.isRecurring != true
                && !(night.isPast && target.plan != nil)
        }
    }

    /// The plans that change when `dinner` moves to `night`: the dinner itself (same time of day, new date) and,
    /// if that night already has a dinner, that one moved back to `dinner`'s night. Empty when nothing changes.
    /// Empty when nothing changes or the move isn't allowed (see `moveTargets`).
    static func move(
        _ dinner: MealPlanModel, to night: Date, plans: [MealPlanModel], today: Date, calendar: Calendar = .current
    ) -> [MealPlanModel] {
        let startOfToday = calendar.startOfDay(for: today)
        guard !dinner.isOn(night, calendar: calendar), !dinner.isRecurring,
              calendar.startOfDay(for: night) >= startOfToday,
              let moved = shifted(dinner, to: night, calendar: calendar) else { return [] }
        let occupant = plans.first { $0.id != dinner.id && $0.isSlot(night, .dinner, calendar: calendar) }
        guard let occupant else { return [moved] }
        guard !occupant.isRecurring, calendar.startOfDay(for: dinner.date) >= startOfToday,
              let swapped = shifted(occupant, to: dinner.date, calendar: calendar) else { return [] }
        return [moved, swapped]
    }

    // MARK: - Private

    /// `plan` on `day`'s date at its own clock time — by components, so a clock change can't slip it a day.
    private static func shifted(_ plan: MealPlanModel, to day: Date, calendar: Calendar) -> MealPlanModel? {
        let time = calendar.dateComponents([.hour, .minute, .second], from: plan.date)
        var parts = calendar.dateComponents([.year, .month, .day], from: day)
        parts.hour = time.hour
        parts.minute = time.minute
        parts.second = time.second
        guard let date = calendar.date(from: parts) else { return nil }
        var moved = plan
        moved.date = date
        return moved
    }
}
