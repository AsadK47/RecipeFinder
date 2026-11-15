import Testing
@testable import RecipeFinder

@Suite("IngredientChecklist")
struct IngredientChecklistTests {

    private typealias Entry = IngredientChecklist.Entry

    /// Layout with every tick already settled into place.
    private func settled(_ sections: [String?], _ ticked: [Bool]) -> [Entry] {
        IngredientChecklist.entries(sections: sections, ticked: ticked, inGotIt: ticked)
    }

    @Test("Nothing ticked: every row in recipe order and no Got it group")
    func nothingTicked() {
        #expect(settled([nil, nil, nil], [false, false, false])
                == [.row(index: 0, isTicked: false), .row(index: 1, isTicked: false), .row(index: 2, isTicked: false)])
    }

    @Test("A settled tick sits under Got it at the bottom; the rest keep recipe order")
    func tickedRowMovesToGotIt() {
        #expect(settled([nil, nil, nil], [true, false, false])
                == [.row(index: 1, isTicked: false), .row(index: 2, isTicked: false),
                    .gotItTitle(count: 1), .row(index: 0, isTicked: true)])
    }

    @Test("A fresh tick shows in place (filled circle) until it settles")
    func freshTickStaysInPlace() {
        let entries = IngredientChecklist.entries(sections: [nil, nil], ticked: [true, false], inGotIt: [false, false])
        #expect(entries == [.row(index: 0, isTicked: true), .row(index: 1, isTicked: false)])
    }

    @Test("Got it keeps recipe order, not the order things were ticked")
    func gotItKeepsRecipeOrder() {
        #expect(settled([nil, nil, nil], [false, true, true])
                == [.row(index: 0, isTicked: false), .gotItTitle(count: 2),
                    .row(index: 1, isTicked: true), .row(index: 2, isTicked: true)])
    }

    @Test("A group title stays above its first row still to get and goes once the whole group is in Got it")
    func groupTitlesFollowUntickedRows() {
        let sections: [String?] = ["Sauce", "Sauce", "Pasta"]
        #expect(settled(sections, [true, false, false])
                == [.groupTitle("Sauce", groupStart: 0), .row(index: 1, isTicked: false),
                    .groupTitle("Pasta", groupStart: 2), .row(index: 2, isTicked: false),
                    .gotItTitle(count: 1), .row(index: 0, isTicked: true)])
        let sauceDone = settled(sections, [true, true, false])
        #expect(!sauceDone.contains(.groupTitle("Sauce", groupStart: 0)))
        #expect(sauceDone.first == .groupTitle("Pasta", groupStart: 2))
    }

    @Test("Two separate runs of the same group each get their own title")
    func repeatedGroupRuns() {
        #expect(settled(["Sauce", nil, "Sauce"], [false, false, false])
                == [.groupTitle("Sauce", groupStart: 0), .row(index: 0, isTicked: false),
                    .row(index: 1, isTicked: false),
                    .groupTitle("Sauce", groupStart: 2), .row(index: 2, isTicked: false)])
    }

    @Test("Every entry id is unique, and a row keeps its id when ticked, so SwiftUI animates the move")
    func idsAreUnique() {
        let entries = settled(["A", "A", nil, "B"], [true, false, true, false])
        #expect(Set(entries.map(\.id)).count == entries.count)
        #expect(Entry.row(index: 3, isTicked: false).id == Entry.row(index: 3, isTicked: true).id)
    }

    @Test("All settled into Got it: the start-cooking prompt sits where the rows were, above Got it")
    func allSetPromptAboveGotIt() {
        #expect(settled([nil, nil], [true, true])
                == [.allSetPrompt, .gotItTitle(count: 2), .row(index: 0, isTicked: true), .row(index: 1, isTicked: true)])
    }

    @Test("No prompt while the last tick is still settling, or while a row is still to get")
    func noPromptUntilSettled() {
        let settling = IngredientChecklist.entries(sections: [nil, nil], ticked: [true, true], inGotIt: [true, false])
        #expect(!settling.contains(.allSetPrompt))
        #expect(!settled([nil, nil], [true, false]).contains(.allSetPrompt))
    }

    @Test("A state array that doesn't fit the rows (the frame after an edit) shows nothing ticked, never wrong ticks",
          arguments: [[true], [true, true, true, true]])
    func mismatchedTicksReadAsNone(ticked: [Bool]) {
        let entries = IngredientChecklist.entries(sections: [nil, nil, nil], ticked: ticked, inGotIt: ticked)
        #expect(entries == [.row(index: 0, isTicked: false), .row(index: 1, isTicked: false),
                            .row(index: 2, isTicked: false)])
    }

    @Test(arguments: [
        (3, [true, true, true], true),
        (3, [true, false, true], false),
        (3, [true, true], false),            // stale shorter state is not "all set"
        (0, [Bool](), false),                // a recipe with no ingredients never prompts
        (2, [true, true, true], false),      // nor a stale longer one
    ])
    func allSet(count: Int, ticked: [Bool], expected: Bool) {
        #expect(IngredientChecklist.isAllSet(count: count, ticked: ticked) == expected)
    }

    @Test("VoiceOver moves on to the next row still to get, below first and then wrapping to the top")
    func nextRowToGet() {
        let entries = settled(["A", "A", nil, nil], [false, false, false, true])
        #expect(IngredientChecklist.nextRowToGet(after: 1, in: entries) == 2)
        #expect(IngredientChecklist.nextRowToGet(after: 2, in: entries) == 0)
        let lastOne = settled([nil, nil], [true, false])
        #expect(IngredientChecklist.nextRowToGet(after: 1, in: lastOne) == nil)
    }

    @Test("The first circle pulses until the cook has ticked a row once")
    func pulseUntilFirstTick() {
        #expect(IngredientChecklist.pulseIndex(count: 4, hasTickedBefore: false, timesPulsed: 0) == 0)
        #expect(IngredientChecklist.pulseIndex(count: 4, hasTickedBefore: true, timesPulsed: 0) == nil)
        #expect(IngredientChecklist.pulseIndex(count: 0, hasTickedBefore: false, timesPulsed: 0) == nil)
    }

    @Test("The pulse stops after a few visits for a cook who never ticks")
    func pulseStopsAfterAFewVisits() {
        let last = IngredientChecklist.maxPulses - 1
        #expect(IngredientChecklist.pulseIndex(count: 4, hasTickedBefore: false, timesPulsed: last) == 0)
        #expect(IngredientChecklist.pulseIndex(count: 4, hasTickedBefore: false,
                                                timesPulsed: IngredientChecklist.maxPulses) == nil)
    }
}

