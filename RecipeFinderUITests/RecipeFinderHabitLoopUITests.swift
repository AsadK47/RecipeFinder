import XCTest

/// Core habit-loop UI smoke test — drives the real app to prove the wired screens, not just the
/// engines: cooking a recipe surfaces the rating and the header streak chip, and the dead import
/// "example links" are gone. Asserts post-cook *deltas* so it holds regardless of prior library state.
final class RecipeFinderHabitLoopUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 10)
        return app
    }

    /// Matches an element by accessibility identifier regardless of its element type.
    @MainActor
    private func element(_ app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// Taps once the element exists and settles. On a cold boot the first recipe row can be on-screen but
    /// momentarily report non-hittable (async image/layout settle); wait for hittability, then fall back to a
    /// coordinate tap. Not masking — a wrong tap still fails the later assertions.
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

    /// Swipes the page up until `element` sits fully inside the visible window (clear of the tab bar).
    @MainActor
    private func scrollIntoView(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 10) {
        let window = app.windows.firstMatch.frame
        let visible = CGRect(x: 0, y: window.minY + 120, width: window.width, height: window.height - 240)
        let scrollView = app.scrollViews.firstMatch
        for _ in 0..<maxSwipes {
            let frame = element.frame
            if visible.contains(frame) { return }
            // Overshot (element above the visible band) → scroll back down; otherwise keep scrolling up.
            if frame.minY < visible.minY {
                scrollView.swipeDown(velocity: .slow)
            } else {
                scrollView.swipeUp(velocity: .slow)
            }
        }
    }

    @MainActor
    func testCookingShowsRatingAndStreakChip() {
        let app = launchApp()

        // Open the first recipe in the library (starter seeds in a clean install, or the user's own recipes).
        tapWhenReady(element(app, id: "recipe.row"), "The Recipes home should list at least one recipe.")

        let markCooked = app.buttons["recipe.markCooked"]
        XCTAssertTrue(markCooked.waitForExistence(timeout: 10), "Recipe detail should show the mark-cooked button.")

        // Cook it — unless an earlier run (state isn't reset) already logged a cook today, which disables the button.
        if markCooked.isEnabled {
            // The button sits ~1,800pt down a ~3,100pt detail page, and XCUITest's automatic
            // scroll-to-visible doesn't work in this SwiftUI ScrollView (hit point {-1,-1}), so scroll it
            // into view ourselves before tapping.
            scrollIntoView(markCooked, in: app)
            XCTAssertTrue(markCooked.isHittable, "Mark as Cooked should be on screen after scrolling.")
            markCooked.tap()

            // A post-cook photo sheet auto-presents ~0.8s later — dismiss it.
            let skip = app.buttons["Skip"]
            if skip.waitForExistence(timeout: 4) {
                skip.tap()
            }
        }
        XCTAssertFalse(markCooked.isEnabled, "After a cook today, 'Mark as Cooked' must be disabled (no double count).")

        // Durable post-conditions: the rating control is now shown on the detail…
        XCTAssertTrue(element(app, id: "recipe.rating").waitForExistence(timeout: 5),
                      "Rating should appear after the recipe has been cooked.")

        // …and the weekly-streak chip now shows in the Recipes header (a cook this week ⇒ streak ≥ 1).
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(element(app, id: "streak.chip").waitForExistence(timeout: 5),
                      "Streak chip should appear in the header after cooking.")

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Recipes home — streak chip after cooking"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testImportScreenHasNoExampleLinks() {
        let app = launchApp()

        app.tabBars.buttons["Import"].tap()
        XCTAssertTrue(app.staticTexts["Import a Recipe"].waitForExistence(timeout: 5),
                      "Import tab should be visible.")
        XCTAssertFalse(app.staticTexts["Try these examples:"].exists,
                       "The dead example links should no longer ship.")
    }
}
