import Testing
import Foundation
@testable import RecipeFinder

/// The opt-in Sunday planning nudge: when it fires (`SundayPlanNudge.fireDate`) and how `MealPlanningManager` keeps
/// the one pending notification in step with the switch and the plans. Fixed UTC calendar, week of Mon 16 Nov 2026.
@Suite struct SundayPlanNudgeTests {

    /// Monday-first (UK) unless told otherwise: Plan's week follows the calendar's first weekday.
    private static func calendar(_ zone: String, firstWeekday: Int = 2) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: zone) ?? .current
        cal.firstWeekday = firstWeekday
        return cal
    }

    private let cal = SundayPlanNudgeTests.calendar("UTC")

    /// `day` November 2026 at `hour`:`minute` (UTC). 22 and 29 Nov are Sundays.
    private func nov(_ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute)) ?? Date()
    }

    private func dinner(on date: Date, _ mealTime: MealTime = .dinner, recurring: Bool = false) -> MealPlanModel {
        MealPlanModel(recipeId: UUID(), recipeName: "Dal", date: date, mealTime: mealTime, isRecurring: recurring)
    }

    @Test func emptyPlanFiresThisComingSundayEvening() {
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: [], calendar: cal) == nov(22, 18))
    }

    @Test func sundayBeforeSixFiresTheSameEvening() {
        #expect(SundayPlanNudge.fireDate(now: nov(22, 17, 59), plans: [], calendar: cal) == nov(22, 18))
    }

    @Test func sundayAfterSixWaitsForNextSunday() {
        #expect(SundayPlanNudge.fireDate(now: nov(22, 18), plans: [], calendar: cal) == nov(29, 18))
    }

    @Test func aDinnerNextWeekMovesTheNudgeToTheFollowingSunday() {
        let plans = [dinner(on: nov(25, 19))]
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: cal) == nov(29, 18))
    }

    @Test(arguments: [MealTime.breakfast, .lunch, .snack])
    func otherMealsDoNotCountAsPlanned(_ mealTime: MealTime) {
        let plans = [dinner(on: nov(25), mealTime)]
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: cal) == nov(22, 18))
    }

    @Test func sundaysOwnDinnerIsNotNextWeek() {
        let plans = [dinner(on: nov(22, 19))]
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: cal) == nov(22, 18))
    }

    @Test func nextWeeksSundayDinnerCountsForNextWeek() {
        let plans = [dinner(on: nov(29, 19))]
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: cal) == nov(29, 18))
    }

    // Other first weekdays (US Sunday-first, Saturday-first, or the cook's own choice in iOS): the nudge checks the
    // Monday after it up to the end of Plan's week holding that Monday — the week a tap opens — never days up to tonight.

    @Test func sundayFirstLeavesTheFollowingSundaysDinnerToItsOwnWeek() {
        let plans = [dinner(on: nov(29, 19))]
        let sundayFirst = Self.calendar("UTC", firstWeekday: 1)
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: sundayFirst) == nov(22, 18))
    }

    @Test func saturdayFirstLeavesTheFollowingSaturdaysDinnerToItsOwnWeek() {
        let plans = [dinner(on: nov(28, 19))]
        let saturdayFirst = Self.calendar("UTC", firstWeekday: 7)
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: saturdayFirst) == nov(22, 18))
    }

    @Test(arguments: [1, 2, 4, 7])
    func tonightsOrAPastDinnerDoesNotStandInForTheWeekAhead(firstWeekday: Int) {
        let plans = [dinner(on: nov(18, 19)), dinner(on: nov(21, 19)), dinner(on: nov(22, 19))]
        let calendar = Self.calendar("UTC", firstWeekday: firstWeekday)
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: calendar) == nov(22, 18))
    }

    @Test(arguments: [1, 2, 4, 7])
    func theNextDaysDinnerCountsWhateverTheFirstWeekday(firstWeekday: Int) {
        let plans = [dinner(on: nov(23, 19))]
        let calendar = Self.calendar("UTC", firstWeekday: firstWeekday)
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: calendar) == nov(29, 18))
    }

    @Test(arguments: [1, 2, 4, 7])
    func aTapOpensThePlanWeekHoldingTheFirstDayChecked(firstWeekday: Int) throws {
        let calendar = Self.calendar("UTC", firstWeekday: firstWeekday)
        let info = SundayPlanNudge.userInfo(firingAt: nov(22, 18), calendar: calendar)
        let opened = try #require(info[SundayPlanNudge.weekStartKey].map { Date(timeIntervalSince1970: $0) })
        #expect(MealPlanCalendar(calendar: calendar).daysInWeek(containing: opened).contains(nov(23)))
    }

    @Test func aRepeatingDinnerMeansNoNudge() {
        let plans = [dinner(on: nov(10), recurring: true)]
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: cal) == nil)
    }

    @Test func aRepeatingDinnerStartingLaterCoversOnlyFromItsWeek() {
        let plans = [dinner(on: nov(30), recurring: true)]
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: cal) == nov(22, 18))
    }

    /// Sunday-first: the week checked after Sun 22 Nov is Mon 23–Sat 28, so a weekly Sunday dinner (next copy Sun 29,
    /// in the following week) leaves it open.
    @Test func sundayFirstAWeeklySundayDinnerDoesNotFillMondayToSaturday() {
        let plans = [dinner(on: nov(15, 19), recurring: true)]
        let sundayFirst = Self.calendar("UTC", firstWeekday: 1)
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: sundayFirst) == nov(22, 18))
    }

    @Test func mondayFirstAWeeklySundayDinnerFillsTheWeek() {
        let plans = [dinner(on: nov(15, 19), recurring: true)]
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: cal) == nil)
    }

    @Test(arguments: [1, 2, 4, 7])
    func aWeeklyWeekdayDinnerFillsEveryWeekAhead(firstWeekday: Int) {
        let plans = [dinner(on: nov(11, 19), recurring: true)] // Wednesdays
        let calendar = Self.calendar("UTC", firstWeekday: firstWeekday)
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: calendar) == nil)
    }

    /// A weekly dinner starting Sat 28 Nov fills a Monday-first week (23–29) from its first copy on.
    @Test func aWeeklyDinnerStartingMidWeekCountsForThatWeek() {
        let plans = [dinner(on: nov(28, 19), recurring: true)]
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: cal) == nil)
    }

    @Test func skipsPlannedWeeksToTheFirstEmptyOne() {
        let plans = [dinner(on: nov(24)), dinner(on: nov(30))]
        let sixthOfDecember = cal.date(from: DateComponents(year: 2026, month: 12, day: 6, hour: 18))
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: cal) == sixthOfDecember)
    }

    @Test func everyWeekPlannedAheadMeansNoNudge() {
        let plans = (0..<SundayPlanNudge.lookAheadWeeks).map { dinner(on: nov(23).addingTimeInterval(Double($0) * 7 * 86_400)) }
        #expect(SundayPlanNudge.fireDate(now: nov(20, 10), plans: plans, calendar: cal) == nil)
    }

    @Test func tapCarriesTheMondayAfterTheNudge() {
        var info: [AnyHashable: Any] = ["type": NotificationKind.planNudge.rawValue]
        for (key, value) in SundayPlanNudge.userInfo(firingAt: nov(22, 18), calendar: cal) { info[key] = value }
        #expect(SundayPlanNudge.weekStart(from: info) == nov(23))
    }

    @Test func otherNotificationsCarryNoWeek() {
        #expect(SundayPlanNudge.weekStart(from: ["type": "meal"]) == nil)
        #expect(SundayPlanNudge.weekStart(from: nil) == nil)
    }

    @Test func firesAtSixLocalTimeOnTheClockChangeSunday() throws {
        let london = Self.calendar("Europe/London")
        let saturday = try #require(london.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 12)))
        let fire = try #require(SundayPlanNudge.fireDate(now: saturday, plans: [], calendar: london))
        let parts = london.dateComponents([.month, .day, .hour, .minute], from: fire)
        #expect(parts == DateComponents(month: 10, day: 25, hour: 18, minute: 0))
    }
}

