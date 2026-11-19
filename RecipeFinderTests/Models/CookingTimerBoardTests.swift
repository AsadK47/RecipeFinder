import Foundation
import Testing
@testable import RecipeFinder

@Suite("CookingTimerBoard")
struct CookingTimerBoardTests {

    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    // MARK: - Several named timers

    @Test("Two steps' timers run side by side, each with its own name and time")
    func severalTimers() throws {
        var board = CookingTimerBoard()
        board.start(name: "Rice", seconds: 720, key: "r#3", now: t0)
        board.start(name: "Sauce", seconds: 240, key: "r#4", now: t0.addingTimeInterval(60))
        #expect(board.timers.map(\.name) == ["Rice", "Sauce"])
        let later = t0.addingTimeInterval(120)
        #expect(board.timers.map { $0.remaining(at: later) } == [600, 180])
    }

    @Test("The same step's button can't start a second copy")
    func oneTimerPerKey() throws {
        var board = CookingTimerBoard()
        let firstResult = board.start(name: "Rice", seconds: 720, key: "r#3", now: t0)
        let first = try #require(firstResult)
        let again = board.start(name: "Rice", seconds: 720, key: "r#3", now: t0.addingTimeInterval(30))
        #expect(again?.id == first.id)
        #expect(board.timers.count == 1)
        #expect(board.timer(forKey: "r#3", now: t0)?.id == first.id)
    }

    @Test("A step whose timer finished can time again, replacing the finished one")
    func finishedFreesStep() throws {
        var board = CookingTimerBoard()
        let firstResult = board.start(name: "Rice", seconds: 60, key: "r#3", now: t0)
        let first = try #require(firstResult).id
        let later = t0.addingTimeInterval(120)
        #expect(board.timer(forKey: "r#3", now: later) == nil)
        let againResult = board.start(name: "Rice", seconds: 60, key: "r#3", now: later)
        let again = try #require(againResult)
        #expect(again.id != first)
        #expect(board.timers.map(\.id) == [again.id])
    }

    @Test("A paused step timer still holds its step")
    func pausedHoldsStep() throws {
        var board = CookingTimerBoard()
        let idResult = board.start(name: "Rice", seconds: 60, key: "r#3", now: t0)
        let id = try #require(idResult).id
        board.togglePause(id, now: t0.addingTimeInterval(10))
        #expect(board.timer(forKey: "r#3", now: t0.addingTimeInterval(500))?.id == id)
    }

    @Test("Done timers are the ones at zero")
    func doneIDs() throws {
        var board = CookingTimerBoard()
        let shortResult = board.start(name: "A", seconds: 10, key: nil, now: t0)
        let short = try #require(shortResult).id
        board.start(name: "B", seconds: 100, key: nil, now: t0)
        #expect(CookingTimerBoard.doneIDs(board.timers, at: t0.addingTimeInterval(5)).isEmpty)
        #expect(CookingTimerBoard.doneIDs(board.timers, at: t0.addingTimeInterval(10)) == [short])
    }

    @Test("A timer with no key can start any number of times")
    func unkeyedTimers() {
        var board = CookingTimerBoard()
        board.start(name: "Oven", seconds: 60, key: nil, now: t0)
        board.start(name: "Oven", seconds: 60, key: nil, now: t0)
        #expect(board.timers.count == 2)
    }

    @Test("A zero-length timer isn't added", arguments: [0, -5])
    func zeroLength(seconds: Int) {
        var board = CookingTimerBoard()
        let r1 = board.start(name: "Rice", seconds: seconds, key: "k", now: t0)
        #expect(r1 == nil)
        #expect(board.timers.isEmpty)
    }

    @Test("Remaining rounds part-seconds up and stops at zero, which is done")
    func remainingAndDone() throws {
        var board = CookingTimerBoard()
        let timerResult = board.start(name: "Rice", seconds: 10, key: nil, now: t0)
        let timer = try #require(timerResult)
        #expect(timer.remaining(at: t0.addingTimeInterval(0.4)) == 10)
        #expect(!timer.isDone(at: t0.addingTimeInterval(9.5)))
        #expect(timer.remaining(at: t0.addingTimeInterval(30)) == 0)
        #expect(timer.isDone(at: t0.addingTimeInterval(10)))
    }

