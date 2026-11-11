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

    // MARK: - New recipe photo

    /// Tapping the photo on a new recipe goes straight to the camera/library choice — not the name editor again.
    @MainActor
    func testDraftPhotoOpensPhotoChoiceNotNameEditor() {
        let app = launchApp()

        app.buttons["recipes.add"].tap()
        app.buttons["import.wizard"].tap()
        let photo = app.buttons["draft.photo"]
        XCTAssertTrue(photo.waitForExistence(timeout: 5), "Start blank should open the new-recipe screen.")
        photo.tap()

        XCTAssertTrue(app.staticTexts["Add Photo"].waitForExistence(timeout: 5),
                      "The photo should offer Take Photo / Choose from Library straight away.")
        XCTAssertFalse(app.descendants(matching: .any)["wizard.recipeName"].exists,
                       "The photo must not reopen the recipe-name editor.")
    }

    // MARK: - Paste box

    /// Add flow 2/3: recipe text typed into the "+" sheet's box goes straight to the text reader — no second paste.
    @MainActor
    func testPastedTextGoesStraightToReview() {
        let app = launchApp()

        app.buttons["recipes.add"].tap()
        XCTAssertTrue(
            app.staticTexts["Add a Recipe"].waitForExistence(timeout: 5),
            "Recipes + should open the Add a Recipe sheet."
        )

        // A multi-line SwiftUI TextField surfaces as a text view or a text field depending on the OS.
        let box = app.descendants(matching: .any).matching(identifier: "add.input").firstMatch
        XCTAssertTrue(box.waitForExistence(timeout: 5), "The Add a Recipe sheet should lead with the paste box.")
        box.tap()
        box.typeText("Pancakes\nIngredients\n200 g flour\n2 eggs\nMethod\nWhisk and fry.")
        app.buttons["add.continue"].tap()

        // The text is read straight away: either the recipe screen or (if nothing was found) the paste sheet's fallback.
        let reviewed = NSPredicate { _, _ in
            app.buttons["draft.name"].exists || app.buttons["import.startFromText"].exists
        }
        let wait = XCTNSPredicateExpectation(predicate: reviewed, object: nil)
        XCTAssertEqual(XCTWaiter().wait(for: [wait], timeout: 15), .completed,
                       "Continue should read the pasted text without asking for it again.")

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Import — Pasted text reviewed"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
