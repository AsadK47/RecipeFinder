import Foundation

extension TodayFeed {
    /// The meal Today's hero is for. From late evening (9pm, or half an hour after a later "Dinner at") — or from 4pm
    /// once tonight's planned dinner, or anything since 4pm, is cooked — it's tomorrow's breakfast, unless tonight's planned dinner is still
    /// open, which keeps the card until it's cooked or the day ends (the cook chose it; a late dinner is still dinner).
    /// "Cooked" is `MealPlanModel.wasCooked` — ticked, or its recipe was cooked that day without Made it.
    struct NextMeal: Equatable {
        let slot: MealSlot
        /// The meal falls on tomorrow's date (late evening). In the small hours the date has already moved on, so
        /// breakfast there is today's.
        let isTomorrow: Bool

        static let lateEveningHour = 21
        static let tonight = NextMeal(slot: .dinner, isTomorrow: false)

        static func at(
            _ date: Date, todaysPlans: [MealPlanModel], recipes: [RecipeModel] = [],
            eatAt: Int = TonightTiming.defaultEatAt, calendar: Calendar
        ) -> NextMeal {
            let minute = TonightTiming.minuteOfDay(date, calendar: calendar)
            // A plan whose recipe is gone has nothing to cook, so it can't hold the evening open.
            let dinners = todaysPlans.filter {
                $0.mealTime == .dinner && ($0.isCompleted || $0.recipe(in: recipes) != nil)
            }
            let dinnerOpen = dinners.contains { !$0.wasCooked(in: recipes, calendar: calendar) }
            // A main or soup cooked since 4pm without a plan (Cook this on a suggestion) is tonight's dinner too; a
            // dessert or tomorrow's oats isn't.
            let cookedThisEvening = recipes.contains { recipe in
                guard MealSlot.dinner.categories.contains(recipe.category.lowercased()),
                      let cookedAt = recipe.lastCookedAt, calendar.isDate(cookedAt, inSameDayAs: date) else { return false }
                return TonightTiming.minuteOfDay(cookedAt, calendar: calendar) >= dinnerStartsAt
            }
            // Tonight's dinner already cooked: nothing left today, so look ahead.
            let dinnerDone = !dinnerOpen && (!dinners.isEmpty || cookedThisEvening)
            let tomorrow = NextMeal(slot: .breakfast, isTomorrow: true)
            if minute >= lateEvening(eatAt: eatAt) { return dinnerOpen ? .tonight : tomorrow }
            if minute >= dinnerStartsAt { return dinnerDone ? tomorrow : .tonight }
            return NextMeal(slot: MealSlot(at: date, calendar: calendar), isTomorrow: false)
        }

        private static let dinnerStartsAt = 16 * 60

        /// Minutes since midnight when the evening is over: 9pm, or half an hour after a later dinner time.
        static func lateEvening(eatAt: Int) -> Int { max(lateEveningHour * 60, eatAt + 30) }

        /// Changes exactly when the next meal can change by the clock (meal boundaries, late evening, midnight) —
        /// Today compares it each minute and rebuilds only when it moves, so an open app never goes stale.
        static func clockPhase(at date: Date, eatAt: Int, calendar: Calendar) -> String {
            let minute = TonightTiming.minuteOfDay(date, calendar: calendar)
            let late = minute >= lateEvening(eatAt: eatAt)
            return "\(TodayFeed.dayKey(date, calendar: calendar))|\(MealSlot(at: date, calendar: calendar).rawValue)|\(late)"
        }

        var mealTime: MealTime { slot.mealTime }

        /// Whether the dinner-clock parts of the card ("Start by…", "Dinner at") apply to a suggestion.
        var isTonight: Bool { self == .tonight }

        /// "For tonight", "For lunch", "For tomorrow's breakfast".
        var forLabel: String {
            if isTomorrow { return "For tomorrow's \(mealTime.rawValue.lowercased())" }
            return slot == .dinner ? "For tonight" : "For \(mealTime.rawValue.lowercased())"
        }

