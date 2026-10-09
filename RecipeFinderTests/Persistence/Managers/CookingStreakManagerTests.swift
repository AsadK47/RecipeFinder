import Testing
import Foundation
@testable import RecipeFinder

/// `CookingStreakManager` recording + per-user persistence, on isolated UserDefaults.
@MainActor
@Suite struct CookingStreakManagerTests {

    private func makeManager() -> CookingStreakManager {
        CookingStreakManager(storage: UserScopedStorage(userDefaults: UserDefaults(suiteName: UUID().uuidString)!))
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
            storage: UserScopedStorage(userDefaults: UserDefaults(suiteName: UUID().uuidString)!),
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
        let storage = UserScopedStorage(userDefaults: defaults)

        let first = CookingStreakManager(storage: storage)
        first.recordCook(on: Date())

        // Fresh instance, same storage → the cook log survives.
        let second = CookingStreakManager(storage: storage)
        #expect(second.streak.cooksThisWeek == 1)
        #expect(second.streak.currentWeeks == 1)
    }

    @Test func reloadForCurrentUser_picksUpStoredLog() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = UserScopedStorage(userDefaults: defaults)

        let writer = CookingStreakManager(storage: storage)
        writer.recordCook(on: Date())

        let reader = CookingStreakManager(storage: storage)
        reader.reloadForCurrentUser()
        #expect(reader.streak.cookedThisWeek)
    }
}
