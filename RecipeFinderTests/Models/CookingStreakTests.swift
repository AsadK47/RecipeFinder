import Testing
import Foundation
@testable import RecipeFinder

/// Pure weekly-cooking-streak math. Dates are built by subtracting whole weeks from a fixed `now`,
/// so they land in deterministic weeks regardless of locale/week-start.
@Suite struct CookingStreakTests {

    private let cal = Calendar.current
    private let now = Date()

    private func weeksAgo(_ n: Int) -> Date {
        cal.date(byAdding: .weekOfYear, value: -n, to: now)!
    }

    private func compute(_ dates: [Date]) -> CookingStreak {
        CookingStreak.compute(cookDates: dates, now: now, calendar: cal)
    }

    @Test func empty_isZero() {
        let s = compute([])
        #expect(s.currentWeeks == 0)
        #expect(s.cooksThisWeek == 0)
        #expect(s.cookedThisWeek == false)
    }

    @Test func cookedThisWeek_isStreakOne() {
        let s = compute([now])
        #expect(s.currentWeeks == 1)
        #expect(s.cooksThisWeek == 1)
        #expect(s.cookedThisWeek)
    }

    @Test func threeConsecutiveWeeks_isStreakThree() {
        let s = compute([now, weeksAgo(1), weeksAgo(2)])
        #expect(s.currentWeeks == 3)
    }

    @Test func gapBreaksStreak() {
        // This week + two weeks ago, but last week missing → only this week counts.
        let s = compute([now, weeksAgo(2)])
        #expect(s.currentWeeks == 1)
    }

    @Test func graceWeek_notCookedThisWeekButLastWeek_keepsStreak() {
        // No cook this week yet, but last + the week before → streak of 2 via grace, this week pending.
        let s = compute([weeksAgo(1), weeksAgo(2)])
        #expect(s.currentWeeks == 2)
        #expect(s.cooksThisWeek == 0)
        #expect(s.cookedThisWeek == false)
    }

    @Test func lapsed_lastCookTwoWeeksAgo_isZero() {
        let s = compute([weeksAgo(2), weeksAgo(3)])
        #expect(s.currentWeeks == 0)
    }

    @Test func isAtRisk_whenLiveStreakButNoCookThisWeek() {
        // Cooked last week + the week before, nothing yet this week → streak alive but at risk.
        let s = compute([weeksAgo(1), weeksAgo(2)])
        #expect(s.currentWeeks == 2)
        #expect(s.isAtRisk)
    }

    @Test func notAtRisk_whenCookedThisWeek() {
        #expect(compute([now, weeksAgo(1)]).isAtRisk == false)
    }

    @Test func notAtRisk_whenNoStreak() {
        #expect(compute([]).isAtRisk == false)
    }

    // MARK: - Lapse reminder

    @Test func lapseReminder_atRisk_isEndOfWeekAtSixPM_inFuture() throws {
        let day = cal.date(from: DateComponents(year: 2030, month: 6, day: 3, hour: 9))!
        let atRisk = CookingStreak(currentWeeks: 2, cooksThisWeek: 0)

        let fire = try #require(CookingStreak.lapseReminder(for: atRisk, now: day, calendar: cal, hour: 18))
        #expect(fire > day)
        let weekEnd = cal.dateInterval(of: .weekOfYear, for: day)!.end
        let lastDay = cal.date(byAdding: .day, value: -1, to: weekEnd)!
        #expect(fire == cal.date(bySettingHour: 18, minute: 0, second: 0, of: lastDay)!)
    }

    @Test func lapseReminder_notAtRisk_isNil() {
        #expect(CookingStreak.lapseReminder(for: CookingStreak(currentWeeks: 2, cooksThisWeek: 1), now: now) == nil)
    }

    @Test func lapseReminder_noStreak_isNil() {
        #expect(CookingStreak.lapseReminder(for: .empty, now: now) == nil)
    }

    @Test func multipleCooksSameWeek_countThisWeek() {
        let s = compute([now, cal.date(byAdding: .hour, value: -3, to: now)!])
        #expect(s.cooksThisWeek == 2)
        #expect(s.currentWeeks == 1)
    }
}
