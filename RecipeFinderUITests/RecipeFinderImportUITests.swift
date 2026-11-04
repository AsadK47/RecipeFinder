import XCTest

/// Critical-flow UI tests: each Import tab entry point opens its expected sheet.
final class RecipeFinderImportUITests: XCTestCase {

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

    // MARK: - Create manually (wizard)

    @MainActor
    func testCreateManuallyOpensWizard() {
        let app = launchApp()

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
        let app = launchApp()

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
