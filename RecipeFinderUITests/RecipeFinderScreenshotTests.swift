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
            let addAll = app.buttons["Add all ingredients to groceries"].firstMatch
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

    /// "Re-import from original" lives in the detail ⋯ menu and only shows for recipes that kept their import text,
    /// so this run seeds one (`-seed-reimport-recipe`, sorts first) and captures the open menu.
    @MainActor
    func testCaptureReimportMenu() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-seed-reimport-recipe"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        settle()

        let row = app.descendants(matching: .any).matching(identifier: "recipe.row").firstMatch
        guard row.waitForExistence(timeout: 10) else { return }
        row.tap()
        settle()
        let more = app.buttons["More actions"].firstMatch
        guard more.waitForExistence(timeout: 5) else { return }
        more.tap()
        settle(1)
        XCTAssertTrue(app.buttons["recipe.reimport"].waitForExistence(timeout: 5),
                      "A recipe with its original text should offer Re-import from original.")
        snap(app, "08-reimport-menu")
    }

    /// Import 2/5: the review screen's "We couldn't read this one well" banner and section highlights, opened on a
    /// deliberately poor import via the DEBUG `-show-low-confidence-import` flag (the paste path may use on-device AI).
    @MainActor
    func testCaptureLowConfidenceImport() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-show-low-confidence-import"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        let importTab = app.tabBars.buttons["Import"]
        guard importTab.waitForExistence(timeout: 5) else { return }
        importTab.tap()
        settle(2)
        XCTAssertTrue(app.descendants(matching: .any)["import.lowConfidenceBanner"].waitForExistence(timeout: 5),
                      "A poor import should open the review with the low-confidence banner.")
        snap(app, "09-low-confidence-import")
    }

    /// Import 3/5: no dead ends. Forced failures (`-force-import-failure`) show "Start from this text" on a paste that
    /// found no recipe (which opens the editor with the text kept) and "Paste the recipe text instead" on a failed link.
    @MainActor
    func testCaptureImportFailureFallbacks() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-force-import-failure"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        app.tabBars.buttons["Import"].tap()
        settle()

        // Paste: no recipe found → keep the text.
        app.buttons["import.paste"].tap()
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5), "The paste sheet should show a text box.")
        editor.tap()
        editor.typeText("Nan's lemon cake\nzest two lemons, bake till golden")
        app.buttons["Import"].firstMatch.tap()
        let startFromText = app.buttons["import.startFromText"]
        XCTAssertTrue(startFromText.waitForExistence(timeout: 10), "A paste with no recipe should offer Start from this text.")
        snap(app, "10-import-no-recipe")
        startFromText.tap()
        XCTAssertTrue(app.staticTexts["Let's start with a name"].waitForExistence(timeout: 5),
                      "Start from this text should open the editor.")
        snap(app, "11-start-from-text")
        app.terminate()

        // Link: page can't be read → paste instead.
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        app.tabBars.buttons["Import"].tap()
        settle()
        app.buttons["import.link"].tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "The link sheet should show a URL field.")
        field.tap()
        field.typeText("https://example.com/not-a-recipe")
        app.buttons["Import Recipe"].firstMatch.tap()
        XCTAssertTrue(app.buttons["import.pasteInstead"].waitForExistence(timeout: 10),
                      "A failed link should offer Paste the recipe text instead.")
        snap(app, "12-link-failed")
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
