import Testing
@testable import RecipeFinder

@Suite("CookingPlan")
struct CookingPlanTests {

    private func plan(prePrep: [String] = [], steps: [String] = []) -> CookingPlan {
        CookingPlan(prePrep: prePrep, steps: steps)
    }

    // MARK: - Composition

    @Test("Items are ingredient list, then pre-prep, then steps, in order")
    func composition() {
        let p = plan(prePrep: ["Soak rice"], steps: ["Boil", "Simmer"])
        #expect(p.count == 4)  // ingredientList + 1 pre-prep + 2 steps
        #expect(p.items[0].isIngredientList)
        #expect(p.items[1] == .prePrep(index: 0, text: "Soak rice"))
        #expect(p.items[2] == .step(index: 0, text: "Boil"))
        #expect(p.items[3] == .step(index: 1, text: "Simmer"))
    }

    @Test("A recipe with no pre-prep still leads with the ingredient list")
    func noPrePrep() {
        let p = plan(steps: ["Mix", "Bake"])
        #expect(p.count == 3)
        #expect(p.items[0].isIngredientList)
        #expect(p.items[1] == .step(index: 0, text: "Mix"))
    }

    // MARK: - First / last

    @Test func firstAndLast() {
        let p = plan(steps: ["A", "B"])  // indices 0,1,2
        #expect(p.isFirst(0))
        #expect(!p.isFirst(1))
        #expect(p.isLast(2))
        #expect(!p.isLast(1))
    }

    // MARK: - Progress (the off-by-one surface)

    @Test("Progress treats the current item as done: index 0 of N → 1/N, last → 1.0")
    func progress() {
        let p = plan(steps: ["A", "B", "C"])  // count 4
        #expect(abs(p.progress(0) - 0.25) < 0.0001)
        #expect(abs(p.progress(3) - 1.0) < 0.0001)
    }

    // MARK: - Phase label + position ("Step N of M")

    @Test("Ingredient list has no phase label")
    func ingredientListLabel() {
        let p = plan(prePrep: ["x"], steps: ["y"])
        #expect(p.phaseLabel(at: 0).label == "")
        #expect(p.positionInPhase(at: 0) == 0)
    }

    @Test("Pre-prep and steps number from 1 within their own section")
    func phaseNumbering() {
        let p = plan(prePrep: ["p1", "p2"], steps: ["s1", "s2", "s3"])
        // index 1,2 = pre-prep 1,2 of 2
        #expect(p.phaseLabel(at: 1) == ("Pre-Prep", 2))
        #expect(p.positionInPhase(at: 1) == 1)
        #expect(p.positionInPhase(at: 2) == 2)
        // index 3,4,5 = step 1,2,3 of 3  (numbering resets per section, not continued from pre-prep)
        #expect(p.phaseLabel(at: 3) == ("Step", 3))
        #expect(p.positionInPhase(at: 3) == 1)
        #expect(p.positionInPhase(at: 5) == 3)
    }

    @Test("Out-of-range index is handled gracefully")
    func outOfRange() {
        let p = plan(steps: ["only"])
        #expect(p.phaseLabel(at: 99) == ("", 0))
        #expect(p.positionInPhase(at: 99) == 0)
    }
}
