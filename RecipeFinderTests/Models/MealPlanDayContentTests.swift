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

    @Test("Older than 24 hours shows the general empty state", arguments: [-25, -24 * 7])
    func emptyPast(hours: Double) {
        #expect(content(offset: hours * hour) == .emptyPast)
    }

    @Test("An old day with stored plans keeps the day's empty state")
    func oldDayWithPlans() {
        #expect(content(plans: true, offset: -24 * 7 * hour) == .emptyDay)
    }
}
