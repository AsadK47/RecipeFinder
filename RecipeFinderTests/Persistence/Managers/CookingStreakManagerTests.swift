import Testing
import Foundation
@testable import RecipeFinder

/// `CookingStreakManager` recording + persistence, on isolated UserDefaults.
@MainActor
@Suite struct CookingStreakManagerTests {

    private func makeManager() -> CookingStreakManager {
        CookingStreakManager(
            storage: LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!),
            cookDateStore: InMemoryCookDateStore()
        )
    }

    /// Records what the streak manager asks of the notification seam.
    final class FakeStreakReminderScheduler: StreakReminderScheduling {
        private(set) var scheduled: [(weeks: Int, date: Date, id: String)] = []
        private(set) var cancelled: [String] = []
        func scheduleStreakReminder(weeks: Int, at date: Date, identifier: String) {
            scheduled.append((weeks, date, identifier))
        }
        func cancelNotification(identifier: String) { cancelled.append(identifier) }
    }

    @Test func cookingThisWeek_cancelsLapseReminder_schedulesNone() {
        let fake = FakeStreakReminderScheduler()
        let sut = CookingStreakManager(
            storage: LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!),
            cookDateStore: InMemoryCookDateStore(),
            reminders: fake
        )
        sut.recordCook(on: Date())   // cooked this week → not at risk
        #expect(fake.cancelled.contains("cooking-streak-lapse"))
        #expect(fake.scheduled.isEmpty)
    }

    @Test func initialState_isEmpty() {
        #expect(makeManager().streak == .empty)
    }

    @Test func recordCook_updatesStreak() {
        let sut = makeManager()
        sut.recordCook(on: Date())
        #expect(sut.streak.cooksThisWeek == 1)
        #expect(sut.streak.currentWeeks == 1)
    }

    @Test func recordCook_returnsTrue_whenItStartsOrExtendsStreak() {
        let sut = makeManager()
        #expect(sut.recordCook(on: Date()) == true)   // 0 → 1 week: streak started
    }

    @Test func recordCook_returnsFalse_forSecondCookSameWeek() {
        let sut = makeManager()
        _ = sut.recordCook(on: Date())
        #expect(sut.recordCook(on: Date()) == false)   // same week, no new week counted
    }

    @Test func recordCook_persistsAcrossReload() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = LocalStore(userDefaults: defaults)
        let cookDates = InMemoryCookDateStore()

        let first = CookingStreakManager(storage: storage, cookDateStore: cookDates)
        first.recordCook(on: Date())

        // Fresh instance, same storage → the cook log survives.
        let second = CookingStreakManager(storage: storage, cookDateStore: cookDates)
        #expect(second.streak.cooksThisWeek == 1)
        #expect(second.streak.currentWeeks == 1)
    }

    @Test func reload_picksUpStoredLog() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = LocalStore(userDefaults: defaults)
        let cookDates = InMemoryCookDateStore()

        let writer = CookingStreakManager(storage: storage, cookDateStore: cookDates)
        writer.recordCook(on: Date())

        let reader = CookingStreakManager(storage: storage, cookDateStore: cookDates)
        reader.reload()
        #expect(reader.streak.cookedThisWeek)
    }
}