/// Records what `MealPlanningManager` asks of the nudge seam.
final class FakePlanNudgeScheduler: PlanNudgeScheduling {
    private(set) var scheduled: [(date: Date, id: String)] = []
    private(set) var cancelled: [String] = []

    func schedulePlanNudge(at date: Date, identifier: String) { scheduled.append((date, identifier)) }
    func cancelNotification(identifier: String) { cancelled.append(identifier) }
}

@MainActor
@Suite struct SundayPlanNudgeSchedulingTests {
    private let storage = LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
    private let nudges = FakePlanNudgeScheduler()

    private func makeManager() -> MealPlanningManager {
        MealPlanningManager(
            storage: storage, mealPlanStore: InMemoryMealPlanStore(),
            reminders: FakeMealReminderScheduler(), planNudges: nudges
        )
    }

    @Test func switchedOffSchedulesNothing() {
        let sut = makeManager()
        sut.syncPlanNudge()
        #expect(nudges.scheduled.isEmpty)
        #expect(nudges.cancelled.last == SundayPlanNudge.identifier)
    }

    @Test func switchedOnWithAnEmptyPlanSchedulesASundayEvening() throws {
        storage.set(true, forKey: SundayPlanNudge.settingKey)
        let sut = makeManager()
        sut.syncPlanNudge()
        let last = try #require(nudges.scheduled.last)
        #expect(last.id == SundayPlanNudge.identifier)
        #expect(last.date > Date())
        #expect(Calendar.current.component(.weekday, from: last.date) == 1)
        #expect(Calendar.current.component(.hour, from: last.date) == SundayPlanNudge.hour)
    }

