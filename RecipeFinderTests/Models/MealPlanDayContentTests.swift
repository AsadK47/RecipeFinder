import Testing
import Foundation
@testable import RecipeFinder

@Suite("MealPlanDayContent")
struct MealPlanDayContentTests {

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar
    }

    /// 18 Nov 2026, 09:00 UTC.
    private let now = Date(timeIntervalSince1970: 1_794_992_400)
    private let hour: TimeInterval = 3600

    private func content(selected: Bool = false, plans: Bool = false, offset: TimeInterval) -> MealPlanDayContent {
        MealPlanDayContent.make(hasSelectedMeals: selected, hasPlans: plans, date: now.addingTimeInterval(offset),
                                now: now, calendar: calendar)
    }

    @Test("Meals on screen show the planned cards, even on an old day")
    func plannedMeals() {
        #expect(content(selected: true, offset: -30 * 24 * hour) == .plannedMeals)
    }

    @Test("Today, later and the last 24 hours show the day's empty state", arguments: [0, 8, -8, -23, 48])
    func emptyDay(hours: Double) {
        #expect(content(offset: hours * hour) == .emptyDay)
    }

    @Test("Older than 24 hours shows the general empty state", arguments: [-24, -25, -24 * 7])
    func emptyPast(hours: Double) {
        #expect(content(offset: hours * hour) == .emptyPast)
    }

    @Test("Early today on a 25-hour clock-change day is still today")
    func clockChangeDayIsToday() {
        var london = Calendar(identifier: .gregorian)
        london.timeZone = TimeZone(identifier: "Europe/London") ?? .current
        // 25 Oct 2026, 23:30 GMT; 00:15 BST the same day is 24h15m earlier.
        let lateEvening = Date(timeIntervalSince1970: 1_792_971_000)
        let justAfterMidnight = Date(timeIntervalSince1970: 1_792_883_700)

        #expect(MealPlanDayContent.make(hasSelectedMeals: false, hasPlans: false, date: justAfterMidnight,
                                        now: lateEvening, calendar: london) == .emptyDay)
    }

    @Test("An old day with stored plans keeps the day's empty state")
    func oldDayWithPlans() {
        #expect(content(plans: true, offset: -24 * 7 * hour) == .emptyDay)
    }
}
