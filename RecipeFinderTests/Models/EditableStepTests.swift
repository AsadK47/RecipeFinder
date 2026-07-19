import XCTest
@testable import RecipeFinder

final class EditableStepTests: XCTestCase {

    // MARK: - Identity (regression guard for the wizard crash)

    /// The wizard crash came from rows identified by array offset: two blank
    /// steps were indistinguishable, so adding/removing rows left TextField
    /// bindings pointing at dead indices. Identical texts must still have
    /// distinct identities.
    func testIdenticalTextsHaveDistinctIdentities() {
        let steps: [EditableStep] = .steps(from: ["", "", ""])
        XCTAssertEqual(Set(steps.map(\.id)).count, 3)
    }

    func testRemovingByIdOnlyRemovesThatStep() {
        var steps: [EditableStep] = .steps(from: ["one", "two", "three"])
        let removed = steps[1]

        steps.removeAll { $0.id == removed.id }

        XCTAssertEqual(steps.map(\.text), ["one", "three"])
    }

    // MARK: - steps(from:)

    func testStepsFromEmptyListProvidesOneBlankRow() {
        let steps: [EditableStep] = .steps(from: [])
        XCTAssertEqual(steps.count, 1)
        XCTAssertEqual(steps[0].text, "")
    }

    func testStepsFromTextsPreservesOrderAndContent() {
        let steps: [EditableStep] = .steps(from: ["Chop onions", "Boil water"])
        XCTAssertEqual(steps.map(\.text), ["Chop onions", "Boil water"])
    }

    // MARK: - nonEmptyTexts

    func testNonEmptyTextsTrimsAndDropsBlankRows() {
        let steps: [EditableStep] = .steps(from: ["  Chop onions  ", "", "   ", "Boil water"])
        XCTAssertEqual(steps.nonEmptyTexts, ["Chop onions", "Boil water"])
    }

    func testRoundTripPreservesRealSteps() {
        let original = ["Marinate the chicken", "Preheat the oven"]
        let steps: [EditableStep] = .steps(from: original)
        XCTAssertEqual(steps.nonEmptyTexts, original)
    }
}
