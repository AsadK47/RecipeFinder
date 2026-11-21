import Foundation

extension TodayFeed {
    /// The meal Today's hero is for. From 9pm — or from 4pm once tonight's planned dinner is cooked — it's tomorrow's
    /// breakfast, unless tonight's planned dinner is still open, which keeps the card until it's cooked or the day
    /// ends (the cook chose it; a late dinner is still dinner).
    struct NextMeal: Equatable {
        let slot: MealSlot
        /// The meal falls on tomorrow's date (late evening). In the small hours the date has already moved on, so
        /// breakfast there is today's.
        let isTomorrow: Bool

        static let lateEveningHour = 21
        static let tonight = NextMeal(slot: .dinner, isTomorrow: false)

        static func at(_ date: Date, todaysPlans: [MealPlanModel], calendar: Calendar) -> NextMeal {
            let slot = MealSlot(at: date, calendar: calendar)
            let hour = calendar.component(.hour, from: date)
            let dinners = todaysPlans.filter { $0.mealTime == .dinner }
            let dinnerOpen = dinners.contains { !$0.isCompleted }
            // Tonight's planned dinner already cooked: nothing left today, so look ahead.
            let dinnerDone = !dinners.isEmpty && !dinnerOpen
            let tomorrow = NextMeal(slot: .breakfast, isTomorrow: true)
            if hour >= lateEveningHour { return dinnerOpen ? .tonight : tomorrow }
            if slot == .dinner, dinnerDone { return tomorrow }
            return NextMeal(slot: slot, isTomorrow: false)
        }

        var mealTime: MealTime { slot.mealTime }

        /// Whether the dinner-clock parts of the card ("Start by…", "Dinner at") apply to a suggestion.
        var isTonight: Bool { self == .tonight }

        /// "For tonight", "For lunch", "For tomorrow's breakfast".
        var forLabel: String {
            if isTomorrow { return "For tomorrow's \(mealTime.rawValue.lowercased())" }
            return slot == .dinner ? "For tonight" : "For \(mealTime.rawValue.lowercased())"
        }

        /// "Tonight", "Lunch", "Tomorrow's breakfast" — what VoiceOver hears before the recipe name.
        var title: String {
            if isTomorrow { return "Tomorrow's \(mealTime.rawValue.lowercased())" }
            return slot == .dinner ? "Tonight" : mealTime.rawValue
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
    }

    /// Start of the day shown.
    let date: Date
    let isTomorrow: Bool
    let meals: [Meal]

    static let mealTimes: [MealTime] = [.breakfast, .lunch, .dinner]

    /// - Parameter plans: the plans on the day the next meal falls on.
    static func make(
        plans: [MealPlanModel], nextMeal: TodayFeed.NextMeal, day: Date, calendar: Calendar
    ) -> TodayDayStrip {
        let next = nextMeal.mealTime.sortOrder
        let meals = mealTimes.map { time -> Meal in
            let atTime = plans.filter { $0.mealTime == time }
            // An open plan is what's still to cook; a ticked one only shows when nothing else is planned.
            if let open = atTime.first(where: { !$0.isCompleted }) {
                return Meal(time: time, state: .planned(open.recipeName), recipeID: open.recipeId,
                            isNext: time == nextMeal.mealTime)
            }
            if let done = atTime.first {
                return Meal(time: time, state: .done(done.recipeName), recipeID: done.recipeId,
                            isNext: time == nextMeal.mealTime)
            }
            let isPast = !nextMeal.isTomorrow && time.sortOrder < next
            return Meal(time: time, state: isPast ? .passed : .open, recipeID: nil, isNext: time == nextMeal.mealTime)
        }
        return TodayDayStrip(date: calendar.startOfDay(for: day), isTomorrow: nextMeal.isTomorrow, meals: meals)
    }

    /// "Breakfast ✓. Lunch: Soup. Dinner: plan it" — the strip read as one line.
    var summary: String {
        let line = meals.map(\.text).joined(separator: ". ")
        return isTomorrow ? "Tomorrow. \(line)" : line
    }
}
