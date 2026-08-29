import Foundation

/// Pure calendar/date math for the meal planner's calendar and weekly views.
///
/// Extracted from `MealPlanningView` so the month-grid and week computations are
/// unit testable and no longer live inline inside a SwiftUI `body`. The
/// `Calendar` is injected so tests are deterministic regardless of the device's
/// locale and time zone.
struct MealPlanCalendar {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// The seven dates of the week containing `date`, starting on the calendar's
    /// first weekday.
    func daysInWeek(containing date: Date) -> [Date] {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }

        var days: [Date] = []
        var current = week.start
        for _ in 0..<7 {
            days.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else {
                break
            }
            current = next
        }
        return days
    }

    /// The month containing `date` laid out as a 7-column grid: leading `nil`s
    /// pad the first week up to the 1st, one entry per day of the month, then
    /// trailing `nil`s pad the final week. The count is always a multiple of 7.
    func monthGrid(containing date: Date) -> [Date?] {
        guard let month = calendar.dateInterval(of: .month, for: date),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: month.start) else {
            return []
        }

        var days: [Date?] = []
        var current = firstWeek.start
        while current < month.end {
            if calendar.isDate(current, equalTo: date, toGranularity: .month) {
                days.append(current)
            } else {
                // Leading pad before the 1st; interior days are always in-month.
                days.append(nil)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else {
                break
            }
            current = next
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    /// Start and inclusive end dates of the week containing `date`.
    func weekRange(containing date: Date) -> (start: Date, end: Date)? {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date) else {
            return nil
        }
        guard let end = calendar.date(byAdding: .day, value: -1, to: week.end) else {
            return (week.start, week.start)
        }
        return (week.start, end)
    }
}