@Suite("IngredientTicks")
struct IngredientTicksTests {

    private let start = ContinuousClock.now
    private let delay = IngredientTicks.settleDelay

    @Test("A tap ticks in place at once; the row moves into Got it only after the wait")
    func tickSettlesAfterDelay() {
        var ticks = IngredientTicks(count: 3)
        ticks.toggle(0, at: start)
        #expect(ticks.ticked == [true, false, false])
        #expect(ticks.inGotIt == [false, false, false])
        ticks.settleIfDue(at: start + delay - .milliseconds(1))
        #expect(ticks.inGotIt == [false, false, false])
        ticks.settleIfDue(at: start + delay)
        #expect(ticks.inGotIt == [true, false, false])
        #expect(ticks.settleDeadline == nil)
    }

    @Test("Each tap restarts the wait, so quick taps all move together once tapping stops")
    func tapRestartsWait() {
        var ticks = IngredientTicks(count: 3)
        ticks.toggle(0, at: start)
        let secondTap = start + .milliseconds(800)
        ticks.toggle(1, at: secondTap)
        ticks.settleIfDue(at: start + delay)  // the first tap's wait has passed, but not the second's
        #expect(ticks.inGotIt == [false, false, false])
        ticks.settleIfDue(at: secondTap + delay)
        #expect(ticks.inGotIt == [true, true, false])
    }

    @Test("Unticking a row in Got it shows its empty circle there, then moves it back after the wait")
    func untickSettlesBack() {
        var ticks = IngredientTicks(count: 2)
        ticks.toggle(0, at: start)
        ticks.settleIfDue(at: start + delay)
        let later = start + .seconds(5)
        ticks.toggle(0, at: later)
        #expect(ticks.ticked == [false, false])
        #expect(ticks.inGotIt == [true, false])
        ticks.settleIfDue(at: later + delay)
        #expect(ticks.inGotIt == [false, false])
    }

    @Test("Out-of-range taps change nothing")
    func outOfRangeTapIgnored() {
        var ticks = IngredientTicks(count: 1)
        ticks.toggle(3, at: start)
        #expect(ticks == IngredientTicks(count: 1))
    }

    @Test("All set only once every row is ticked")
    func allSet() {
        var ticks = IngredientTicks(count: 2)
        ticks.toggle(0, at: start)
        #expect(!ticks.isAllSet)
        ticks.toggle(1, at: start)
        #expect(ticks.isAllSet)
    }

    @Test("A recipe edit carries ticks to their ingredients and settles at once")
    func remapSettles() {
        let flour = Ingredient(baseQuantity: 200, unit: "g", name: "flour")
        let butter = Ingredient(baseQuantity: 50, unit: "g", name: "butter")
        var ticks = IngredientTicks(count: 2)
        ticks.toggle(1, at: start)
        ticks.remap(from: [flour, butter], to: [butter, flour])
        #expect(ticks.ticked == [true, false])
        #expect(ticks.inGotIt == [true, false])
        #expect(ticks.settleDeadline == nil)
    }
}
