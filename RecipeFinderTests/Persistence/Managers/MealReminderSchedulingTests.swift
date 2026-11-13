import Testing
import Foundation
@testable import RecipeFinder

/// Records what `MealPlanningManager` asks of the reminder seam so scheduling side-effects are assertable.
final class FakeMealReminderScheduler: MealReminderScheduling {
    struct Scheduled {
        let id: String
        let mealName: String
        let recipeName: String
        let date: Date
        let repeatsWeekly: Bool
    }
    private(set) var scheduled: [Scheduled] = []
    private(set) var cancelled: [String] = []

    @discardableResult
    func scheduleMealReminder(
        mealName: String,
        recipeName: String,
        date: Date,
        identifier: String?,
        repeatsWeekly: Bool
    ) -> String {
        let id = identifier ?? "meal-\(UUID().uuidString)"
        scheduled.append(Scheduled(id: id, mealName: mealName, recipeName: recipeName, date: date, repeatsWeekly: repeatsWeekly))
        return id
    }

    func cancelNotification(identifier: String) { cancelled.append(identifier) }
}

/// `MealPlanningManager` reminder scheduling across its mutation paths, with a fake scheduler.
@MainActor
@Suite struct MealReminderSchedulingTests {

    private func makeManager(_ scheduler: FakeMealReminderScheduler) -> MealPlanningManager {
        MealPlanningManager(
            storage: LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!), mealPlanStore: InMemoryMealPlanStore(),
            reminders: scheduler
        )
    }

    private func futureDay() -> Date {
        Calendar.current.date(byAdding: .day, value: 2, to: Date())!
    }

    private func pastDay() -> Date {
        Calendar.current.date(byAdding: .day, value: -2, to: Date())!
    }

    private func clock(_ hour: Int, _ minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())!
    }

    private func plan(
        date: Date,
        mealTime: MealTime = .dinner,
        isRecurring: Bool = false,
        reminderTime: Date? = nil,
        isCompleted: Bool = false
    ) -> MealPlanModel {
        MealPlanModel(
            recipeId: UUID(), recipeName: "Soup", date: date, mealTime: mealTime,
            isCompleted: isCompleted, isRecurring: isRecurring, reminderTime: reminderTime
        )
    }

    // MARK: - add

    @Test func add_futureOneOff_schedulesOnceNonRepeating() throws {
        let fake = FakeMealReminderScheduler()
        let sut = makeManager(fake)
        let p = plan(date: futureDay(), mealTime: .lunch, reminderTime: clock(13))

        sut.addMealPlan(p)

        #expect(fake.scheduled.count == 1)
        let s = try #require(fake.scheduled.first)
        #expect(s.id == "meal-\(p.id.uuidString)")
        #expect(s.mealName == MealTime.lunch.rawValue)
        #expect(s.recipeName == "Soup")
        #expect(s.repeatsWeekly == false)
    }

    @Test func add_recurring_schedulesWeekly() throws {
        let fake = FakeMealReminderScheduler()
        let sut = makeManager(fake)
        // Even a past day repeats weekly (fires on the next matching weekday).
        sut.addMealPlan(plan(date: pastDay(), isRecurring: true, reminderTime: clock(19)))

        let s = try #require(fake.scheduled.first)
        #expect(s.repeatsWeekly == true)
    }

    @Test func add_pastOneOff_doesNotSchedule() {
        let fake = FakeMealReminderScheduler()
        let sut = makeManager(fake)
        sut.addMealPlan(plan(date: pastDay(), reminderTime: clock(19)))
        #expect(fake.scheduled.isEmpty)
    }

    @Test func add_noReminderTime_doesNotSchedule() {
        let fake = FakeMealReminderScheduler()
        let sut = makeManager(fake)
        sut.addMealPlan(plan(date: futureDay(), reminderTime: nil))
        #expect(fake.scheduled.isEmpty)
    }

    @Test func add_completedMeal_doesNotSchedule() {
        let fake = FakeMealReminderScheduler()
        let sut = makeManager(fake)
        sut.addMealPlan(plan(date: futureDay(), reminderTime: clock(19), isCompleted: true))
        #expect(fake.scheduled.isEmpty)
    }

    // MARK: - update / remove / complete

    @Test func update_clearingReminderTime_cancels() {
        let fake = FakeMealReminderScheduler()
        let sut = makeManager(fake)
        var p = plan(date: futureDay(), reminderTime: clock(19))
        sut.addMealPlan(p)

        p.reminderTime = nil
        sut.updateMealPlan(p)

        #expect(fake.cancelled.contains("meal-\(p.id.uuidString)"))
    }

    @Test func remove_cancelsReminder() {
        let fake = FakeMealReminderScheduler()
        let sut = makeManager(fake)
        let p = plan(date: futureDay(), reminderTime: clock(19))
        sut.addMealPlan(p)

        sut.removeMealPlan(p)

        #expect(fake.cancelled.contains("meal-\(p.id.uuidString)"))
    }

    @Test func completing_cancelsAndDoesNotReschedule() {
        let fake = FakeMealReminderScheduler()
        let sut = makeManager(fake)
        let p = plan(date: futureDay(), reminderTime: clock(19))
        sut.addMealPlan(p)
        let scheduledBefore = fake.scheduled.count

        sut.toggleCompletion(p)

        #expect(fake.cancelled.contains("meal-\(p.id.uuidString)"))
        #expect(fake.scheduled.count == scheduledBefore)  // no new schedule after completion
    }

    @Test func toggleRecurring_reschedulesAsWeekly() {
        let fake = FakeMealReminderScheduler()
        let sut = makeManager(fake)
        let p = plan(date: futureDay(), reminderTime: clock(19))
        sut.addMealPlan(p)

        sut.toggleRecurring(p)

        #expect(fake.scheduled.last?.repeatsWeekly == true)
    }

    // MARK: - fire-date helper

    @Test func reminderFireDate_combinesDayWithClockTime() throws {
        let cal = Calendar.current
        let day = cal.date(from: DateComponents(year: 2030, month: 6, day: 15))!
        let time = cal.date(bySettingHour: 7, minute: 45, second: 0, of: Date())!

        let fire = try #require(MealPlanningManager.reminderFireDate(day: day, time: time, calendar: cal))
        let c = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        #expect(c.year == 2030 && c.month == 6 && c.day == 15)
        #expect(c.hour == 7 && c.minute == 45)
    }

    @Test func mealTime_defaultReminderTimes() {
        #expect(MealTime.breakfast.defaultReminderHourMinute == (8, 0))
        #expect(MealTime.lunch.defaultReminderHourMinute == (13, 0))
        #expect(MealTime.dinner.defaultReminderHourMinute == (19, 0))
        #expect(MealTime.snack.defaultReminderHourMinute == (15, 0))
    }
}