    // MARK: - Pause, +1 min, stop

    @Test("Pausing holds the time left; resuming counts on from there")
    func pauseAndResume() throws {
        var board = CookingTimerBoard()
        let idResult = board.start(name: "Rice", seconds: 600, key: nil, now: t0)
        let id = try #require(idResult).id
        let pausedResult = board.togglePause(id, now: t0.addingTimeInterval(100))
        let paused = try #require(pausedResult)
        #expect(paused.isPaused)
        #expect(paused.remaining(at: t0.addingTimeInterval(400)) == 500)
        let resumedResult = board.togglePause(id, now: t0.addingTimeInterval(400))
        let resumed = try #require(resumedResult)
        #expect(!resumed.isPaused)
        #expect(resumed.remaining(at: t0.addingTimeInterval(500)) == 400)
    }

    @Test("A finished timer can't be paused")
    func finishedStaysFinished() throws {
        var board = CookingTimerBoard()
        let idResult = board.start(name: "Rice", seconds: 10, key: nil, now: t0)
        let id = try #require(idResult).id
        let after = t0.addingTimeInterval(20)
        let timerResult = board.togglePause(id, now: after)
        let timer = try #require(timerResult)
        #expect(!timer.isPaused)
        #expect(timer.isDone(at: after))
    }

    @Test("+1 min adds to a running, a paused and a finished timer")
    func addMinute() throws {
        var board = CookingTimerBoard()
        let runningResult = board.start(name: "A", seconds: 100, key: nil, now: t0)
        let running = try #require(runningResult).id
        let pausedResult = board.start(name: "B", seconds: 100, key: nil, now: t0)
        let paused = try #require(pausedResult).id
        let finishedResult = board.start(name: "C", seconds: 10, key: nil, now: t0)
        let finished = try #require(finishedResult).id
        board.togglePause(paused, now: t0.addingTimeInterval(40))
        let now = t0.addingTimeInterval(50)
        let r2 = board.add(seconds: 60, to: running, now: now)
        #expect(r2?.remaining(at: now) == 110)
        let r3 = board.add(seconds: 60, to: paused, now: now)
        #expect(r3?.remaining(at: now) == 120)
        let r4 = board.add(seconds: 60, to: finished, now: now)
        #expect(r4?.remaining(at: now) == 60)
        #expect(board.timer(paused)?.isPaused == true)
    }

    @Test("Stopping removes only that timer, and frees its step to start again")
    func stop() throws {
        var board = CookingTimerBoard()
        let riceResult = board.start(name: "Rice", seconds: 600, key: "r#3", now: t0)
        let rice = try #require(riceResult).id
        board.start(name: "Sauce", seconds: 600, key: "r#4", now: t0)
        board.remove(rice)
        #expect(board.timers.map(\.name) == ["Sauce"])
        #expect(board.timer(forKey: "r#3", now: t0) == nil)
        let r5 = board.start(name: "Rice", seconds: 600, key: "r#3", now: t0)
        #expect(r5?.id != rice)
    }

    @Test("Unknown ids change nothing")
    func unknownID() {
        var board = CookingTimerBoard()
        let r6 = board.togglePause(UUID(), now: t0)
        #expect(r6 == nil)
        let r7 = board.add(seconds: 60, to: UUID(), now: t0)
        #expect(r7 == nil)
    }

    // MARK: - Display

    @Test("Clock shows minutes:seconds, hours only when there are some", arguments: [
        (720, "12:00"), (45, "0:45"), (3900, "1:05:00"), (0, "0:00"), (-3, "0:00")
    ])
    func clock(seconds: Int, expected: String) {
        #expect(CookingTimerBoard.clock(seconds: seconds) == expected)
    }

    @Test("VoiceOver reads the time in words", arguments: [
        (725, "12 minutes 5 seconds"), (60, "1 minute"), (3601, "1 hour 1 second"), (0, "0 seconds")
    ])
    func spoken(seconds: Int, expected: String) {
        #expect(CookingTimerBoard.spoken(seconds: seconds) == expected)
    }
}

