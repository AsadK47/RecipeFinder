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
    /// userInfo key carrying the Monday after the nudge: Plan opens the week holding it — the week the nudge checked.
    static let weekStartKey = "weekStart"
    static let body = "Next week is wide open — swipe through a few dinners on Plan and it's sorted in a minute."

    /// The nudge's userInfo for one firing at `fire`: the Monday after it (seconds since 1970, plist-safe).
    static func userInfo(firingAt fire: Date, calendar: Calendar = .current) -> [String: Double] {
        let monday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: fire)) ?? fire
        return [weekStartKey: monday.timeIntervalSince1970]
    }

    /// The week a tapped nudge asks Plan to show; nil for any other notification.
    static func weekStart(from userInfo: [AnyHashable: Any]?) -> Date? {
        (userInfo?[weekStartKey] as? Double).map { Date(timeIntervalSince1970: $0) }
    }

    /// The first Sunday 18:00 after `now` whose week ahead (the Monday after, to the end of Plan's week) has no
    /// dinner planned; nil when every week in the look-ahead already has one. A repeating dinner counts for a week when one of
    /// its weekly copies (from its date on) falls on a day checked. Breakfast, lunch and
    /// snacks don't count.
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
            // From the Monday after to the end of Plan's week holding it (the week a tap opens): Monday–Sunday where
            // weeks start on Monday, Monday–Saturday where they start on Sunday. Days up to tonight never count, so
            // tonight's or a past dinner can't stand in for the week ahead.
            guard let monday = calendar.date(byAdding: .day, value: 1, to: sunday),
                  let lastDay = MealPlanCalendar(calendar: calendar).daysInWeek(containing: monday).last,
                  let weekEnd = calendar.date(byAdding: .day, value: 1, to: lastDay) else { return nil }
            // A weekly dinner counts only when one of its copies lands on a day checked (same rule as Plan's nights).
            var day = monday
            var planned = false
            while day < weekEnd, !planned {
                planned = MealPlanModel.hasDinner(on: day, plans: dinners, calendar: calendar)
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { return nil }
                day = next
            }
            if !planned { return fire }
        }
        return nil
    }
}