    @Test func switchingOffCancelsThePendingNudge() {
        storage.set(true, forKey: SundayPlanNudge.settingKey)
        let sut = makeManager()
        sut.syncPlanNudge()
        let scheduledBefore = nudges.scheduled.count
        storage.set(false, forKey: SundayPlanNudge.settingKey)
        sut.syncPlanNudge()
        #expect(nudges.scheduled.count == scheduledBefore)
        #expect(nudges.cancelled.last == SundayPlanNudge.identifier)
    }

    @Test func planningNextWeeksDinnerMovesTheNudgeAWeekOn() throws {
        storage.set(true, forKey: SundayPlanNudge.settingKey)
        let sut = makeManager()
        let first = try #require(SundayPlanNudge.fireDate(now: Date(), plans: []))
        let monday = try #require(Calendar.current.date(byAdding: .day, value: 1, to: first))
        sut.addMealPlan(MealPlanModel(recipeId: UUID(), recipeName: "Dal", date: monday, mealTime: .dinner))
        #expect(nudges.scheduled.last?.date == Calendar.current.date(byAdding: .day, value: 7, to: first))
    }

    @Test func resetCancelsThePendingNudge() {
        storage.set(true, forKey: SundayPlanNudge.settingKey)
        let sut = makeManager()
        let scheduledBefore = nudges.scheduled.count
        storage.clearAll()
        sut.removeAllMealPlans()
        #expect(nudges.scheduled.count == scheduledBefore)
        #expect(nudges.cancelled.last == SundayPlanNudge.identifier)
    }

    @Test func reloadingPlansResyncsTheNudge() {
        let sut = makeManager()
        #expect(nudges.scheduled.isEmpty)
        storage.set(true, forKey: SundayPlanNudge.settingKey)
        sut.reload()
        #expect(nudges.scheduled.last?.id == SundayPlanNudge.identifier)
    }

    @Test func aRepeatingDinnerClearsThePendingNudge() {
        storage.set(true, forKey: SundayPlanNudge.settingKey)
        let sut = makeManager()
        sut.addMealPlan(MealPlanModel(
            recipeId: UUID(), recipeName: "Dal", date: Date(), mealTime: .dinner, isRecurring: true
        ))
        let scheduledBefore = nudges.scheduled.count
        sut.syncPlanNudge()
        #expect(nudges.scheduled.count == scheduledBefore)
        #expect(nudges.cancelled.last == SundayPlanNudge.identifier)
    }
}