@Suite("CookingTimerName")
struct CookingTimerNameTests {

    /// Every ingredient counts as used, so these test the naming alone (matching has its own suite).
    private func name(_ step: String, _ names: [String], used: Bool = true) -> String {
        let ingredients = names.map { Ingredient(baseQuantity: 1, unit: "", name: $0) }
        let uses = used ? ingredients.indices.map { StepIngredientMatcher.Use(index: $0, stepGivesAmount: false) } : []
        return CookingTimerName.name(for: step, uses: uses, ingredients: ingredients, fallback: "Step 4")
    }

    @Test("Named after the ingredient the step mentions first, not recipe order")
    func firstMentioned() {
        #expect(name("Add the rice to the onions and simmer for 12 minutes.", ["onion", "basmati rice"]) == "Basmati rice")
    }

    @Test("A long name keeps its last two words")
    func shortName() {
        #expect(name("Pour in the soy sauce and cook 2 minutes.", ["light soy sauce"]) == "Soy sauce")
    }

    @Test("A step naming no ingredient falls back to the step")
    func fallback() {
        #expect(name("Bake for 25 minutes.", ["butter"], used: false) == "Step 4")
    }

    @Test("A used ingredient the step words differently still names it")
    func unmentioned() {
        #expect(name("Cook until tender, about 10 minutes.", ["broccoli"]) == "Broccoli")
    }

    @Test("A note after a comma or in brackets stays off the name")
    func noteOff() {
        #expect(name("Boil the potatoes for 20 minutes.", ["potatoes (floury), peeled"]) == "Potatoes")
    }
}

@Suite("CookingTimers")
@MainActor
struct CookingTimersTests {

    private final class Clock {
        var date = Date(timeIntervalSince1970: 1_800_000_000)
    }

    private final class FakeAlerts: CookingTimerAlerting {
        var scheduled: [String: TimeInterval] = [:]
        var titles: [String: String] = [:]
        var cancelled: [String] = []
        func schedule(id: String, title: String, body: String, after seconds: TimeInterval) {
            scheduled[id] = seconds
            titles[id] = title
        }
        func cancel(id: String) { cancelled.append(id) }
    }

    @Test("Starting a timer schedules its own named alert for when it ends")
    func startSchedules() throws {
        let alerts = FakeAlerts()
        let timers = CookingTimers(now: { Clock().date }, alerts: alerts)
        let rice = try #require(timers.start(name: "Rice", minutes: 12, key: "r#3"))
        let sauce = try #require(timers.start(name: "Sauce", minutes: 4, key: "r#4"))
        #expect(alerts.scheduled[CookingTimers.alertID(rice.id)] == 720)
        #expect(alerts.scheduled[CookingTimers.alertID(sauce.id)] == 240)
        #expect(alerts.titles[CookingTimers.alertID(rice.id)] == "⏰ Rice is ready")
    }

    @Test("Tapping the same step again doesn't reschedule")
    func repeatStart() throws {
        let alerts = FakeAlerts()
        let timers = CookingTimers(now: { Clock().date }, alerts: alerts)
        timers.start(name: "Rice", minutes: 12, key: "r#3")
        timers.start(name: "Rice", minutes: 12, key: "r#3")
        #expect(timers.timers.count == 1)
        #expect(alerts.scheduled.count == 1)
    }

    @Test("Pause cancels the alert; resume schedules it for the time left")
    func pauseResume() throws {
        let clock = Clock()
        let alerts = FakeAlerts()
        let timers = CookingTimers(now: { clock.date }, alerts: alerts)
        let id = try #require(timers.start(name: "Rice", minutes: 10, key: nil)).id
        clock.date += 100
        timers.togglePause(id)
        #expect(alerts.cancelled == [CookingTimers.alertID(id)])
        clock.date += 1000
        timers.togglePause(id)
        #expect(alerts.scheduled[CookingTimers.alertID(id)] == 500)
    }