        /// "Tonight", "Lunch", "Tomorrow's breakfast".
        var title: String { Self.title(mealTime, isTomorrow: isTomorrow) }

        static func title(_ meal: MealTime, isTomorrow: Bool) -> String {
            if isTomorrow { return meal == .dinner ? "Tomorrow night" : "Tomorrow's \(meal.rawValue.lowercased())" }
            return meal == .dinner ? "Tonight" : meal.rawValue
        }
    }
}

/// Today's one-line day strip — "Breakfast ✓ · Lunch: Soup · Dinner: plan it" — for the day the next meal is on.
/// Pure so the rules are testable; TodaySnapshot builds it on each data change.
struct TodayDayStrip: Equatable {
    enum State: Equatable {
        /// Cooked (the plan is ticked).
        case done(String)
        case planned(String)
        /// Nothing planned yet and still ahead — tapping plans it.
        case open
        /// Earlier today with nothing planned: nothing to do about it now.
        case passed
    }

    struct Meal: Equatable, Identifiable {
        let time: MealTime
        let state: State
        /// The planned recipe, for opening it.
        let recipeID: UUID?
        /// The meal the hero is for.
        let isNext: Bool
        var id: MealTime { time }

        var text: String {
            switch state {
            case .done: "\(time.rawValue) ✓"
            case .planned(let name): "\(time.rawValue): \(name)"
            case .open: "\(time.rawValue): plan it"
            case .passed: "\(time.rawValue) —"
            }
        }

        /// What VoiceOver says (✓ and — read as symbol names).
        var spokenText: String {
            switch state {
            case .done(let name): "\(time.rawValue), cooked: \(name)"
            case .planned(let name): "\(time.rawValue): \(name)"
            case .open: "\(time.rawValue), nothing planned yet"
            case .passed: "\(time.rawValue), nothing planned"
            }
        }
    }

    /// Start of the day shown.
    let date: Date
    let isTomorrow: Bool
    let meals: [Meal]

    static let mealTimes: [MealTime] = [.breakfast, .lunch, .dinner]

    /// - Parameter plans: the plans on the day the next meal falls on. A plan whose recipe is gone (deleted, not
    ///   re-imported under its name) doesn't count — tapping it would open nothing.
    static func make(
        plans: [MealPlanModel], recipes: [RecipeModel], nextMeal: TodayFeed.NextMeal, day: Date, calendar: Calendar
    ) -> TodayDayStrip {
        let next = nextMeal.mealTime.sortOrder
        let meals = mealTimes.map { time -> Meal in
            let atTime = plans.filter { $0.mealTime == time }.compactMap { plan in
                plan.recipe(in: recipes).map { (plan: plan, recipe: $0) }
            }
            // An open plan is what's still to cook; a cooked one only shows when nothing else is planned.
            if let open = atTime.first(where: { !$0.plan.wasCooked(in: recipes, calendar: calendar) }) {
                return Meal(time: time, state: .planned(open.recipe.name), recipeID: open.recipe.id,
                            isNext: time == nextMeal.mealTime)
            }
            if let done = atTime.first {
                return Meal(time: time, state: .done(done.recipe.name), recipeID: done.recipe.id,
                            isNext: time == nextMeal.mealTime)
            }
            let isPast = !nextMeal.isTomorrow && time.sortOrder < next
            return Meal(time: time, state: isPast ? .passed : .open, recipeID: nil, isNext: time == nextMeal.mealTime)
        }
        return TodayDayStrip(date: calendar.startOfDay(for: day), isTomorrow: nextMeal.isTomorrow, meals: meals)
    }

    /// "Breakfast ✓. Lunch: Soup. Dinner: plan it" — the strip as one line (tests; the card labels each meal).
    var summary: String {
        let line = meals.map(\.text).joined(separator: ". ")
        return isTomorrow ? "Tomorrow. \(line)" : line
    }
}
