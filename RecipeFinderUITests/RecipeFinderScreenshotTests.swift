import XCTest

/// Captures marketing screenshots of the key screens with the bundled sample recipes.
/// Run by the "Screenshots" GitHub workflow, which sets `SCREENSHOT_DIR` (via `TEST_RUNNER_SCREENSHOT_DIR`)
/// so each shot is also written to disk as `<name>.png`. Every shot is attached to the test result too.
/// Not a correctness test: a screen that can't be reached is skipped, not failed.
final class RecipeFinderScreenshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    @MainActor
    func testCaptureScreenshots() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        let tabs = app.tabBars.firstMatch
        XCTAssertTrue(tabs.waitForExistence(timeout: 15), "App should reach the main tabs.")
        settle()

        // 1. Recipe library
        snap(app, "01-recipes")

        // 2. A recipe
        let row = app.descendants(matching: .any).matching(identifier: "recipe.row").firstMatch
        if row.waitForExistence(timeout: 10) {
            row.tap()
            settle()
            snap(app, "02-recipe")

            // Fill the shopping list from this recipe so the Groceries shot isn't empty.
            let addAll = app.buttons["Add all ingredients to groceries"]
            if addAll.waitForExistence(timeout: 5) {
                addAll.tap()
                settle()
                snap(app, "07-add-to-groceries")
                // The sheet pre-ticks every ingredient; confirm adds them all.
                let confirm = app.buttons["shop.confirm"]
                if confirm.waitForExistence(timeout: 5) {
                    confirm.tap()
                    settle()
                }
            }
            app.navigationBars.buttons.element(boundBy: 0).tap()
            settle()
        }

        // 3–5. Other tabs
        tab(app, "Groceries", shot: "03-groceries")
        tab(app, "Planning", shot: "04-meal-plan")
        tab(app, "Import", shot: "05-import")

        // 6. Cooking mode — last, so there's no need to find its close button.
        tab(app, "Recipes", shot: nil)
        if row.waitForExistence(timeout: 5) {
            row.tap()
            settle()
            let cook = app.buttons["Start Cooking Mode"]
            if cook.waitForExistence(timeout: 5) {
                cook.tap()
                settle(2)
                snap(app, "06-cooking-mode")
            }
        }
    }

    // MARK: - Helpers

    @MainActor
    private func tab(_ app: XCUIApplication, _ name: String, shot: String?) {
        let button = app.tabBars.buttons[name]
        guard button.waitForExistence(timeout: 5) else { return }
        button.tap()
        settle()
        if let shot { snap(app, shot) }
    }

    /// Lets images load and any toast fade before the shot.
    private func settle(_ seconds: TimeInterval = 1.5) {
        _ = XCTWaiter().wait(for: [XCTestExpectation(description: "settle")], timeout: seconds)
    }

    @MainActor
    private func snap(_ app: XCUIApplication, _ name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"], !dir.isEmpty {
            let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).png")
            try? screenshot.pngRepresentation.write(to: url)
        }
    }
}
