import Foundation

/// Pure weekly-cooking-streak math over recorded cook dates.
///
/// We reward the act of *cooking*, not opening the app (browsing is the retention anti-pattern for
/// recipe apps). A week "counts" if it contains at least one cook. The streak is the run of
/// consecutive counted weeks ending at the current week — with a one-week grace: not having cooked
/// *yet* this week doesn't break last week's run, it just means this week is still pending.
struct CookingStreak: Equatable {
    /// Consecutive weeks (ending at this week, or last week via grace) that each contain a cook.
    let currentWeeks: Int
    /// Cooks recorded in the current calendar week.
    let cooksThisWeek: Int
    /// Whether the user has cooked at least once this week.
    var cookedThisWeek: Bool { cooksThisWeek > 0 }

    static let empty = CookingStreak(currentWeeks: 0, cooksThisWeek: 0)

    static func compute(cookDates: [Date], now: Date = Date(), calendar: Calendar = .current) -> CookingStreak {
        guard !cookDates.isEmpty else { return .empty }

        func weekStart(_ date: Date) -> Date {
            calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
        }

        let cookedWeeks = Set(cookDates.map(weekStart))
        let thisWeek = weekStart(now)
        let cooksThisWeek = cookDates.filter { weekStart($0) == thisWeek }.count

        // Anchor the count at this week if cooked, else last week (grace), else there's no live streak.
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: thisWeek) ?? thisWeek
        var cursor: Date
        if cookedWeeks.contains(thisWeek) {
            cursor = thisWeek
        } else if cookedWeeks.contains(lastWeek) {
            cursor = lastWeek
        } else {
            return CookingStreak(currentWeeks: 0, cooksThisWeek: cooksThisWeek)
        }

        var weeks = 0
        while cookedWeeks.contains(cursor) {
            weeks += 1
            guard let previous = calendar.date(byAdding: .weekOfYear, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return CookingStreak(currentWeeks: weeks, cooksThisWeek: cooksThisWeek)
    }
}
