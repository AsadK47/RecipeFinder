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

    /// Tabs 2/3: a first launch's Today — "Bring in your first recipe" + Starters — with the "Copied a recipe link?"
    /// card (DEBUG `-fake-clipboard-link`; CI's clipboard is empty). Named to sort first in this class, so on the
    /// Screenshots workflow's fresh simulator nothing has been cooked or imported yet. Other UI classes may run first
    /// on a shared simulator (nightly), so the new-user shot is taken only when that state is on screen.
    @MainActor
    func testCaptureAFirstLaunchToday() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-fake-clipboard-link"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        let card = app.descendants(matching: .any).matching(identifier: "today.clipboard").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "Today should offer to import a copied link.")
        XCTAssertTrue(app.buttons["today.clipboard.dismiss"].exists, "The clipboard card should be dismissible.")
        if app.buttons["today.addFirstRecipe"].waitForExistence(timeout: 5) {
            settle()
            snap(app, "20-today-new-user")
        }
        app.buttons["today.clipboard.dismiss"].tap()
        XCTAssertTrue(card.waitForNonExistence(timeout: 5), "Dismissing should hide the clipboard card.")
    }

    @MainActor
    func testCaptureScreenshots() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        let tabs = app.tabBars.firstMatch
        XCTAssertTrue(tabs.waitForExistence(timeout: 15), "App should reach the main tabs.")
        XCTAssertTrue(app.tabBars.buttons["Today"].isSelected, "The app should open on Today.")
        settle()

        // 1. Recipe library
        tab(app, "Recipes", shot: "01-recipes")

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

        // 3–5. Other tabs and the "+" sheet
        tab(app, "Groceries", shot: "03-groceries")
        tab(app, "Plan", shot: "04-meal-plan")
        tab(app, "Today", shot: "16-today")
        tab(app, "Me", shot: "17-me")
        tab(app, "Recipes", shot: nil)
        let add = app.buttons["recipes.add"]
        if add.waitForExistence(timeout: 5) {
            add.tap()
            settle()
            snap(app, "05-import")
            app.buttons["import.close"].tap()
            settle()
        }

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
        app.tabBars.buttons["Recipes"].tap()
        settle()

        // By name: other screenshot tests seed recipes that also sort near the top and persist on the simulator.
        let row = app.staticTexts["1-Pot Tomato Soup"].firstMatch
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
        app.tabBars.buttons["Recipes"].tap()
        let add = app.buttons["recipes.add"]
        guard add.waitForExistence(timeout: 5) else { return }
        add.tap()
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
        app.tabBars.buttons["Recipes"].tap()
        app.buttons["recipes.add"].tap()
        settle()

        // Paste: no recipe found → keep the text.
        app.buttons["import.paste"].tap()
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 5), "The paste sheet should show a text box.")
        editor.tap()
        editor.typeText("Nan's lemon cake\nzest two lemons, bake till golden")
        app.buttons["paste.import"].tap()
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
        app.tabBars.buttons["Recipes"].tap()
        app.buttons["recipes.add"].tap()
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

    /// Import 5/5: the in-app recipe search (empty state; results need the network, so they aren't captured here).
    @MainActor
    func testCaptureWebSearch() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        app.tabBars.buttons["Recipes"].tap()
        app.buttons["recipes.add"].tap()
        settle()
        app.buttons["import.web"].tap()
        XCTAssertTrue(app.textFields["webSearch.query"].waitForExistence(timeout: 5),
                      "Search the web should open with a search field.")
        snap(app, "13-web-search")
    }

    /// Estimate missing amounts: the review sheet on a seeded recipe with gaps (`-seed-missing-amounts-recipe`, sorts
    /// first), filled by the DEBUG fake estimator (`-fake-amount-estimates`) since simulators lack Apple Intelligence.
    @MainActor
    func testCaptureEstimateAmounts() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-seed-missing-amounts-recipe", "-fake-amount-estimates"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        app.tabBars.buttons["Recipes"].tap()
        settle()
        let row = app.staticTexts["1-Bowl Banana Bread"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "The seeded recipe should be listed.")
        row.tap()
        settle()
        let estimate = app.buttons["recipe.estimateAmounts"]
        for _ in 0..<6 where !estimate.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(estimate.waitForExistence(timeout: 5), "A recipe missing most amounts should offer Estimate amounts.")
        estimate.tap()
        XCTAssertTrue(app.buttons["estimate.save"].waitForExistence(timeout: 10), "The review sheet should open.")
        settle()
        snap(app, "14-estimate-amounts")
    }

    /// Import from other apps: the summary after importing an export, shown via the DEBUG
    /// `-show-other-app-import-summary` flag because UI tests can't drive the system file picker.
    @MainActor
    func testCaptureOtherAppImportSummary() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-show-other-app-import-summary"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        app.tabBars.buttons["Me"].tap()
        app.buttons["me.settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "The Me gear should open Settings.")
        settle()
        let data = app.staticTexts["Data Management"].firstMatch
        for _ in 0..<4 where !data.isHittable { app.swipeUp() }
        data.tap()
        XCTAssertTrue(app.alerts["Import Finished"].waitForExistence(timeout: 10),
                      "The import summary should appear on Data Management.")
        snap(app, "15-other-app-import")
    }

    /// Tabs 2/3: Today's "Planned for tonight" hero + prep-ahead nudge, with tonight's and tomorrow's dinners seeded
    /// via the DEBUG `-seed-tonight-plan` flag. Sorts after `testCaptureScreenshots`, so `16-today` stays the unplanned day (the plan persists).
    @MainActor
    func testCaptureTodayPlanned() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-seed-tonight-plan"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        // Planning a meal can unlock a badge whose sheet would cover the shot; swipe it away.
        let badgeSheet = app.staticTexts.matching(NSPredicate(format: "label ==[c] 'Badge Earned!'")).firstMatch
        if badgeSheet.waitForExistence(timeout: 3) {
            badgeSheet.swipeDown()
            settle()
        }
        let hero = app.descendants(matching: .any).matching(identifier: "today.hero").firstMatch
        XCTAssertTrue(hero.waitForExistence(timeout: 10), "Today should lead with a Tonight card.")
        XCTAssertTrue(hero.label.contains("Planned for tonight"), "The Tonight card should be the planned dinner.")
        // Tabs 2/3 slice 4: tomorrow's seeded dinner needs starting tonight, so Today nudges it.
        let prepAhead = app.descendants(matching: .any).matching(identifier: "today.prepAhead").firstMatch
        XCTAssertTrue(prepAhead.waitForExistence(timeout: 5), "Today should nudge tomorrow's prep-ahead dinner.")
        XCTAssertTrue(prepAhead.label.contains("tonight for tomorrow's dinner"), "The nudge should say when to prep.")
        settle()
        snap(app, "18-today-planned")

        // Tabs 2/3: "Let's cook" goes straight into cooking mode, not just the recipe page.
        let cook = app.buttons["today.hero.cook"]
        XCTAssertTrue(cook.waitForExistence(timeout: 5), "The Tonight card should offer Let's cook.")
        cook.tap()
        XCTAssertTrue(app.buttons["cooking.done"].waitForExistence(timeout: 10),
                      "Let's cook should open cooking mode.")
        settle()
        snap(app, "19-today-lets-cook")
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
