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
                recipe: plan.flatMap { recipe(for: $0, in: recipes) },
                isToday: calendar.isDate(date, inSameDayAs: today),
                isPast: calendar.startOfDay(for: date) < startOfToday
            )
        }
    }

    /// The nights a dinner can move to, in week order: every other night from tonight on (a missed dinner can move
    /// forward; nothing moves into the past).
    static func moveTargets(from night: Night, in nights: [Night]) -> [Night] {
        nights.filter { $0.date != night.date && !$0.isPast }
    }

    /// The plans that change when `dinner` moves to `night`: the dinner itself (same time of day, new date) and,
    /// if that night already has a dinner, that one moved back to `dinner`'s night. Empty when nothing changes.
    static func move(
        _ dinner: MealPlanModel, to night: Date, plans: [MealPlanModel], calendar: Calendar = .current
    ) -> [MealPlanModel] {
        guard !dinner.isOn(night, calendar: calendar),
              let moved = shifted(dinner, to: night, calendar: calendar) else { return [] }
        let occupant = plans.first { $0.id != dinner.id && $0.isSlot(night, .dinner, calendar: calendar) }
        guard let occupant, let swapped = shifted(occupant, to: dinner.date, calendar: calendar) else {
            return [moved]
        }
        return [moved, swapped]
    }

    // MARK: - Private

    /// Matched by id, then by name so a re-imported recipe keeps its night (same rule as Add Week to Groceries).
    private static func recipe(for plan: MealPlanModel, in recipes: [RecipeModel]) -> RecipeModel? {
        recipes.first { $0.id == plan.recipeId }
            ?? recipes.first { $0.name.caseInsensitiveCompare(plan.recipeName) == .orderedSame }
    }

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
