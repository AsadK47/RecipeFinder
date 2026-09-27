import XCTest

/// Critical-flow UI tests: each Import tab entry point opens its expected sheet.
/// Uses the `-skip-auth` hook to land directly on the main app.
final class RecipeFinderImportUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    private func launchAuthenticated() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-skip-auth"]
        app.launch()
        // autoSignIn() is async; wait for the guest nudge to vanish (isAuthenticated == true) before tapping.
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 10)
        let nudge = app.buttons["guest.nudge.cta"]
        if nudge.exists {
            let gone = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: nudge
            )
            wait(for: [gone], timeout: 10)
        }
        return app
    }

    // MARK: - Create manually (wizard)

    @MainActor
    func testCreateManuallyOpensWizard() {
        let app = launchAuthenticated()

        app.tabBars.buttons["Import"].tap()
        XCTAssertTrue(
            app.staticTexts["Import a Recipe"].waitForExistence(timeout: 5),
            "Import tab should be visible."
        )

        app.buttons["import.wizard"].tap()

        XCTAssertTrue(
            app.staticTexts["Let's start with a name"].waitForExistence(timeout: 5),
            "Tapping 'Create manually' should open the recipe wizard."
        )

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Import — Wizard open"
        shot.lifetime = .keepAlways
        add(shot)
    }

    // MARK: - Paste text

    @MainActor
    func testPasteTextOpensSheet() {
        let app = launchAuthenticated()

        app.tabBars.buttons["Import"].tap()
        XCTAssertTrue(
            app.staticTexts["Import a Recipe"].waitForExistence(timeout: 5),
            "Import tab should be visible."
        )

        app.buttons["import.paste"].tap()

        XCTAssertTrue(
            app.staticTexts["Paste Text"].waitForExistence(timeout: 5),
            "Tapping 'Paste text' should open the paste text sheet."
        )

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Import — Paste text sheet"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
