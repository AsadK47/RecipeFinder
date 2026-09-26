import Foundation

/// Pure calendar/date math for the planner, extracted from `MealPlanningView` for testability; `Calendar` injected for determinism.
struct MealPlanCalendar {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    /// The seven dates of the week containing `date`, from the calendar's first weekday.
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

    /// The month as a 7-column grid: leading/trailing `nil`s pad partial weeks, one entry per day; count is a multiple of 7.
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
