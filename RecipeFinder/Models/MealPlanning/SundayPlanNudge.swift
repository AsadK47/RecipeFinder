import Foundation

/// The opt-in Sunday planning nudge: one notification on a Sunday evening when the week after it has no dinners
/// planned yet. Pure, so the "when" is testable with a fixed calendar; `MealPlanningManager` re-runs it whenever plans
/// change, so planning a dinner for that week moves the nudge on to the next empty week (or drops it).
enum SundayPlanNudge {
    /// LocalStore key of the Settings switch (off until the cook turns it on). Namespaced, so Reset turns it off.
    static let settingKey = "sundayPlanNudge"
    static let identifier = "plan-sunday-nudge"
    static let hour = 18
    /// How many Sundays ahead to look: a planned next week shouldn't drop the nudge for the week after.
    static let lookAheadWeeks = 4

    static let title = "Plan next week's dinners?"
    static let body = "Next week is wide open — swipe through a few dinners on Plan and it's sorted in a minute."

    /// The first Sunday 18:00 after `now` whose following Monday–Sunday has no dinner planned; nil when every week
    /// in the look-ahead already has one. A repeating dinner counts for every week from its date on (Plan fills the
    /// repeat into each week), so a cook with one never gets nudged. Breakfast, lunch and snacks don't count.
    static func fireDate(now: Date, plans: [MealPlanModel], calendar: Calendar = .current) -> Date? {
        let dinners = plans.filter { $0.mealTime == .dinner }
        let startOfToday = calendar.startOfDay(for: now)
        let weekday = calendar.component(.weekday, from: startOfToday)
        let daysToSunday = (8 - weekday) % 7 // Gregorian weekday 1 = Sunday, whatever the first day of the week.

        var checked = 0
        var offset = daysToSunday
        while checked < lookAheadWeeks {
            defer { offset += 7 }
            guard let sunday = calendar.date(byAdding: .day, value: offset, to: startOfToday),
                  let fire = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: sunday) else { return nil }
            guard fire > now else { continue }
            checked += 1
            guard let weekStart = calendar.date(byAdding: .day, value: 1, to: sunday),
                  let weekEnd = calendar.date(byAdding: .day, value: 8, to: sunday) else { return nil }
            let planned = dinners.contains { dinner in
                let day = calendar.startOfDay(for: dinner.date)
                return (day >= weekStart && day < weekEnd) || (dinner.isRecurring && day < weekEnd)
            }
            if !planned { return fire }
        }
        return nil
    }
}
