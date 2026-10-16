import XCTest

/// Regression guards for two bug classes fixed together:
///  • data-carrying sheets must open at the correct content on *first* present (`.sheet(item:)`), not a stale
///    full form — proven here via the recipe-detail cook-time editor opening focused on "Details".
///  • signing out must reset user scope — the previous account's name must not linger and browsing must still
///    show recipes (guest seeds reloaded), not a blank list.
/// These drive the real app because the underlying defects are SwiftUI presentation/lifecycle timing that unit
/// tests structurally can't exercise.
final class RecipeFinderSheetAndScopeUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Launches signed-in (as the "Test User" account) and waits for the main tab bar.
    @MainActor
    private func launchAuthenticated() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-skip-auth"]
        app.launch()
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 10)
        let nudge = app.buttons["guest.nudge.cta"]
        if nudge.exists {
            wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: nudge)], timeout: 10)
        }
        return app
    }

    /// Matches an element by accessibility identifier regardless of its element type.
    @MainActor
    private func element(_ app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// Taps once the element exists and settles. On a cold boot the first recipe row can be on-screen but
    /// momentarily report non-hittable (async image/layout settle); wait for hittability, then fall back to a
    /// coordinate tap. Not masking — a wrong tap (e.g. a real overlay) still fails the later assertions.
    @MainActor
    private func tapWhenReady(_ element: XCUIElement, _ message: String, timeout: TimeInterval = 10) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), message)
        if !element.isHittable {
            _ = XCTWaiter().wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "isHittable == true"), object: element)], timeout: timeout)
        }
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    /// Bug class A: the FIRST tap of the cook-time card must open the editor focused on "Details", not the full
    /// unfocused "Edit Recipe" form. The old `.sheet(isPresented:)` + separate state rendered the full editor on
    /// first present; `.sheet(item:)` fixes it. This is the exact user-reported symptom.
    @MainActor
    func testCookTimeEditorOpensFocusedOnFirstPresent() {
        let app = launchAuthenticated()

        tapWhenReady(element(app, id: "recipe.row"), "Recipes home should list at least one recipe.")

        let timeCard = element(app, id: "recipe.card.time")
        XCTAssertTrue(timeCard.waitForExistence(timeout: 10), "Recipe detail should show the editable time card.")
        timeCard.tap()

        XCTAssertTrue(app.navigationBars["Details"].waitForExistence(timeout: 5),
                      "First tap of cook time should open the editor focused on Details.")
        XCTAssertFalse(app.navigationBars["Edit Recipe"].exists,
                       "First present must not show the full unfocused editor (the stale-first-render bug).")

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Cook-time editor — focused Details on first open"
        shot.lifetime = .keepAlways
        add(shot)
    }

    // Bug class B (sign-out scope reset) is NOT covered here: the guest-only build (AuthUIGate.showAuthUI == false)
    // routes a signed-out session to the auth screen, so the guest→browse-again path can't be reproduced via the
    // `-skip-auth` harness. Its core logic — guest seed reload on an empty library — is unit-tested in
    // RecipeStoreTests.guestLoadSeedsWhenEmpty.
}
