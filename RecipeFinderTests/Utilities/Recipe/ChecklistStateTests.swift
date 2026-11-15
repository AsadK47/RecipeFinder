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

    private func salt(_ quantity: Double) -> Ingredient { Ingredient(baseQuantity: quantity, unit: "tsp", name: "salt") }
    private let flour = Ingredient(baseQuantity: 200, unit: "g", name: "flour")

    @Test("Editing a ticked ingredient's amount keeps its tick")
    func amountEditKeepsTick() {
        #expect(ChecklistState.remap([true, false], from: [salt(1), flour], to: [salt(2), flour]) == [true, false])
    }

    @Test("An edited amount doesn't steal the tick of an exact match")
    func exactMatchesWinFirst() {
        // Two salt lines, only the 1 tsp one ticked; the 2 tsp line is edited to 3 tsp and must stay unticked.
        let state = ChecklistState.remap([true, false], from: [salt(1), salt(2)], to: [salt(3), salt(1)])
        #expect(state == [false, true])
    }

    @Test("A renamed ingredient starts unticked")
    func renameDropsTick() {
        let pepper = Ingredient(baseQuantity: 1, unit: "tsp", name: "pepper")
        #expect(ChecklistState.remap([true], from: [salt(1)], to: [pepper]) == [false])
    }
}