    @Test("+1 min moves the alert later; on a paused timer it waits for resume")
    func addMinute() throws {
        let clock = Clock()
        let alerts = FakeAlerts()
        let timers = CookingTimers(now: { clock.date }, alerts: alerts)
        let id = try #require(timers.start(name: "Rice", minutes: 10, key: nil)).id
        clock.date += 100
        timers.addMinute(id)
        #expect(alerts.scheduled[CookingTimers.alertID(id)] == 560)
        timers.togglePause(id)
        alerts.scheduled = [:]
        timers.addMinute(id)
        #expect(alerts.scheduled.isEmpty)
    }

    @Test("Pausing a finished timer neither cancels nor re-arms an alert")
    func pauseFinished() throws {
        let clock = Clock()
        let alerts = FakeAlerts()
        let timers = CookingTimers(now: { clock.date }, alerts: alerts)
        let id = try #require(timers.start(name: "Rice", minutes: 1, key: nil)).id
        clock.date += 120
        alerts.scheduled = [:]
        timers.togglePause(id)
        #expect(alerts.cancelled.isEmpty)
        #expect(alerts.scheduled.isEmpty)
    }

    @Test("+1 min on a finished timer sets a fresh one-minute alert")
    func addMinuteFinished() throws {
        let clock = Clock()
        let alerts = FakeAlerts()
        let timers = CookingTimers(now: { clock.date }, alerts: alerts)
        let id = try #require(timers.start(name: "Rice", minutes: 1, key: nil)).id
        clock.date += 120
        timers.addMinute(id)
        #expect(alerts.scheduled[CookingTimers.alertID(id)] == 60)
    }

    @Test("Step keys differ per recipe and per step")
    func stepKeys() {
        let a = UUID(), b = UUID()
        #expect(CookingTimers.stepKey(recipeID: a, index: 3) != CookingTimers.stepKey(recipeID: b, index: 3))
        #expect(CookingTimers.stepKey(recipeID: a, index: 3) != CookingTimers.stepKey(recipeID: a, index: 4))
        #expect(CookingTimers.stepKey(recipeID: a, index: 3) == CookingTimers.stepKey(recipeID: a, index: 3))
    }

    @Test("The step button says start, on or paused")
    func stepTimerTitle() throws {
        var board = CookingTimerBoard()
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)
        let started = board.start(name: "Rice", seconds: 600, key: nil, now: t0)
        let rice = try #require(started)
        #expect(CookingModeView.stepTimerTitle(minutes: 12, running: nil) == "Start 12-minute timer")
        #expect(CookingModeView.stepTimerTitle(minutes: 12, running: rice) == "Rice timer is on")
        let pausedResult = board.togglePause(rice.id, now: t0)
        let paused = try #require(pausedResult)
        #expect(CookingModeView.stepTimerTitle(minutes: 12, running: paused) == "Rice timer paused")
    }

    @Test("Finish closes into Made it when the cook counts, else shows the done screen")
    func finishStep() {
        #expect(CookingModeView.finishStep(cookLogged: true) == .madeIt)
        #expect(CookingModeView.finishStep(cookLogged: false) == .alreadyCounted)
    }

    @Test("Stop removes the timer and its alert")
    func stop() throws {
        let alerts = FakeAlerts()
        let timers = CookingTimers(now: { Clock().date }, alerts: alerts)
        let id = try #require(timers.start(name: "Rice", minutes: 10, key: "r#3")).id
        timers.stop(id)
        #expect(timers.timers.isEmpty)
        #expect(timers.timer(forKey: "r#3", now: Clock().date) == nil)
        #expect(alerts.cancelled == [CookingTimers.alertID(id)])
    }

    @Test("VoiceOver says the name, time left and whether it's paused or done")
    func accessibility() {
        #expect(CookingTimerStrip.accessibilityLabel(name: "Rice", left: 65, paused: false) == "Rice timer, 1 minute 5 seconds left")
        #expect(CookingTimerStrip.accessibilityLabel(name: "Rice", left: 65, paused: true) == "Rice timer, 1 minute 5 seconds left, paused")
        #expect(CookingTimerStrip.accessibilityLabel(name: "Rice", left: 0, paused: false) == "Rice timer, done")
    }
}
