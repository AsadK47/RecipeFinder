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
                    // Filling the list can earn a badge; a tap on its reveal can land on "View all badges" (→ Profile).
                    dismissBadgeSheet(app)
                }
            }
            app.navigationBars.buttons.element(boundBy: 0).tap()
            settle()
        }

        // 3–5. Other tabs and the "+" sheet
        tab(app, "Groceries", shot: "03-groceries")
        let atHome = app.buttons["At home"]
        if atHome.waitForExistence(timeout: 5) {
            atHome.tap()
            settle()
            snap(app, "46-groceries-at-home")
            app.buttons["To buy"].tap()
            settle()
        }
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

    /// Cooking flow: tapping ingredient rows ticks them in place, they move into "Got it" once tapping pauses, and
    /// ticking them all offers cooking mode. Asserts the flow (it's the cook's first step), then captures both states.
    @MainActor
    func testCaptureRecipeTicks() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        tab(app, "Recipes", shot: nil)
        let recipe = app.descendants(matching: .any).matching(identifier: "recipe.row").firstMatch
        guard recipe.waitForExistence(timeout: 10) else {
            XCTFail("The Recipes home should list a recipe to tick ingredients on.")
            return
        }
        recipe.tap()
        settle()

        let rows = app.buttons.matching(identifier: "recipe.ingredient.row")
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 5), "The recipe should list its ingredients.")
        // Bring the ingredients card up under the title; the page doesn't auto-scroll for taps.
        app.swipeUp(velocity: .slow)
        settle(1)
        let total = rows.count
        XCTAssertGreaterThan(total, 1, "Need two or more ingredients to show both groups.")
        // The first row still to get, by its VoiceOver value — rows stay put until tapping pauses, then move.
        let nextToGet = app.buttons.matching(
            NSPredicate(format: "identifier == 'recipe.ingredient.row' AND value == 'Not yet'")
        ).firstMatch

        // Matched by label so the check holds whether or not the row has moved yet.
        let firstLabel = rows.element(boundBy: 0).label
        rows.element(boundBy: 0).tap()
        let tapped = app.buttons.matching(
            NSPredicate(format: "identifier == 'recipe.ingredient.row' AND label == %@", firstLabel)
        ).firstMatch
        XCTAssertEqual(tapped.value as? String, "Got it", "A tap should tick that row.")
        let gotIt = app.descendants(matching: .any).matching(identifier: "recipe.ingredients.gotIt").firstMatch
        XCTAssertTrue(gotIt.waitForExistence(timeout: 4), "Once tapping pauses, the ticked row should move into Got it.")
        nextToGet.tap()
        settle(2)
        snap(app, "38-recipe-got-it")

        // Pause between taps so each tick settles and the next row to get is back at the top, on screen.
        for _ in 0..<total where nextToGet.exists {
            nextToGet.tap()
            settle(1.5)
        }
        let startCooking = app.buttons["recipe.ingredients.startCooking"]
        XCTAssertTrue(startCooking.waitForExistence(timeout: 4), "All ticked should offer to start cooking.")
        settle(1)
        snap(app, "39-recipe-all-set")
        XCTAssertTrue(startCooking.isHittable, "Start cooking should appear on screen, where the last rows were.")
        startCooking.tap()
        XCTAssertTrue(app.buttons["cooking.done"].waitForExistence(timeout: 5), "Start cooking should open cooking mode.")

        // Cooking flow slice 2: step through until a step names an ingredient; it lists that ingredient with its amount.
        let next = app.buttons["cooking.next"]
        let stepIngredients = app.descendants(matching: .any).matching(identifier: "cooking.stepIngredients").firstMatch
        for _ in 0..<8 where !stepIngredients.exists && next.exists {
            checkpoint(app, "cooking-next")
            next.tap()
            settle(1)
        }
        XCTAssertTrue(stepIngredients.waitForExistence(timeout: 3), "A step that names an ingredient should list it.")
        snap(app, "50-cooking-step-ingredients")

        // Cooking flow slice 3: leaving mid-recipe and starting again picks up at the same step.
        // Done on the last step finishes the cook (and forgets the place), so step back off it first.
        if next.label.hasPrefix("Finish") {
            app.buttons["cooking.back"].tap()
            settle(1)
        }
        let position = app.staticTexts["cooking.stepPosition"]
        XCTAssertTrue(position.waitForExistence(timeout: 3), "A step should show its position.")
        let leftAt = position.label
        checkpoint(app, "cooking-leave")
        app.buttons["cooking.done"].tap()
        XCTAssertTrue(startCooking.waitForExistence(timeout: 5), "Leaving cooking mode should return to the recipe.")
        settle(1)
        startCooking.tap()
        XCTAssertTrue(app.buttons["cooking.done"].waitForExistence(timeout: 5), "Start cooking should reopen cooking mode.")
        XCTAssertTrue(position.waitForExistence(timeout: 3), "Reopening should resume on a step, not the ingredient list.")
        XCTAssertEqual(position.label, leftAt, "Reopening should resume at the step the cook left.")

        // Cooking flow slice 3b: a step's named timer stays in sight on the next step.
        let startTimer = app.buttons["cooking.startTimer"]
        let back = app.buttons["cooking.back"]
        for _ in 0..<12 where !startTimer.exists && !next.label.hasPrefix("Finish") {
            next.tap()
            settle(1)
        }
        for _ in 0..<12 where !startTimer.exists && back.exists {
            back.tap()
            settle(1)
        }
        XCTAssertTrue(startTimer.waitForExistence(timeout: 3), "A step with a time in it should offer a timer.")
        checkpoint(app, "cooking-start-timer")
        startTimer.tap()
        // Starting a timer asks for notification permission once.
        let allowPrompt = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        if allowPrompt.waitForExistence(timeout: 6) { allowPrompt.tap() }
        let timerPill = app.descendants(matching: .any).matching(identifier: "cooking.timer").firstMatch
        XCTAssertTrue(timerPill.waitForExistence(timeout: 3), "A started timer should show as a pill.")
        settle(1)
        snap(app, "51-cooking-timers")
        let move = next.label.hasPrefix("Finish") ? back : next
        checkpoint(app, "cooking-timer-next-step")
        move.tap()
        settle(1)
        XCTAssertTrue(timerPill.waitForExistence(timeout: 3), "The timer should stay visible on another step.")
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

        // Add flow 2/3: the sheet leads with one box for a link or recipe text.
        snap(app, "23-add-sheet")

        // Paste: no recipe found → keep the text.
        let editor = addInput(in: app)
        XCTAssertTrue(editor.waitForExistence(timeout: 5), "The + sheet should lead with the paste box.")
        editor.tap()
        editor.typeText("Nan's lemon cake\nzest two lemons, bake till golden")
        app.buttons["add.continue"].tap()
        let startFromText = app.buttons["import.startFromText"]
        XCTAssertTrue(startFromText.waitForExistence(timeout: 10), "A paste with no recipe should offer Start from this text.")
        snap(app, "10-import-no-recipe")
        startFromText.tap()
        XCTAssertTrue(app.buttons["draft.name"].waitForExistence(timeout: 5),
                      "Start from this text should open the recipe screen.")
        snap(app, "11-start-from-text")
        app.terminate()

        // Link: page can't be read → paste instead.
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        app.tabBars.buttons["Recipes"].tap()
        app.buttons["recipes.add"].tap()
        settle()
        // Link: detected in the same box and fetched straight away (no second URL field).
        let field = addInput(in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 5), "The + sheet should lead with the paste box.")
        field.tap()
        field.typeText("https://example.com/not-a-recipe")
        app.buttons["add.continue"].tap()
        XCTAssertTrue(app.buttons["import.pasteInstead"].waitForExistence(timeout: 10),
                      "A failed link should offer Paste the recipe text instead.")
        snap(app, "12-link-failed")
    }

    /// The "+" sheet's paste box: a multi-line SwiftUI TextField surfaces as a text view or a text field by OS version.
    @MainActor
    private func addInput(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "add.input").firstMatch
    }

    /// Add flow 1/3: a blank new recipe shown as it will look once saved; tapping the name opens just that editor.
    @MainActor
    func testCaptureNewRecipeDraft() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        app.tabBars.buttons["Recipes"].tap()
        app.buttons["recipes.add"].tap()
        settle()
        app.buttons["import.wizard"].tap()
        let name = app.buttons["draft.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5), "Create manually should open the new-recipe screen.")
        XCTAssertTrue(app.buttons["draft.save"].exists, "Save should be pinned on the new-recipe screen.")
        snap(app, "21-new-recipe")
        name.tap()
        XCTAssertTrue(app.textFields["wizard.recipeName"].waitForExistence(timeout: 5),
                      "Tapping the name should open the name & photo editor.")
        snap(app, "22-new-recipe-edit-name")
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
        dismissBadgeSheet(app)
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
        checkpoint(app, "Me before the Settings gear")
        app.buttons["me.settings"].tap()
        checkpoint(app, "after the Settings gear")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "The Me gear should open Settings.")
        settle()
        let data = app.staticTexts["Data Management"].firstMatch
        for _ in 0..<4 where !data.isHittable { app.swipeUp() }
        data.tap()
        checkpoint(app, "after Data Management")
        XCTAssertTrue(app.alerts["Import Finished"].waitForExistence(timeout: 10),
                      "The import summary should appear on Data Management.")
        snap(app, "15-other-app-import")

        // Data safety 2/4: the same screen opens on the iCloud sync switch (off on a fresh install). Matched by
        // label: a Toggle folds its text into the switch, so neither a static text nor the row's identifier is
        // guaranteed to surface as its own element.
        app.alerts["Import Finished"].buttons["OK"].tap()
        let sync = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Sync with iCloud")).firstMatch
        XCTAssertTrue(sync.waitForExistence(timeout: 10), "Data Management should show the iCloud sync switch.")
        settle()
        snap(app, "37-data-management-sync")
    }

    /// Plan slice 5: Settings › Notifications shows the opt-in "Sunday Planning" switch (off on a fresh install).
    @MainActor
    func testCaptureNotificationSettings() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        app.tabBars.buttons["Me"].tap()
        checkpoint(app, "Me before the Settings gear")
        app.buttons["me.settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "The Me gear should open Settings.")
        settle()
        checkpoint(app, "before Notifications")
        app.staticTexts["Notifications"].firstMatch.tap()
        // Matched by label: a Toggle folds its text into the switch.
        let sunday = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Sunday Planning")).firstMatch
        for _ in 0..<3 where !sunday.exists { app.swipeUp() }
        XCTAssertTrue(sunday.waitForExistence(timeout: 10), "Notifications should offer the Sunday Planning switch.")
        settle()
        snap(app, "55-notifications-sunday-planning")

        // Inbox 🐞: with notifications denied, turning Sunday Planning on switches it back off and says why, so the
        // switch never promises a nudge iOS won't show. Needs a fresh install (CI reinstalls): this test and the
        // others that meet the prompt answer "Don't Allow"; a simulator where Allow was tapped keeps the switch on.
        let toggle = app.switches["settings.sundayPlanNudge"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "The Sunday Planning row should be a switch.")
        checkpoint(app, "before turning Sunday Planning on")
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        let dontAllow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        if dontAllow.waitForExistence(timeout: 6) { dontAllow.tap() }
        let off = expectation(for: NSPredicate(format: "value == '0'"), evaluatedWith: toggle)
        wait(for: [off], timeout: 8)
        let note = app.descendants(matching: .any)["settings.sundayPlanNudge.denied"]
        XCTAssertTrue(note.waitForExistence(timeout: 5), "A denied nudge should say notifications are off.")
        settle()
        snap(app, "57-notifications-sunday-denied")
    }

    /// Theme palette: every theme's picker and Today, in Light and Dark (DEBUG `-ui-light` / `-ui-dark`). `-ui-testing`
    /// resets the theme to Teal and the appearance to System on each launch, so later tests keep the defaults.
    @MainActor
    func testCaptureThemes() {
        let themes = ["Tomato", "Saffron", "Honey", "Herb", "Teal", "Blueberry", "Plum", "Raspberry"]
        for mode in ["light", "dark"] {
            let app = XCUIApplication()
            app.launchArguments += ["-ui-testing", "-ui-\(mode)"]
            app.launch()
            XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
            app.tabBars.buttons["Me"].tap()
            checkpoint(app, "Me before the Settings gear (\(mode))")
            app.buttons["me.settings"].tap()
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "The Me gear should open Settings.")
            app.staticTexts["Appearance & Theme"].firstMatch.tap()
            XCTAssertTrue(app.buttons["theme.Teal"].waitForExistence(timeout: 5), "Appearance should show the picker.")
            settle(0.8)
            for theme in themes {
                let swatch = app.buttons["theme.\(theme)"]
                XCTAssertTrue(swatch.waitForExistence(timeout: 5), "The picker should offer \(theme).")
                for _ in 0..<3 where !swatch.isHittable { app.swipeUp() }
                checkpoint(app, "before picking \(theme) (\(mode))")
                swatch.tap()
                let selected = expectation(for: NSPredicate(format: "isSelected == true"), evaluatedWith: swatch)
                wait(for: [selected], timeout: 5)
                settle(0.8)
                snap(app, "61-theme-\(theme.lowercased())-\(mode)")
                app.tabBars.buttons["Today"].tap()
                settle(0.8)
                snap(app, "62-today-\(theme.lowercased())-\(mode)")
                app.tabBars.buttons["Me"].tap()
            }
            app.terminate()
        }

        // Theme slice 2: at the largest accessibility text size the picker goes to one column and VoiceOver reads
        // each swatch by its name (no "Checkmark"), with the chosen one marked selected.
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-UIPreferredContentSizeCategoryName",
                                "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        app.tabBars.buttons["Me"].tap()
        checkpoint(app, "Me before the Settings gear (AX size)")
        let gear = app.buttons["me.settings"]
        XCTAssertTrue(gear.waitForExistence(timeout: 5), "Me should show the Settings gear at AX sizes.")
        gear.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5), "The Me gear should open Settings.")
        // Lesson 23: hittable is true at the first peeking pixel, so scroll until the row clears the tab bar.
        let tabTop = app.tabBars.firstMatch.frame.minY
        func clearOfTabBar(_ element: XCUIElement) -> Bool {
            element.exists && element.isHittable && element.frame.maxY < tabTop
        }
        let appearance = app.staticTexts["Appearance & Theme"].firstMatch
        for _ in 0..<8 where !clearOfTabBar(appearance) { app.swipeUp() }
        checkpoint(app, "before Appearance & Theme (AX size)")
        appearance.tap()
        XCTAssertTrue(app.staticTexts["Colour Theme"].waitForExistence(timeout: 5), "Appearance should open at AX sizes.")
        // The swatches sit in a LazyVGrid: rows below the fold aren't built until scrolled to.
        for theme in themes {
            let swatch = app.buttons["theme.\(theme)"]
            for _ in 0..<8 where !clearOfTabBar(swatch) { app.swipeUp() }
            XCTAssertTrue(swatch.exists, "The picker should offer \(theme) at AX sizes.")
            XCTAssertEqual(swatch.label, theme, "VoiceOver should read the swatch's name.")
            if theme == "Teal" {
                XCTAssertTrue(swatch.isSelected, "The default theme should read as selected.")
                settle(0.8)
                snap(app, "63-theme-picker-ax")
            }
        }
        app.terminate()
    }

    /// Tabs 2/3: Today's "Planned for tonight" hero + prep-ahead nudge, with tonight's and tomorrow's dinners seeded
    /// via the DEBUG `-seed-tonight-plan` flag. Sorts after `testCaptureScreenshots`, so `16-today` stays the unplanned day (the plan persists).
    /// `-today-time 17:30` pins Today's clock to the evening: before 4pm Today leads breakfast/lunch with ideas, so the
    /// 03:00 UTC nightly saw no "Planned for tonight" hero (run 45931745156).
    @MainActor
    func testCaptureTodayPlanned() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-seed-tonight-plan", "-today-time", "17:30"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        // Planning a meal can unlock a badge whose sheet would cover the shot.
        dismissBadgeSheet(app)
        let hero = app.descendants(matching: .any).matching(identifier: "today.hero").firstMatch
        XCTAssertTrue(hero.waitForExistence(timeout: 10), "Today should lead with a Tonight card.")
        XCTAssertTrue(hero.label.contains("Planned for tonight"), "The Tonight card should be the planned dinner.")
        // Tabs 2/3 slice 4: tomorrow's seeded dinner needs starting tonight, so Today nudges it.
        let prepAhead = app.buttons.matching(identifier: "today.nudge").firstMatch
        XCTAssertTrue(prepAhead.waitForExistence(timeout: 5), "Today should nudge tomorrow's prep-ahead dinner.")
        XCTAssertTrue(prepAhead.label.contains("tonight for tomorrow's dinner"), "The nudge should say when to prep.")
        XCTAssertFalse(app.buttons["today.nudge.openKitchen"].exists, "Prep ahead isn't from the kitchen, so no kitchen link.")
        settle()
        snap(app, "18-today-planned")

        // Tabs 2/3: "Cook this" goes straight into cooking mode, not just the recipe page.
        let cook = app.buttons["today.hero.cook"]
        XCTAssertTrue(cook.waitForExistence(timeout: 5), "The Tonight card should offer Cook this.")
        cook.tap()
        XCTAssertTrue(app.buttons["cooking.done"].waitForExistence(timeout: 10),
                      "Cook this should open cooking mode.")
        settle()
        snap(app, "19-today-lets-cook")
    }

    /// Today+ 1/3: the Tonight card's time-aware line in the morning, afternoon and evening (DEBUG `-today-time` pins
    /// Today's clock), picking a later dinner time, and Shuffle stepping to another pick. Sorts after `testCaptureTodayPlanned`; seeds the same plan.
    /// The afternoon is 17:00, inside the 4–9pm dinner window: before 4pm Today leads lunch with ideas (09453d3), so
    /// a 15:00 pin had no Tonight card or "Dinner at" pill whenever a lunch idea was available.
    @MainActor
    func testCaptureTodayTimes() {
        for (time, shot) in [("08:30", "24-today-morning"), ("17:00", "25-today-afternoon"), ("21:00", "27-today-evening")] {
            let app = XCUIApplication()
            app.launchArguments += ["-ui-testing", "-seed-tonight-plan", "-today-time", time]
            app.launch()
            XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
            dismissBadgeSheet(app)
            let hero = app.descendants(matching: .any).matching(identifier: "today.hero").firstMatch
            XCTAssertTrue(hero.waitForExistence(timeout: 10), "Today should lead with a Tonight card at \(time).")
            // Declutter 1: the strip leaves off the planned dinner the hero shows and the meals gone by unplanned, so
            // from 5pm (seeded dinner in the hero, breakfast and lunch passed) nothing is left and the card goes.
            let strip = app.descendants(matching: .any).matching(identifier: "today.day").firstMatch
            if time == "08:30" {
                XCTAssertTrue(strip.waitForExistence(timeout: 5), "Today should show the day strip at \(time).")
                let breakfast = app.buttons["today.day.breakfast"]
                XCTAssertTrue(breakfast.isEnabled && breakfast.label.contains("nothing planned yet"),
                              "Breakfast should be open to plan at 8:30: \(breakfast.label)")
            } else {
                XCTAssertFalse(strip.exists, "With the planned dinner in the hero, the strip should be gone at \(time): \(hero.label)")
            }
            settle()
            snap(app, shot)

            if time == "21:00" {
                // Past 7pm with tonight's dinner not cooked yet, the line says when this recipe would be ready
                // (or, for a long one, how long it takes).
                let label = hero.label
                XCTAssertTrue(
                    label.contains("Start now to eat by") || label.contains("Takes "),
                    "Evening should say when tonight's pick would be ready: \(label)"
                )
            }
            if time == "17:00" {
                // The timing line is the eat-time Menu ("Start by 6 to eat at 7 ▾"); the start time follows the pick.
                let timing = app.buttons["today.hero.eatAt"]
                XCTAssertTrue(timing.waitForExistence(timeout: 5), "The Tonight card should offer a dinner time.")
                // "eat at", not "eat at 7": the pick persists, so an interrupted earlier run can leave 8pm.
                XCTAssertTrue(timing.label.contains("eat at"), "The timing line should be the Menu: \(timing.label)")
                XCTAssertFalse(hero.label.contains("eat at"), "The card shouldn't repeat the Menu's line: \(hero.label)")
                timing.tap()
                let eight = app.buttons["8 pm"]
                XCTAssertTrue(eight.waitForExistence(timeout: 5), "The Menu should offer dinner times.")
                eight.tap()
                settle(1)
                XCTAssertTrue(timing.label.contains("eat at 8"), "Start time should count back from 8pm: \(timing.label)")
                snap(app, "28-today-eat-at-8")
                // Put 7pm back: the choice persists in the shared simulator.
                timing.tap()
                let seven = app.buttons["7 pm"]
                XCTAssertTrue(seven.waitForExistence(timeout: 5), "7pm should be a dinner time.")
                seven.tap()
                settle(1)

                let before = hero.label
                let shuffle = app.buttons["today.hero.shuffle"]
                XCTAssertTrue(shuffle.waitForExistence(timeout: 5), "Tonight should offer Shuffle.")
                shuffle.tap()
                settle(1)
                XCTAssertNotEqual(hero.label, before, "Shuffle should show another pick.")
                snap(app, "26-today-shuffled")
            }
            app.terminate()
        }
    }

    /// Today+ 2/3: "Use it up" pairs kitchen items going off soon with a recipe (DEBUG `-seed-use-soon` adds spinach
    /// for today and lemons in three days). Sorts after `testCaptureTodayTimes`.
    @MainActor
    func testCaptureTodayUseSoon() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-seed-use-soon"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        // Seeding kitchen items schedules expiry reminders, which asks for notification permission over the shot.
        let allowPrompt = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Don’t Allow"]
        if allowPrompt.waitForExistence(timeout: 5) { allowPrompt.tap() }
        dismissBadgeSheet(app)
        let row = app.buttons.matching(identifier: "today.nudge").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Today should pair spinach going off with a recipe.")
        XCTAssertTrue(row.label.contains("Spinach: use by today"), "The nudge should say when to use the spinach.")
        for _ in 0..<3 where !row.isHittable { app.swipeUp() }
        settle()
        snap(app, "29-today-use-soon")

        // Kitchen you can find slice 2: the section's "Your kitchen" link opens Groceries on At home.
        let link = app.buttons["today.nudge.openKitchen"]
        XCTAssertTrue(link.waitForExistence(timeout: 5), "Use it up should link to the kitchen it's built from.")
        // Scrolling the row into view can tuck the header just above it under the nav bar.
        if !link.isHittable { app.swipeDown() }
        link.tap()
        let atHome = app.descendants(matching: .any).matching(identifier: "groceries.atHome").firstMatch
        XCTAssertTrue(atHome.waitForExistence(timeout: 5), "Your kitchen should open Groceries on At home.")
        XCTAssertTrue(atHome.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Spinach")).firstMatch
                        .waitForExistence(timeout: 5), "At home should list the spinach.")
        settle()
        snap(app, "47-today-kitchen-at-home")
    }

    /// Today+ 2/3 slice 2: the "This week" strip and planning an empty day's dinner from it. Sorts after
    /// `testCaptureTodayUseSoon`; earlier tests leave tonight and tomorrow planned, so a later day is the empty one.
    @MainActor
    func testCaptureTodayWeek() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        dismissBadgeSheet(app)
        let days = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'today.week.day.'"))
        let first = days.firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 10), "Today should show the week strip.")
        for _ in 0..<5 where !first.isHittable { app.swipeUp() }
        XCTAssertEqual(days.count, 7, "The week strip should show seven days.")
        XCTAssertTrue(first.label.hasPrefix("Today"), "The strip should start today: \(first.label)")
        settle()
        snap(app, "30-today-week")

        let empty = days.matching(NSPredicate(format: "label ENDSWITH 'nothing planned'")).firstMatch
        XCTAssertTrue(empty.exists, "Some day this week should be unplanned.")
        let emptyID = empty.identifier
        empty.tap()
        let pick = app.buttons.matching(identifier: "mealPicker.recipe").firstMatch
        XCTAssertTrue(pick.waitForExistence(timeout: 5), "Tapping an empty day should offer recipes for its dinner.")
        settle()
        snap(app, "31-today-plan-day")
        pick.tap()
        dismissBadgeSheet(app)
        let planned = app.buttons[emptyID]
        XCTAssertTrue(planned.waitForExistence(timeout: 5), "The day should still be on the strip.")
        let markedPlanned = NSPredicate(format: "label CONTAINS 'dinner:'")
        expectation(for: markedPlanned, evaluatedWith: planned)
        waitForExpectations(timeout: 5)
    }

    /// Today's "Your cooking" row (streak, cooks this week, next badge); tapping it opens the Cooking sheet. Browsing
    /// shelves live on Recipes → Discover now (Today — decide tonight), so none sit under it.
    @MainActor
    func testCaptureTodayProgress() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        dismissBadgeSheet(app)
        let progress = app.buttons["today.progress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 10), "Today should show the progress row.")
        // The tab bar floats over the scroll, so "hittable" isn't "visible": nudge up until the card clears it.
        let tabBarTop = app.tabBars.firstMatch.frame.minY
        let window = app.windows.firstMatch
        for _ in 0..<12 where progress.frame.maxY > tabBarTop - 16 {
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                .press(forDuration: 0.05, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)))
        }
        for id in ["today.tryNew", "today.shelf.cookAgain", "today.shelf.kitchen", "today.shelf.rediscover"] {
            XCTAssertFalse(app.descendants(matching: .any)[id].exists, "Browsing moved to Recipes → Discover: \(id)")
        }
        XCTAssertTrue(progress.label.contains("week streak"), "Progress should read the streak: \(progress.label)")
        XCTAssertTrue(progress.label.contains("this week"), "Progress should read cooks this week: \(progress.label)")
        settle()
        snap(app, "32-today-progress")

        progress.tap()
        XCTAssertTrue(app.staticTexts["Cooking badges"].waitForExistence(timeout: 5),
                      "Tapping progress should open the Cooking sheet.")
        settle()
        snap(app, "33-today-cooking-sheet")
    }

    /// Owner 2026-11-17: a badge card should close with a swipe down, not only the ✕.
    @MainActor
    func testBadgeCardClosesWithASwipeDown() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        dismissBadgeSheet(app)
        let row = app.buttons["today.progress.badges"]
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Today should show the next-badge row.")
        let tabBarTop = app.tabBars.firstMatch.frame.minY
        let window = app.windows.firstMatch
        for _ in 0..<12 where row.frame.maxY > tabBarTop - 16 {
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                .press(forDuration: 0.05, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)))
        }
        checkpoint(app, "today badge row")
        row.tap()
        let position = app.staticTexts["badge.pager.position"]
        XCTAssertTrue(position.waitForExistence(timeout: 8), "The badge card should open.")
        settle(1)

        checkpoint(app, "badge card open")
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            .press(forDuration: 0.05, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)))
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: position)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(app.staticTexts["Trophy shelf"].waitForExistence(timeout: 5), "Me should be back after the swipe.")
    }

    /// Tester feedback: Today's next-badge row opens Me's trophy shelf with that badge's card up (not the Cooking sheet).
    @MainActor
    func testTodayBadgeRowOpensItsBadgeOnTheShelf() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        dismissBadgeSheet(app)
        let row = app.buttons["today.progress.badges"]
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Today should show the next-badge row.")
        let tabBarTop = app.tabBars.firstMatch.frame.minY
        let window = app.windows.firstMatch
        for _ in 0..<12 where row.frame.maxY > tabBarTop - 16 {
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                .press(forDuration: 0.05, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)))
        }
        // A fresh install has cooked nothing, so a badge is always left to earn: "1 more cook to Head Chef".
        let parts = row.label.components(separatedBy: " to ")
        XCTAssertTrue(parts.count > 1 && row.label.contains(" more "), "The row should say what's left: \(row.label)")
        let badgeTitle = (parts.last ?? "").components(separatedBy: ",").first ?? ""
        checkpoint(app, "today badge row")
        row.tap()

        let progress = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH 'badge.pager.progress.'"))
            .firstMatch
        XCTAssertTrue(progress.waitForExistence(timeout: 8), "The badge's card should open on the shelf.")
        XCTAssertTrue(app.staticTexts[badgeTitle].exists, "The card should be the row's badge, \(badgeTitle).")
        XCTAssertTrue(app.tabBars.buttons["Me"].isSelected, "The row should switch to Me.")
        XCTAssertFalse(app.staticTexts["Cooking badges"].exists, "The row shouldn't open the Cooking sheet.")
        settle()
        snap(app, "45-today-badge-on-shelf")

        app.buttons["badge.pager.close"].tap()
        let shelf = app.staticTexts["Trophy shelf"]
        XCTAssertTrue(shelf.waitForExistence(timeout: 5), "Closing the card should leave Profile up.")
        XCTAssertTrue(shelf.isHittable, "Profile should have scrolled to the trophy shelf.")

        // Profile already on screen in Me: a second tap from Today must still open the card.
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Today should still show the next-badge row.")
        checkpoint(app, "today badge row again")
        row.tap()
        XCTAssertTrue(progress.waitForExistence(timeout: 8), "A second tap should open the card again.")
    }

    /// Badges 1/2: Me's trophy shelf, a locked badge in the full-screen pager (progress + earn-here button), a swipe
    /// to the next card, and the earn-here button switching tab.
    @MainActor
    func testCaptureTrophyShelf() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        dismissBadgeSheet(app)
        tab(app, "Me", shot: nil)
        // The shelf lives one tap deeper than Me, in Profile.
        let profile = app.buttons["me.profile"]
        for _ in 0..<4 where !(profile.exists && profile.isHittable) { app.swipeUp() }
        XCTAssertTrue(profile.waitForExistence(timeout: 5), "Me should show the profile hero.")

        // The name is edited in place on the hero: tap it, type, Done — no form, no Save.
        let name = app.buttons["me.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5), "Me's hero should show the name as a button.")
        checkpoint(app, "hero name")
        name.tap()
        let field = app.textFields["me.name.field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Tapping the name should open the inline field.")
        // Cursor to the end (a tap mid-text would leave the tail), then clear what an earlier run saved.
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.5)).tap()
        let current = field.value as? String ?? ""
        if !current.isEmpty, current != "Your name" {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        // Never the name already saved (the simulator keeps the profile, so a fixed name would pass even if saving
        // broke), but a real-looking one: it shows in the published Me screenshots.
        let newName = ["Sam Rivera", "Alex Morgan"].first { $0 != current } ?? "Sam Rivera"
        field.typeText(newName)
        app.buttons["me.name.done"].tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 5), "Done should close the inline field.")
        XCTAssertEqual(app.buttons["me.name"].label, newName, "The hero should show the new name.")

        profile.tap()

        // Earned medals + "Next up" (closest three, with counts) come first; the full shelf is behind See all.
        let nextUp = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'me.nextUp.'"))
        XCTAssertTrue(nextUp.firstMatch.waitForExistence(timeout: 5), "Profile should show the badges up next.")
        XCTAssertLessThanOrEqual(nextUp.count, 3, "Next up shows at most three badges.")
        XCTAssertFalse(app.buttons["me.badge.streak_twelve_weeks"].exists, "Locked badges wait behind See all.")
        let seeAll = app.buttons["me.badges.seeAll"]
        for _ in 0..<6 where !(seeAll.exists && seeAll.isHittable) { app.swipeUp() }
        settle()
        snap(app, "34a-me-next-up")
        checkpoint(app, "see all badges")
        seeAll.tap()

        // Third in the Streaks row, so it's on screen without a sideways scroll; nobody has a 12-week streak in CI.
        let locked = app.buttons["me.badge.streak_twelve_weeks"]
        for _ in 0..<8 where !(locked.exists && locked.isHittable) { app.swipeUp() }
        XCTAssertTrue(locked.waitForExistence(timeout: 5), "Me should show the trophy shelf.")
        XCTAssertTrue(app.staticTexts["Trophy shelf"].exists, "The shelf should have its title.")
        // The tab bar floats over the scroll, so "hittable" isn't "visible": nudge up until the row clears it.
        let tabBarTop = app.tabBars.firstMatch.frame.minY
        let window = app.windows.firstMatch
        for _ in 0..<6 where locked.frame.maxY > tabBarTop - 60 {
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                .press(forDuration: 0.05, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        }
        settle()
        snap(app, "34-me-trophy-shelf")

        locked.tap()
        let progress = app.staticTexts["badge.pager.progress.streak_twelve_weeks"]
        XCTAssertTrue(progress.waitForExistence(timeout: 5), "A locked badge should show its progress.")
        XCTAssertTrue(progress.label.hasSuffix("/ 12 weeks"), "Progress should count weeks: \(progress.label)")
        let earn = app.buttons["badge.pager.earn.streak_twelve_weeks"]
        XCTAssertTrue(earn.exists, "A locked badge should offer where to earn it.")
        settle()
        snap(app, "35-badge-pager-locked")

        let position = app.staticTexts["badge.pager.position"]
        let before = position.label
        app.swipeLeft()
        settle(1)
        XCTAssertNotEqual(position.label, before, "Swiping should move to the next badge.")
        app.swipeRight()
        settle(1)

        earn.tap()
        let today = app.tabBars.buttons["Today"]
        let selected = NSPredicate(format: "isSelected == true")
        expectation(for: selected, evaluatedWith: today)
        waitForExpectations(timeout: 5)
        XCTAssertFalse(app.staticTexts["badge.pager.position"].exists, "The pager should be closed before the tab switches.")
    }

    /// Badges 1/2 slice 2: the full-screen earn reveal (flip, shine, confetti) and closing it with the ✕.
    @MainActor
    func testCaptureBadgeReveal() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-show-badge-reveal"]
        app.launch()
        let title = app.staticTexts["badge.reveal.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 15), "The reveal should open full screen on launch.")
        XCTAssertEqual(title.label, "Head Chef", "The reveal should name the badge.")
        XCTAssertTrue(app.buttons["badge.reveal.viewAll"].exists, "The reveal should offer View all badges.")
        settle(2.5)
        snap(app, "36-badge-reveal")

        app.buttons["badge.reveal.close"].tap()
        let headChef = app.staticTexts.matching(
            NSPredicate(format: "identifier == 'badge.reveal.title' AND label == 'Head Chef'")
        ).firstMatch
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: headChef)
        waitForExpectations(timeout: Self.revealTimeout)
    }

    /// TestFlight 2026-11-15: "View all badges" left the reveal stuck on screen. It must close and land on Me's
    /// trophy shelf (one tap deeper, in Profile).
    @MainActor
    func testBadgeRevealViewAllClosesAndOpensMe() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-show-badge-reveal"]
        app.launch()
        let viewAll = app.buttons["badge.reveal.viewAll"]
        XCTAssertTrue(viewAll.waitForExistence(timeout: 15), "The reveal should open full screen on launch.")
        settle(1.5)
        checkpoint(app, "badge reveal before View all")
        viewAll.tap()
        checkpoint(app, "after View all")

        // Head Chef must close. A badge the launch itself earned can queue behind it and open next; close that one
        // too — the cover then dismisses and Me opens.
        let headChef = app.staticTexts.matching(
            NSPredicate(format: "identifier == 'badge.reveal.title' AND label == 'Head Chef'")
        ).firstMatch
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: headChef)
        waitForExpectations(timeout: Self.revealTimeout)
        // The queued reveal may still be sliding in; give it a moment before deciding there is none.
        let title = app.staticTexts["badge.reveal.title"]
        if title.waitForExistence(timeout: 2) {
            checkpoint(app, "queued reveal after Head Chef: \(title.label)")
            app.buttons["badge.reveal.close"].tap()
        }
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: title)
        waitForExpectations(timeout: Self.revealTimeout)
        let me = app.tabBars.buttons["Me"]
        expectation(for: NSPredicate(format: "isSelected == true"), evaluatedWith: me)
        waitForExpectations(timeout: Self.revealTimeout)
        // Me opens Profile, where the badges are.
        XCTAssertTrue(app.staticTexts["Trophy shelf"].waitForExistence(timeout: Self.revealTimeout),
                      "View all badges should land on the trophy shelf.")
    }

    // MARK: - Helpers

    /// Waits around the badge reveal. 20 s, not 5–8: as the first test on a cold simulator one accessibility query
    /// alone took 7–11 s (Screenshots 43871503359) and the reveal closed after an 8 s wait gave up — Me and the shelf
    /// then passed. A stuck reveal (the TestFlight bug) never closes, so it still fails.
    private static let revealTimeout: TimeInterval = 20

    /// A seeded recipe or plan can unlock a badge whose sheet covers the tab bar (e.g. "First Bite" when a seeded
    /// recipe isn't the first launch's); swipe it away.
    @MainActor
    private func dismissBadgeSheet(_ app: XCUIApplication) {
        let badgeSheet = app.staticTexts.matching(NSPredicate(format: "label ==[c] 'Badge Earned!'")).firstMatch
        // The sheet can close on its own between the wait and the swipe (seen in CI), so drag the window rather than
        // the element — a drag never fails on a missing match, and with no sheet it lands harmlessly on Today.
        if badgeSheet.waitForExistence(timeout: 3) {
            let window = app.windows.firstMatch
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
                .press(forDuration: 0.05, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)))
            settle()
        }
    }

    /// Endless discovery below the library preview: Recipes scrolled one, two and three screens down.
    @MainActor
    func testCaptureRecipesDiscovery() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-recipes-discover"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        tab(app, "Recipes", shot: "40-recipes-discovery-0")
        checkpoint(app, "recipes-discover")
        let chapter = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'discovery.chapter.'")).firstMatch
        XCTAssertTrue(chapter.waitForExistence(timeout: 10), "Discover should show at least one chapter.")
        for screen in 1...3 {
            app.swipeUp(velocity: .slow)
            settle()
            snap(app, "40-recipes-discovery-\(screen)")
        }
    }

    /// Made-it moment: cooking mode's last-step Finish closes straight into the sheet — dish picture, "First time
    /// making …", week count, photo nudge. Finishing again the same day shows the done screen (one cook a day).
    /// Skipped (not failed) when an earlier run already cooked this recipe today, which disables the button.
    /// Named to sort last: the cook it records would otherwise show up in later shots (streak, Today, badges).
    @MainActor
    func testZCaptureMadeIt() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        dismissBadgeSheet(app)
        tab(app, "Recipes", shot: nil)
        let recipe = app.descendants(matching: .any).matching(identifier: "recipe.row").firstMatch
        guard recipe.waitForExistence(timeout: 10) else { return }
        recipe.tap()
        let markCooked = app.buttons["recipe.markCooked"]
        guard markCooked.waitForExistence(timeout: 10), markCooked.isEnabled else { return }

        // Cooking flow slice 4: Next to the last step, then Finish closes cooking mode into Made it.
        let madeItDone = app.buttons["madeIt.done"]
        let doneCard = app.descendants(matching: .any).matching(identifier: "cooking.finished").firstMatch
        finishCooking(app)
        XCTAssertTrue(madeItDone.waitForExistence(timeout: 6), "Finish should open the Made it sheet.")
        XCTAssertFalse(doneCard.exists, "Finish should close cooking mode, not stop on a done screen.")
        settle(4)   // let the confetti fall away
        snap(app, "41-made-it")
        madeItDone.tap()
        XCTAssertTrue(madeItDone.waitForNonExistence(timeout: 4), "Done should close the Made it sheet.")
        dismissBadgeSheet(app)   // a first cook can earn a badge, revealed once Made it closes
        XCTAssertFalse(markCooked.isEnabled, "Finishing cooking mode should count today's cook.")

        // Cooked already today: Finish has no sheet to open, so cooking mode says so on its done screen.
        finishCooking(app)
        XCTAssertTrue(doneCard.waitForExistence(timeout: 5), "A second cook today should show the done screen.")
        XCTAssertFalse(madeItDone.exists, "A second cook today shouldn't open Made it again.")
        app.buttons["cooking.done"].tap()
        XCTAssertTrue(markCooked.waitForExistence(timeout: 5), "Done should return to the recipe.")
    }

    /// From a recipe page: Start cooking, Next through every step, then Finish.
    @MainActor
    private func finishCooking(_ app: XCUIApplication) {
        let start = app.buttons["Start Cooking Mode"]
        checkpoint(app, "start cooking")
        XCTAssertTrue(start.waitForExistence(timeout: 5), "The recipe should offer cooking mode.")
        start.tap()
        let next = app.buttons["cooking.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 5), "Cooking mode should show Next.")
        for _ in 0..<40 where !next.label.hasPrefix("Finish") {
            next.tap()
            settle(0.5)
        }
        XCTAssertTrue(next.label.hasPrefix("Finish"), "Next should reach the last step's Finish.")
        checkpoint(app, "cooking finish")
        next.tap()
    }

    /// Plan — swipe to match: "Plan my week" deals one card per empty dinner; Plan it (button) and a right swipe each
    /// plan the night and move to the next, Not this one deals another dish for the same night. Sorts last: it
    /// plans dinners, which would fill the empty days earlier tests (Today's week strip) rely on.
    @MainActor
    func testZZZPlanMyWeek() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        dismissBadgeSheet(app)
        tab(app, "Plan", shot: nil)
        let open = app.buttons["plan.planMyWeek"]
        // The button looks four weeks ahead ("Plan week of …"), so it shows on the first Plan screen even when
        // earlier tests filled this week; missing is the owner's "deck vanished" bug (2026-11-20) — fail, not skip.
        guard open.waitForExistence(timeout: 5) else {
            XCTFail("Plan should offer Plan my week on the first Plan screen.")
            return
        }
        checkpoint(app, "plan my week")
        open.tap()
        let card = app.descendants(matching: .any).matching(identifier: "planDeck.card").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5), "Plan my week should deal a card.")
        let night = app.staticTexts["planDeck.night"]
        XCTAssertTrue(night.exists, "The deck should say which night it's planning.")
        XCTAssertFalse(app.tabBars.firstMatch.isHittable, "The deck should cover the tab bar.")
        settle()
        snap(app, "52-plan-deck")

        // Not this one: another dish for the same night.
        let firstNight = night.label
        let firstCard = card.label
        checkpoint(app, "skip")
        app.buttons["planDeck.skip"].tap()
        settle(0.8)
        if card.exists {
            XCTAssertEqual(night.label, firstNight, "Not this one should stay on the same night.")
            XCTAssertNotEqual(card.label, firstCard, "Not this one should deal a different dish.")
        }

        // Busy night: marks this night (quick dishes) and stays on it.
        // `.isToggle` surfaces it as a switch, not a button, so query any element type.
        let busy = app.descendants(matching: .any).matching(identifier: "planDeck.busy").firstMatch
        if card.exists {
            let busyNight = night.label
            checkpoint(app, "busy night")
            XCTAssertTrue(busy.exists, "The deck should offer Busy night.")
            busy.tap()
            settle(0.8)
            // A switch may report its value as "1" rather than the accessibilityValue text.
            let busyValue = busy.value as? String
            XCTAssertTrue(busyValue == "On" || busyValue == "1", "Busy night should show it's on (value \(busyValue ?? "nil")).")
            XCTAssertEqual(night.label, busyNight, "Busy night should stay on the same night.")
            XCTAssertTrue(card.label.contains("busy night"), "The card should say it's picked for a busy night.")
            snap(app, "56-plan-deck-busy")
        }

        // Plan it (button), then a right swipe: each plans the night and moves on.
        let finished = app.staticTexts["planDeck.finished"]
        for path in ["button", "swipe"] where card.exists {
            let before = night.label
            checkpoint(app, "plan by \(path)")
            if path == "button" { app.buttons["planDeck.plan"].tap() } else { card.swipeRight(velocity: .fast) }
            dismissBadgeSheet(app)
            settle(0.8)
            XCTAssertTrue(finished.exists || night.label != before, "Planning by \(path) should move to the next night.")
        }

        let close = finished.exists ? app.buttons["planDeck.done"] : app.buttons["planDeck.close"]
        XCTAssertTrue(close.exists, "The deck should offer a way out.")
        if finished.exists { snap(app, "53-plan-deck-done") }
        close.tap()
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: card)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5), "Closing the deck should bring back the tabs.")

        // The week as seven dinner photos: the nights just planned show their dish.
        let nights = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'plan.dinner.'"))
        XCTAssertTrue(app.descendants(matching: .any)["plan.dinner.6"].waitForExistence(timeout: 5),
                      "Plan should show the seventh night.")
        XCTAssertEqual(nights.count, 7, "Plan should show the week as seven nights.")
        let planned = nights.matching(NSPredicate(format: "label CONTAINS 'dinner:'"))
        XCTAssertTrue(planned.firstMatch.waitForExistence(timeout: 5), "A planned night should show its dinner.")
        // Scroll until the whole planned photo clears the tab bar (isHittable is true at its first pixel).
        let tabBarTop = app.tabBars.firstMatch.frame.minY
        for _ in 0..<4 where planned.firstMatch.frame.maxY > tabBarTop - 8 {
            app.swipeUp(velocity: .slow)
        }
        settle()
        snap(app, "54-plan-week-dinners")

        // Hold = move: the held night's dinner moves (or swaps), so that night no longer shows the same dish.
        let held = planned.firstMatch
        let heldID = held.identifier
        let heldLabel = held.label
        checkpoint(app, "hold to move")
        held.press(forDuration: 1.2)
        let move = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Move to' OR label BEGINSWITH 'Swap with'"))
            .firstMatch
        XCTAssertTrue(move.waitForExistence(timeout: 5), "Holding a dinner should offer to move it.")
        move.tap()
        settle(0.8)
        XCTAssertNotEqual(app.descendants(matching: .any)[heldID].label, heldLabel, "Moving should take the dinner off its night.")

        // Tap = open (owner 2026-11-20): a planned night opens its recipe, not cooking mode; Cook is the hold menu's.
        let toOpen = planned.firstMatch
        XCTAssertTrue(toOpen.waitForExistence(timeout: 5), "A planned night should still be on the week.")
        checkpoint(app, "tap to open")
        toOpen.tap()
        XCTAssertTrue(app.buttons["Start Cooking Mode"].waitForExistence(timeout: 10),
                      "Tapping a dinner photo should open its recipe.")
        XCTAssertFalse(app.buttons["cooking.done"].exists, "Tapping a dinner photo shouldn't start cooking.")
    }

    /// Owner 2026-11-20: "the swipe planning works the first time, then never appears or works again". Opens the deck,
    /// closes it, opens it again; then plans every night it deals and checks Plan still offers the deck afterwards.
    /// Sorts after testZZZPlanMyWeek (both plan dinners).
    @MainActor
    func testZZZPlanMyWeekAgain() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        dismissBadgeSheet(app)
        tab(app, "Plan", shot: nil)
        let open = app.buttons["plan.planMyWeek"]
        let card = app.descendants(matching: .any).matching(identifier: "planDeck.card").firstMatch
        let finished = app.staticTexts["planDeck.finished"]
        let gone = NSPredicate(format: "exists == false")

        for attempt in 1...2 {
            checkpoint(app, "open deck \(attempt)")
            XCTAssertTrue(open.waitForExistence(timeout: 5), "Plan should offer Plan my week (open \(attempt)).")
            open.tap()
            XCTAssertTrue(card.waitForExistence(timeout: 5) || finished.waitForExistence(timeout: 1),
                          "Plan my week should open (open \(attempt)).")
            app.buttons["planDeck.close"].tap()
            expectation(for: gone, evaluatedWith: app.buttons["planDeck.close"])
            waitForExpectations(timeout: 5)
        }

        // Plan every night the deck deals, then the deck should still be there for the next go.
        checkpoint(app, "plan the whole deck")
        XCTAssertTrue(open.waitForExistence(timeout: 5), "Plan should offer Plan my week before the full run.")
        open.tap()
        for _ in 0..<8 where card.waitForExistence(timeout: 3) {
            app.buttons["planDeck.plan"].tap()
            dismissBadgeSheet(app)
            settle(0.8)
        }
        XCTAssertTrue(finished.waitForExistence(timeout: 5), "Planning every night should finish the deck.")
        app.buttons["planDeck.done"].tap()
        expectation(for: gone, evaluatedWith: app.buttons["planDeck.close"])
        waitForExpectations(timeout: 5)

        checkpoint(app, "open after a full week")
        XCTAssertTrue(open.waitForExistence(timeout: 5), "Plan should still offer the deck once the week is planned.")
        open.tap()
        XCTAssertTrue(card.waitForExistence(timeout: 5), "The deck should deal again after a full week.")
        app.buttons["planDeck.close"].tap()
        expectation(for: gone, evaluatedWith: app.buttons["planDeck.close"])
        waitForExpectations(timeout: 5)


        // Swipe a planned meal left to take it off (owner 2026-11-20: "can't clear old plans").
        let dinner = app.descendants(matching: .any)["plan.meal.Dinner"]
        for _ in 0..<4 where dinner.exists && !dinner.isHittable { app.swipeUp(velocity: .slow) }
        if dinner.waitForExistence(timeout: 3) {
            checkpoint(app, "swipe to remove")
            dinner.swipeLeft(velocity: .fast)
            expectation(for: gone, evaluatedWith: dinner)
            waitForExpectations(timeout: 5)
        }
    }

    /// Groceries writes itself, slice 1: with dinners planned, To buy offers what the plan still needs in one tap,
    /// and once added the card goes (adding again would double nothing). Sorts after testZZZPlanMyWeek, so the
    /// planned week reaches Groceries; `-seed-tonight-plan` also plans tonight on a shard that ran nothing before.
    @MainActor
    func testZZZZGroceriesFromPlan() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-seed-tonight-plan"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        dismissBadgeSheet(app)
        tab(app, "Groceries", shot: nil)
        let toBuy = app.buttons["To buy"]
        if toBuy.waitForExistence(timeout: 5) { toBuy.tap() }
        let add = app.buttons["groceries.fromPlan.add"]
        checkpoint(app, "from your plan")
        XCTAssertTrue(add.waitForExistence(timeout: 10), "Groceries should offer what the planned meals still need.")
        settle()
        snap(app, "58-groceries-from-plan")
        add.tap()
        dismissBadgeSheet(app)
        XCTAssertTrue(add.waitForNonExistence(timeout: 5), "Once added, the plan's card should go.")
        XCTAssertFalse(app.staticTexts["Your groceries list is empty"].exists, "The plan's items should be on the list.")

        // Shop mode: big rows, tick one, Done puts it At home.
        let shopMode = app.buttons["groceries.shopMode"]
        checkpoint(app, "shop mode button")
        XCTAssertTrue(shopMode.waitForExistence(timeout: 5), "To buy should offer shop mode.")
        shopMode.tap()
        let firstRow = app.buttons.matching(identifier: "shop.row").firstMatch
        checkpoint(app, "shop mode rows")
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5), "Shop mode should list what's to buy.")
        settle()
        snap(app, "59-groceries-shop")
        let name = firstRow.label
        let progress = app.staticTexts["shop.progress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        // Earlier tests on the shard may have left ticks, so compare with what was in the basket before.
        let inBasket = { Int(progress.label.prefix { $0.isNumber }) ?? -1 }
        let before = inBasket()
        firstRow.tap()
        dismissBadgeSheet(app)
        let deadline = Date().addingTimeInterval(5)
        while inBasket() != before + 1 && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTAssertEqual(inBasket(), before + 1, "Ticking a row should put it in the basket: \(progress.label)")
        let done = app.buttons["shop.done"]
        checkpoint(app, "shop done")
        done.tap()
        dismissBadgeSheet(app)
        XCTAssertTrue(done.waitForNonExistence(timeout: 5), "Done should close shop mode.")
        // At home is a lazy list that earlier tests may have filled, so ask its search rather than scroll for the row.
        app.buttons["At home"].tap()
        let search = app.textFields["groceries.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText(name)
        checkpoint(app, "put away at home")
        XCTAssertTrue(app.buttons["Already in kitchen"].firstMatch.waitForExistence(timeout: 5),
                      "What was ticked in the shop should be At home: \(name)")
    }

    /// Groceries writes itself, slice 4: something the plan counts on has been At home three weeks
    /// (`-seed-still-got`), so To buy asks "Still got the …?"; "No, add it" settles that question in one tap.
    @MainActor
    func testZZZZZGroceriesStillGot() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-seed-tonight-plan", "-seed-still-got"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        dismissBadgeSheet(app)
        tab(app, "Groceries", shot: nil)
        let toBuy = app.buttons["To buy"]
        if toBuy.waitForExistence(timeout: 5) { toBuy.tap() }
        let no = app.buttons["groceries.stillGot.no"]
        checkpoint(app, "still got question")
        XCTAssertTrue(no.waitForExistence(timeout: 10), "Groceries should ask about an old perishable the plan needs.")
        let question = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH 'Still got the'")).firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 5), "The card should say what it's asking about.")
        let asked = question.label
        settle()
        snap(app, "60-groceries-still-got")
        no.tap()
        dismissBadgeSheet(app)
        let same = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", asked)).firstMatch
        checkpoint(app, "still got answered")
        XCTAssertTrue(same.waitForNonExistence(timeout: 5), "Answering should settle that question: \(asked)")
    }

    /// Me's hero above My Cookbook: one page (the cook testZCaptureMadeIt just recorded), then many (`-seed-cookbook`).
    /// The empty cookbook is 17-me on a fresh simulator. Named to sort after testZCaptureMadeIt for the same reason.
    @MainActor
    func testZZCaptureCookbook() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        dismissBadgeSheet(app)
        tab(app, "Me", shot: nil)
        let pages = app.descendants(matching: .any).matching(identifier: "cookbook.pages").firstMatch
        if pages.waitForExistence(timeout: 5) {
            settle()
            snap(app, "42-cookbook-one")
        }
        app.terminate()

        app.launchArguments += ["-seed-cookbook"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        dismissBadgeSheet(app)
        tab(app, "Me", shot: nil)
        dismissBadgeSheet(app)   // the seeded cooks can unlock a badge once the library loads
        XCTAssertTrue(pages.waitForExistence(timeout: 10), "Cooked recipes should fill My Cookbook.")
        settle()
        snap(app, "43-cookbook-many")
        // Me's hero sits above the cookbook: with cooks recorded, its stats strip counts them.
        let profile = app.buttons["me.profile"]
        XCTAssertTrue(profile.waitForExistence(timeout: 5), "Me should show the profile hero.")
        let value = profile.value as? String ?? ""
        // A count above zero, so "Nothing cooked yet" or "0 meals cooked" fail.
        XCTAssertNotNil(value.range(of: #"[1-9]\d* meals cooked"#, options: .regularExpression),
                        "Me's hero should count the seeded meals: \(value)")
        XCTAssertNotNil(value.range(of: #"[1-9]\d* cuisines? tried"#, options: .regularExpression),
                        "Me's hero should count cuisines tried: \(value)")
        // A page shares as a picture: the share button on the page opens a preview of exactly what gets sent.
        let share = app.buttons["cookbook.page.share"].firstMatch
        checkpoint(app, "cookbook share button")
        XCTAssertTrue(share.waitForExistence(timeout: 5), "Each cookbook page should have a share button.")
        share.tap()
        let preview = app.descendants(matching: .any).matching(identifier: "cookbook.share.preview").firstMatch
        XCTAssertTrue(preview.waitForExistence(timeout: 10), "Sharing a page should show the picture that gets sent.")
        XCTAssertTrue(app.buttons["cookbook.share.send"].exists, "The share preview should offer Share.")
        settle()
        snap(app, "44-cookbook-share")
        app.buttons["Done"].firstMatch.tap()
        XCTAssertTrue(preview.waitForNonExistence(timeout: 5), "Done should close the share preview.")
        // A page opens its recipe, to cook it again.
        app.descendants(matching: .any).matching(identifier: "cookbook.page").firstMatch.tap()
        XCTAssertTrue(app.buttons["Start Cooking Mode"].waitForExistence(timeout: 10),
                      "Tapping a cookbook page should open the recipe.")

        // Below the cookbook: "Your taste" from the seeded cooks; a trait row opens the recipes behind it.
        checkpoint(app, "back to Me for taste")
        app.navigationBars.buttons.firstMatch.tap()
        let card = app.descendants(matching: .any).matching(identifier: "taste.card").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5), "Cooked meals should show Your taste on Me.")
        // Scroll until the last trait row clears the tab bar, so the shot shows the whole card (hittable alone
        // stops as soon as the card's top edge peeks in).
        let lastRow = app.descendants(matching: .any).matching(identifier: "taste.row.fresh").firstMatch
        let tabBarTop = app.tabBars.firstMatch.frame.minY
        for _ in 0..<6 where !lastRow.exists || lastRow.frame.maxY > tabBarTop { app.swipeUp(velocity: .slow) }
        XCTAssertTrue(app.staticTexts["taste.headline"].exists, "Your taste should say what the cook leans towards.")
        settle()
        snap(app, "48-me-taste")
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'taste.row.'")).firstMatch
        checkpoint(app, "taste row")
        XCTAssertTrue(row.waitForExistence(timeout: 5), "A trait the cook has cooked should open its recipes.")
        // "taste.row.spicy" → the list is titled "Spicy", so the row opened its own trait.
        let trait = row.identifier.replacingOccurrences(of: "taste.row.", with: "").capitalized
        row.tap()
        XCTAssertTrue(app.navigationBars[trait].waitForExistence(timeout: 10),
                      "The \(trait) row should open the \(trait) recipes.")
        XCTAssertTrue(app.buttons["recipe.row"].firstMatch.waitForExistence(timeout: 5),
                      "A taste row should list the recipes behind it.")
        settle()
        snap(app, "48a-me-taste-recipes")

        // Below Your taste: "Your cooking story" from the seeded cooks (a week apart), back to the first cook.
        checkpoint(app, "back to Me for story")
        app.navigationBars.buttons.firstMatch.tap()
        let story = app.descendants(matching: .any).matching(identifier: "story.card").firstMatch
        let firstCook = app.descendants(matching: .any).matching(identifier: "story.row.first-cook").firstMatch
        let tabTop = app.tabBars.firstMatch.frame.minY
        // The seeded story is longer than the preview: open it all, so the oldest moment (the first cook) shows.
        let showAll = app.buttons["story.showAll"]
        for _ in 0..<6 where !showAll.exists || showAll.frame.maxY > tabTop { app.swipeUp(velocity: .slow) }
        XCTAssertTrue(story.waitForExistence(timeout: 5), "Cooked meals should show Your cooking story on Me.")
        checkpoint(app, "story show all")
        if showAll.exists { showAll.tap() }
        for _ in 0..<8 where !firstCook.exists || firstCook.frame.maxY > tabTop { app.swipeUp(velocity: .slow) }
        XCTAssertTrue(firstCook.exists, "The story should start with the first cook.")
        settle()
        snap(app, "49-me-story")
    }

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
