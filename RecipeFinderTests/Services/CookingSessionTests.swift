import Testing
@testable import RecipeFinder

@MainActor
@Suite("CookingSession")
struct CookingSessionTests {

    @Test("inactive and empty before start")
    func inactiveByDefault() {
        let session = CookingSession()
        #expect(!session.isActive)
        #expect(session.currentIndex == 0)
        #expect(session.currentStepText == nil)
        #expect(session.stepCount == 0)
    }

    @Test("start sets recipe name, items, and resets to first step")
    func startSetsState() {
        let session = CookingSession()
        session.start(recipeName: "Pasta", items: ["Boil water", "Add pasta", "Drain"])
        #expect(session.isActive)
        #expect(session.recipeName == "Pasta")
        #expect(session.currentIndex == 0)
        #expect(session.currentStepText == "Boil water")
        #expect(session.stepCount == 3)
    }

    @Test("start resets index when called on an already-active session")
    func startResetsIndex() {
        let session = CookingSession()
        session.start(recipeName: "Pasta", items: ["A", "B"])
        session.advance()
        session.start(recipeName: "Pasta", items: ["A", "B"])
        #expect(session.currentIndex == 0)
    }

    @Test("advance moves to next step")
    func advanceMovesForward() {
        let session = CookingSession()
        session.start(recipeName: "Pasta", items: ["Step 1", "Step 2", "Step 3"])
        session.advance()
        #expect(session.currentIndex == 1)
        #expect(session.currentStepText == "Step 2")
    }

    @Test("advance is clamped at the last step")
    func advanceClampedAtEnd() {
        let session = CookingSession()
        session.start(recipeName: "Pasta", items: ["Only step"])
        session.advance()
        #expect(session.currentIndex == 0)
    }

    @Test("retreat moves to previous step")
    func retreatMovesBack() {
        let session = CookingSession()
        session.start(recipeName: "Pasta", items: ["Step 1", "Step 2"])
        session.advance()
        session.retreat()
        #expect(session.currentIndex == 0)
        #expect(session.currentStepText == "Step 1")
    }

    @Test("retreat is clamped at the first step")
    func retreatClampedAtStart() {
        let session = CookingSession()
        session.start(recipeName: "Pasta", items: ["Only step"])
        session.retreat()
        #expect(session.currentIndex == 0)
    }

    @Test("setIndex moves to the given position")
    func setIndexMovesToPosition() {
        let session = CookingSession()
        session.start(recipeName: "Pasta", items: ["A", "B", "C"])
        session.setIndex(2)
        #expect(session.currentIndex == 2)
        #expect(session.currentStepText == "C")
    }

    @Test("setIndex ignores out-of-range values")
    func setIndexClampsOutOfRange() {
        let session = CookingSession()
        session.start(recipeName: "Pasta", items: ["A"])
        session.setIndex(99)
        #expect(session.currentIndex == 0)
        session.setIndex(-1)
        #expect(session.currentIndex == 0)
    }

    @Test("end clears all state")
    func endClearsState() {
        let session = CookingSession()
        session.start(recipeName: "Pasta", items: ["Step 1"])
        session.advance()
        session.end()
        #expect(!session.isActive)
        #expect(session.recipeName == nil)
        #expect(session.currentIndex == 0)
        #expect(session.currentStepText == nil)
        #expect(session.stepCount == 0)
    }
}
