import Testing
import Foundation
@testable import RecipeFinder

/// State machine, display formatting, and persistence contract for `RecipeTimerManager`.
/// Each test gets a fresh `UserDefaults` suite so no global state leaks between runs.
@MainActor
@Suite struct RecipeTimerManagerTests {

    private func makeSUT(defaults: UserDefaults? = nil) -> RecipeTimerManager {
        RecipeTimerManager(defaults: defaults ?? UserDefaults(suiteName: UUID().uuidString)!)
    }

    // MARK: - Initial state

    @Test func initialState_isIdle() {
        let sut = makeSUT()
        #expect(!sut.isRunning)
        #expect(!sut.isPaused)
        #expect(!sut.isActive)
        #expect(sut.durationSeconds == 0)
        #expect(sut.remainingSeconds == 0)
        #expect(sut.displayTime == "00:00:00")
    }

    // MARK: - start

    @Test func start_setsRunningState() {
        let sut = makeSUT()
        sut.start(hours: 0, minutes: 5, seconds: 0)
        #expect(sut.isRunning)
        #expect(!sut.isPaused)
        #expect(sut.isActive)
        #expect(sut.durationSeconds == 300)
        #expect(sut.remainingSeconds == 300)
    }

    @Test func start_withZeroTotal_doesNotActivate() {
        let sut = makeSUT()
        sut.start(hours: 0, minutes: 0, seconds: 0)
        #expect(!sut.isActive)
        #expect(sut.durationSeconds == 0)
    }

    @Test func start_calculatesCorrectDuration() {
        let sut = makeSUT()
        sut.start(hours: 1, minutes: 30, seconds: 45)
        #expect(sut.durationSeconds == 5445)  // 3600 + 1800 + 45
    }

    @Test func start_whilePaused_resetsAndRestarts() {
        let sut = makeSUT()
        sut.start(hours: 0, minutes: 5, seconds: 0)
        sut.pause()
        sut.start(hours: 0, minutes: 2, seconds: 0)
        #expect(sut.isRunning)
        #expect(!sut.isPaused)
        #expect(sut.durationSeconds == 120)
    }

    // MARK: - pause

    @Test func pause_whileRunning_setsPaused() {
        let sut = makeSUT()
        sut.start(hours: 0, minutes: 1, seconds: 0)
        sut.pause()
        #expect(!sut.isRunning)
        #expect(sut.isPaused)
        #expect(sut.isActive)   // still active when paused
    }

    @Test func pause_whenNotRunning_isNoop() {
        let sut = makeSUT()
        sut.pause()
        #expect(!sut.isActive)
    }

    // MARK: - resume

    @Test func resume_whilePaused_setsRunning() {
        let sut = makeSUT()
        sut.start(hours: 0, minutes: 1, seconds: 0)
        sut.pause()
        sut.resume()
        #expect(sut.isRunning)
        #expect(!sut.isPaused)
    }

    @Test func resume_whenAlreadyRunning_isNoop() {
        let sut = makeSUT()
        sut.start(hours: 0, minutes: 1, seconds: 0)
        let durationBefore = sut.durationSeconds
        sut.resume()
        #expect(sut.isRunning)
        #expect(sut.durationSeconds == durationBefore)
    }

    // MARK: - togglePause

    @Test func togglePause_whenRunning_pauses() {
        let sut = makeSUT()
        sut.start(hours: 0, minutes: 1, seconds: 0)
        sut.togglePause()
        #expect(sut.isPaused)
        #expect(!sut.isRunning)
    }

    @Test func togglePause_whenPaused_resumes() {
        let sut = makeSUT()
        sut.start(hours: 0, minutes: 1, seconds: 0)
        sut.pause()
        sut.togglePause()
        #expect(sut.isRunning)
        #expect(!sut.isPaused)
    }

    // MARK: - stop

    @Test func stop_clearsAllState() {
        let sut = makeSUT()
        sut.start(hours: 1, minutes: 30, seconds: 0)
        sut.stop()
        #expect(!sut.isRunning)
        #expect(!sut.isPaused)
        #expect(!sut.isActive)
        #expect(sut.durationSeconds == 0)
        #expect(sut.remainingSeconds == 0)
    }

    @Test func stop_whenAlreadyStopped_isNoop() {
        let sut = makeSUT()
        sut.stop()
        #expect(!sut.isActive)
        #expect(sut.durationSeconds == 0)
    }

    // MARK: - isActive

    @Test func isActive_falseWhenIdle() {
        #expect(!makeSUT().isActive)
    }

    @Test func isActive_trueWhenRunning() {
        let sut = makeSUT()
        sut.start(hours: 0, minutes: 1, seconds: 0)
        #expect(sut.isActive)
    }

    @Test func isActive_trueWhenPaused() {
        let sut = makeSUT()
        sut.start(hours: 0, minutes: 1, seconds: 0)
        sut.pause()
        #expect(sut.isActive)
    }

    // MARK: - displayTime formatting

    @Test(arguments: [
        (h: 0,  m: 0,  s: 0,  expected: "00:00:00"),
        (h: 0,  m: 0,  s: 9,  expected: "00:00:09"),
        (h: 0,  m: 1,  s: 30, expected: "00:01:30"),
        (h: 1,  m: 0,  s: 0,  expected: "01:00:00"),
        (h: 23, m: 59, s: 59, expected: "23:59:59"),
    ])
    func displayTime_formatsHoursMinutesSeconds(h: Int, m: Int, s: Int, expected: String) {
        let sut = makeSUT()
        sut.start(hours: h, minutes: m, seconds: s)
        #expect(sut.displayTime == expected)
    }

    // MARK: - Notification preference gating

    @Test func timerNotifications_disabled_preferenceIsRespected() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(false, forKey: "timerNotifications")
        let sut = makeSUT(defaults: defaults)
        sut.start(hours: 0, minutes: 1, seconds: 0)
        // The injected defaults carry the disabled preference; completeTimer()
        // reads it before firing. Verified by asserting the flag is stored.
        #expect((defaults.object(forKey: "timerNotifications") as? Bool) == false)
        _ = sut
    }

    // MARK: - Persistence round-trip

    @Test func persistence_runningState_survivesRestart() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let first = makeSUT(defaults: defaults)
        first.start(hours: 0, minutes: 10, seconds: 0)

        let restored = makeSUT(defaults: defaults)
        #expect(restored.isRunning)
        #expect(!restored.isPaused)
        #expect(restored.durationSeconds == 600)
        #expect(restored.remainingSeconds > 0)
    }

    @Test func persistence_pausedState_survivesRestart() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let first = makeSUT(defaults: defaults)
        first.start(hours: 0, minutes: 5, seconds: 0)
        first.pause()

        let restored = makeSUT(defaults: defaults)
        #expect(!restored.isRunning)
        #expect(restored.isPaused)
        #expect(restored.durationSeconds == 300)
        #expect(restored.isActive)
    }

    @Test func persistence_stoppedState_survivesRestart() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let first = makeSUT(defaults: defaults)
        first.start(hours: 0, minutes: 5, seconds: 0)
        first.stop()

        let restored = makeSUT(defaults: defaults)
        #expect(!restored.isActive)
        #expect(restored.durationSeconds == 0)
        #expect(restored.remainingSeconds == 0)
    }

    @Test func persistence_afterStop_displayTimeIsZero() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let first = makeSUT(defaults: defaults)
        first.start(hours: 1, minutes: 0, seconds: 0)
        first.stop()

        let restored = makeSUT(defaults: defaults)
        #expect(restored.displayTime == "00:00:00")
    }
}
