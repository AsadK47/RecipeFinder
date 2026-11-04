import Testing
@testable import RecipeFinder

@Suite("ChecklistState")
struct ChecklistStateTests {

    @Test("Ticks follow their item when an earlier item is removed and a new one added")
    func ticksFollowItems() {
        // Regression: ticks were kept by row position, so removing row 1 moved them onto the wrong items.
        let old = ["chicken", "yogurt", "salt", "butter"]
        let new = ["yogurt", "salt", "butter", "lemon"]
        let state = ChecklistState.remap([true, false, false, true], from: old, to: new)
        #expect(state == [false, false, true, false])
    }

    @Test("Unchanged items keep their ticks exactly")
    func unchangedKeepsState() {
        let items = ["a", "b", "c"]
        #expect(ChecklistState.remap([true, false, true], from: items, to: items) == [true, false, true])
    }

    @Test("Duplicate lines keep their own tick counts")
    func duplicatesMatchedInOrder() {
        let state = ChecklistState.remap([true, false], from: ["stir", "stir"], to: ["stir", "stir", "serve"])
        #expect(state == [true, false, false])
    }

    @Test("A stale, shorter state array never traps")
    func staleStateIsSafe() {
        #expect(ChecklistState.remap([true], from: ["a", "b"], to: ["a", "b", "c"]) == [true, false, false])
        #expect(ChecklistState.remap([], from: ["a"], to: ["a"]) == [false])
    }
}
