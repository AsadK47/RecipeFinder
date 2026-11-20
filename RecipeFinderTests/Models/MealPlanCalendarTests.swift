import Testing
import Foundation
@testable import RecipeFinder

@Suite("MealPlanCalendar")
struct MealPlanCalendarTests {

    // MARK: - Fixtures

    /// Deterministic Sunday-first Gregorian calendar in UTC so the grid matches
    /// the "Sun...Sat" header regardless of the host locale.
    private var sut: MealPlanCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = 1
        return MealPlanCalendar(calendar: calendar)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    // MARK: - daysInWeek

    @Test("A week is seven consecutive days starting on Sunday")
    func weekIsSevenConsecutiveDaysFromSunday() {
        // Aug 1 2025 is a Friday; its Sunday-first week starts Jul 27.
        let days = sut.daysInWeek(containing: date(2025, 8, 1))

        #expect(days.count == 7)
        #expect(days.first == date(2025, 7, 27))
        #expect(days.last == date(2025, 8, 2))
        for (offset, day) in days.enumerated() {
            #expect(day == date(2025, 7, 27 + offset))
        }
    }

    // MARK: - weekRange

    @Test("Week range spans Sunday to the following Saturday")
    func weekRangeSpansSundayToSaturday() throws {
        let range = try #require(sut.weekRange(containing: date(2025, 8, 1)))
        #expect(range.start == date(2025, 7, 27))
        #expect(range.end == date(2025, 8, 2))
    }

    // MARK: - monthGrid

    @Test(
        "Month grid pads to full weeks with leading and trailing nils",
        arguments: [
            // (year, month, leadingNils, daysInMonth, totalCount)
            (2025, 8, 5, 31, 42),   // Aug 1 2025 is a Friday
            (2025, 2, 6, 28, 35)    // Feb 1 2025 is a Saturday
        ]
    )
    func monthGridPadsToFullWeeks(
        year: Int, month: Int, leadingNils: Int, daysInMonth: Int, totalCount: Int
    ) {
        let grid = sut.monthGrid(containing: date(year, month, 1))

        #expect(grid.count == totalCount)
        #expect(grid.count % 7 == 0)

        // Leading pad.
        #expect(grid.prefix(leadingNils).allSatisfy { $0 == nil })

        // Every day of the month, in order, with no interior gaps.
        let realDays = grid.compactMap { $0 }
        #expect(realDays.count == daysInMonth)
        for day in 1...daysInMonth {
            #expect(realDays[day - 1] == date(year, month, day))
        }

        // Trailing pad.
        let trailing = totalCount - leadingNils - daysInMonth
        #expect(grid.suffix(trailing).allSatisfy { $0 == nil })
    }
}

/// Plan bug hunt 2026-11-20: Plan left open past midnight kept "today" on yesterday, so Add meal planned the day gone.
@Suite("MealPlanCalendar midnight rollover")
struct MealPlanRolloverTests {
    private let sut: MealPlanCalendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        return MealPlanCalendar(calendar: cal)
    }()

    private func at(_ day: Int, _ hour: Int) -> Date {
        sut.calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour)) ?? Date()
    }

    @Test func todayLeftOpenMovesToTheNewDay() {
        #expect(sut.rolledOver(selected: at(20, 9), lastToday: at(20, 22), now: at(21, 7)) == at(21, 7))
    }

    @Test func aDayTheCookPickedStays() {
        #expect(sut.rolledOver(selected: at(24, 0), lastToday: at(20, 22), now: at(21, 7)) == nil)
    }

    @Test func sameDayChangesNothing() {
        #expect(sut.rolledOver(selected: at(20, 9), lastToday: at(20, 8), now: at(20, 23)) == nil)
    }
}
