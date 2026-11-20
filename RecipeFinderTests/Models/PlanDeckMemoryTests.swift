import Testing
import Foundation
@testable import RecipeFinder

/// Plan — swipe to match slice 4: dishes passed on in "Plan my week" are remembered for 30 days, so the next deck
/// deals fresh dishes first; planning a dish forgets it; Reset clears it (an `rf.` key).
@Suite struct PlanDeckMemoryTests {

    private let cal: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
        return cal
    }()

    /// Wednesday 18 Nov 2026, noon UTC (mid-week, AGENT_LESSONS 15).
    private var now: Date {
        cal.date(from: DateComponents(year: 2026, month: 11, day: 18, hour: 12)) ?? Date()
    }

    private func daysAgo(_ days: Int) -> Date {
        cal.date(byAdding: .day, value: -days, to: now) ?? now
    }

    private let a = UUID()
    private let b = UUID()

    @Test func rememberedDishesCountAsRecentlyPassed() {
        var memory = PlanDeckMemory()
        memory.record(passed: [a], planned: [], at: now)
        #expect(memory.recentlyPassed(at: now, calendar: cal) == [a])
    }

    @Test(arguments: [(29, true), (30, false), (45, false)])
    func aPassLastsThirtyDays(age: Int, remembered: Bool) {
        let memory = PlanDeckMemory(passedOn: [a: daysAgo(age)])
        #expect(memory.recentlyPassed(at: now, calendar: cal).contains(a) == remembered)
    }

    @Test func aPassDatedInTheFutureIsForgotten() {
        // A clock set wrong once must not pin a dish to the back of the deck for good.
        let memory = PlanDeckMemory(passedOn: [a: cal.date(byAdding: .day, value: 2, to: now) ?? now])
        #expect(memory.recentlyPassed(at: now, calendar: cal).isEmpty)
    }

    @Test func passingAgainRestartsItsThirtyDays() {
        var memory = PlanDeckMemory(passedOn: [a: daysAgo(29)])
        memory.record(passed: [a], planned: [], at: now)
        #expect(memory.passedOn[a] == now)
    }

    @Test func aDishOnlyCarriedOverFromAnEarlierDeckKeepsItsDate() {
        // Only what the cook passed in this deck is recorded, so a dish passed once still expires after 30 days.
        var memory = PlanDeckMemory(passedOn: [a: daysAgo(10)])
        memory.record(passed: [b], planned: [], at: now)
        #expect(memory.passedOn[a] == daysAgo(10))
    }

    @Test func planningADishForgetsItsPass() {
        var memory = PlanDeckMemory(passedOn: [a: daysAgo(3)])
        memory.record(passed: [], planned: [a], at: now)
        #expect(memory.passedOn[a] == nil)
    }

    @Test func aDishPassedThenPlannedInTheSameDeckIsNotRemembered() {
        var memory = PlanDeckMemory()
        memory.record(passed: [a], planned: [a], at: now)
        #expect(memory.passedOn.isEmpty)
    }

    @Test func recordDropsExpiredEntries() {
        var memory = PlanDeckMemory(passedOn: [a: daysAgo(31)])
        memory.record(passed: [b], planned: [], at: now, calendar: cal)
        #expect(memory.passedOn.keys.sorted { $0.uuidString < $1.uuidString } == [b])
    }

    // MARK: - Stored on the device

    private func makeStorage() -> LocalStore {
        LocalStore(userDefaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
    }

    @Test func savedMemoryLoadsBack() {
        let storage = makeStorage()
        PlanDeckMemory(passedOn: [a: now]).save(to: storage)
        #expect(PlanDeckMemory.load(from: storage).passedOn == [a: now])
    }

    @Test func nothingSavedLoadsEmpty() {
        #expect(PlanDeckMemory.load(from: makeStorage()).passedOn.isEmpty)
    }

    @Test func resetClearsTheMemory() {
        let storage = makeStorage()
        PlanDeckMemory(passedOn: [a: now]).save(to: storage)
        storage.clearAll()
        #expect(PlanDeckMemory.load(from: storage).passedOn.isEmpty)
    }

    @Test func closingADeckRemembersItsPassesAndForgetsItsPicks() {
        let storage = makeStorage()
        PlanDeckMemory(passedOn: [b: daysAgo(5)]).save(to: storage)
        PlanDeckMemory.update(in: storage, passed: [a], planned: [b], at: now, calendar: cal)
        #expect(PlanDeckMemory.load(from: storage).passedOn == [a: now])
    }
}
