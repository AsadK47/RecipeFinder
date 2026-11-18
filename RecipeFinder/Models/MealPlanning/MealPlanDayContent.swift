import Foundation

/// What Plan shows under the week strip for the selected day. Pure — split from `MealPlanningView` (Smell Batch D).
enum MealPlanDayContent: Equatable {
    /// The day's planned meal cards.
    case plannedMeals
    /// Today, a future day or yesterday with nothing planned: "Nothing planned for <day>" + Add meal.
    case emptyDay
    /// An older day with nothing planned: the general "Plan a meal" empty state.
    case emptyPast

    /// `hasPlans` is whether the store holds plans for `date`; `hasSelectedMeals` whether the screen shows any yet.
    static func make(hasSelectedMeals: Bool, hasPlans: Bool, date: Date, now: Date,
                     calendar: Calendar = .current) -> MealPlanDayContent {
        if hasSelectedMeals { return .plannedMeals }
        // Kept as it was: "yesterday" is anything within the last 24 hours, not the calendar day.
        if calendar.isDate(date, inSameDayAs: now) || hasPlans || date > now.addingTimeInterval(-86400) {
            return .emptyDay
        }
        return .emptyPast
    }
}
