import XCTest

/// Critical-flow UI tests: each Recipes "+" entry point opens its expected sheet.
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
        // The app opens on Today; these flows start from the Recipes home.
        app.tabBars.buttons["Recipes"].tap()
        return app
    }

    // MARK: - Create manually (wizard)

    @MainActor
    func testCreateManuallyOpensWizard() {
        let app = launchApp()

        app.buttons["recipes.add"].tap()
        XCTAssertTrue(
            app.staticTexts["Add a Recipe"].waitForExistence(timeout: 5),
            "Recipes + should open the Add a Recipe sheet."
        )

        app.buttons["import.wizard"].tap()

        XCTAssertTrue(
            app.buttons["draft.name"].waitForExistence(timeout: 5),
            "Tapping 'Create manually' should open the new-recipe screen."
        )

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Import — Wizard open"
        shot.lifetime = .keepAlways
        add(shot)
    }

    // MARK: - Other apps

    @MainActor
    func testOtherAppsOpensImportScreen() {
        let app = launchApp()

        app.buttons["recipes.add"].tap()
        app.buttons["import.otherApp"].tap()

        XCTAssertTrue(
            app.buttons["settings.importOtherApp"].waitForExistence(timeout: 5),
            "Bring recipes from another app should open the export-file import."
        )
    }

    // MARK: - Paste text

    @MainActor
    func testPasteTextOpensSheet() {
        let app = launchApp()

        app.buttons["recipes.add"].tap()
        XCTAssertTrue(
            app.staticTexts["Add a Recipe"].waitForExistence(timeout: 5),
            "Recipes + should open the Add a Recipe sheet."
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
