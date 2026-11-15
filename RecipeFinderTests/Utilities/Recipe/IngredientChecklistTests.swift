import Testing
@testable import RecipeFinder

@Suite("IngredientChecklist")
struct IngredientChecklistTests {

    private typealias Entry = IngredientChecklist.Entry

    @Test("Nothing ticked: every row in recipe order and no Got it group")
    func nothingTicked() {
        let entries = IngredientChecklist.entries(sections: [nil, nil, nil], ticked: [false, false, false])
        #expect(entries == [.row(index: 0, isTicked: false), .row(index: 1, isTicked: false),
                            .row(index: 2, isTicked: false)])
    }

    @Test("A ticked row moves under Got it at the bottom; the rest keep recipe order")
    func tickedRowMovesToGotIt() {
        let entries = IngredientChecklist.entries(sections: [nil, nil, nil], ticked: [true, false, false])
        #expect(entries == [.row(index: 1, isTicked: false), .row(index: 2, isTicked: false),
                            .gotItTitle(count: 1), .row(index: 0, isTicked: true)])
    }

    @Test("Got it keeps recipe order, not the order things were ticked")
    func gotItKeepsRecipeOrder() {
        let entries = IngredientChecklist.entries(sections: [nil, nil, nil], ticked: [false, true, true])
        #expect(entries == [.row(index: 0, isTicked: false), .gotItTitle(count: 2),
                            .row(index: 1, isTicked: true), .row(index: 2, isTicked: true)])
    }

    @Test("Unticking every row restores the original order")
    func untickRestoresPlace() {
        let sections: [String?] = [nil, nil, nil]
        #expect(IngredientChecklist.entries(sections: sections, ticked: [false, false, false])
                == IngredientChecklist.entries(sections: sections, ticked: []))
    }

    @Test("A group title stays above its first unticked row and goes once the whole group is ticked")
    func groupTitlesFollowUntickedRows() {
        let sections: [String?] = ["Sauce", "Sauce", "Pasta"]
        let firstTicked = IngredientChecklist.entries(sections: sections, ticked: [true, false, false])
        #expect(firstTicked == [.groupTitle("Sauce", groupStart: 0), .row(index: 1, isTicked: false),
                                .groupTitle("Pasta", groupStart: 2), .row(index: 2, isTicked: false),
                                .gotItTitle(count: 1), .row(index: 0, isTicked: true)])
        let sauceDone = IngredientChecklist.entries(sections: sections, ticked: [true, true, false])
        #expect(!sauceDone.contains(.groupTitle("Sauce", groupStart: 0)))
        #expect(sauceDone.first == .groupTitle("Pasta", groupStart: 2))
    }

    @Test("Two separate runs of the same group each get their own title")
    func repeatedGroupRuns() {
        let entries = IngredientChecklist.entries(sections: ["Sauce", nil, "Sauce"], ticked: [])
        #expect(entries == [.groupTitle("Sauce", groupStart: 0), .row(index: 0, isTicked: false),
                            .row(index: 1, isTicked: false),
                            .groupTitle("Sauce", groupStart: 2), .row(index: 2, isTicked: false)])
    }

    @Test("Every entry id is unique, and a row keeps its id when ticked, so SwiftUI animates the move")
    func idsAreUnique() {
        let entries = IngredientChecklist.entries(sections: ["A", "A", nil, "B"], ticked: [true, false, true, false])
        #expect(Set(entries.map(\.id)).count == entries.count)
        #expect(Entry.row(index: 3, isTicked: false).id == Entry.row(index: 3, isTicked: true).id)
    }

    @Test("A shorter tick array (the frame after an edit adds rows) reads missing ticks as not ticked")
    func shorterTicksAreSafe() {
        let entries = IngredientChecklist.entries(sections: [nil, nil, nil], ticked: [true])
        #expect(entries == [.row(index: 1, isTicked: false), .row(index: 2, isTicked: false),
                            .gotItTitle(count: 1), .row(index: 0, isTicked: true)])
    }

    @Test(arguments: [
        (3, [true, true, true], true),
        (3, [true, false, true], false),
        (3, [true, true], false),       // stale shorter state is not "all set"
        (0, [Bool](), false),           // a recipe with no ingredients never prompts
        (2, [true, true, false], true), // a longer stale array only counts the rows shown
    ])
    func allSet(count: Int, ticked: [Bool], expected: Bool) {
        #expect(IngredientChecklist.isAllSet(count: count, ticked: ticked) == expected)
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
