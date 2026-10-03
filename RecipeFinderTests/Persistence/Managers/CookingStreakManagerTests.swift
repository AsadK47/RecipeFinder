import Testing
import Foundation
@testable import RecipeFinder

/// `CookingStreakManager` recording + per-user persistence, on isolated UserDefaults.
@MainActor
@Suite struct CookingStreakManagerTests {

    private func makeManager() -> CookingStreakManager {
        CookingStreakManager(storage: UserScopedStorage(userDefaults: UserDefaults(suiteName: UUID().uuidString)!))
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
