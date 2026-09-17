import XCTest

/// Critical-flow UI tests for the Import tab.
///
/// Uses the `-skip-auth` hook (see `RecipeFinderApp.init`) to land directly on
/// the main app as a guest — no sign-in ceremony needed. Verifies that each
/// import entry point opens the expected sheet.
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
        // autoSignIn() fires asynchronously; wait for it to settle so the app
        // is fully authenticated (isGuest = false) before tests tap action elements.
        // The nudge button disappears once authManager.isAuthenticated becomes true.
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

        // RecipeWizardView step 1 shows "Let's start with a name".
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

        // PasteTextImportSheet has navigation title "Paste Text".
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
