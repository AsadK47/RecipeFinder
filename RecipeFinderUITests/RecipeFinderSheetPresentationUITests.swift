import XCTest

/// Regression guard: data-carrying sheets must open at the correct content on *first* present (`.sheet(item:)`),
/// not a stale full form — proven here via the recipe-detail cook-time editor opening focused on "Details".
/// Drives the real app because the defect is SwiftUI presentation timing that unit tests structurally can't exercise.
final class RecipeFinderSheetPresentationUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Launches the app and waits for the main tab bar.
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

    /// Matches an element by accessibility identifier regardless of its element type.
    @MainActor
    private func element(_ app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// Taps once the element exists and settles. On a cold boot the first recipe row can be on-screen but
    /// momentarily report non-hittable (async image/layout settle); wait for hittability, then fall back to a
    /// coordinate tap. Not masking — a wrong tap (e.g. a real overlay) still fails the later assertions.
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

    /// Bug class A: the FIRST tap of the cook-time card must open the editor focused on "Details", not the full
    /// unfocused "Edit Recipe" form. The old `.sheet(isPresented:)` + separate state rendered the full editor on
    /// first present; `.sheet(item:)` fixes it. This is the exact user-reported symptom.
    @MainActor
    func testCookTimeEditorOpensFocusedOnFirstPresent() {
        let app = launchApp()

        tapWhenReady(element(app, id: "recipe.row"), "Recipes home should list at least one recipe.")

        let timeCard = element(app, id: "recipe.card.time")
        XCTAssertTrue(timeCard.waitForExistence(timeout: 10), "Recipe detail should show the editable time card.")
        timeCard.tap()
        checkpoint(app, "after tapping cook time")

        XCTAssertTrue(app.navigationBars["Details"].waitForExistence(timeout: 5),
                      "First tap of cook time should open the editor focused on Details.")
        XCTAssertFalse(app.navigationBars["Edit Recipe"].exists,
                       "First present must not show the full unfocused editor (the stale-first-render bug).")

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Cook-time editor — focused Details on first open"
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// Tester feedback 1: cuisine is edited with the other facts (Details), shows as a chip under the title, and the
    /// chip opens the Recipes list filtered to that cuisine. Uses the seed's first row, so later shots may show it.
    @MainActor
    func testCuisineChipOpensRecipesFilteredToThatCuisine() {
        let app = launchApp()

        tapWhenReady(element(app, id: "recipe.row"), "Recipes home should list at least one recipe.")
        tapWhenReady(element(app, id: "recipe.card.time"), "Recipe detail should show the editable facts card.")
        XCTAssertTrue(app.navigationBars["Details"].waitForExistence(timeout: 5), "Facts card should open Details.")

        let field = app.textFields["wizard.cuisine"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Details should include the cuisine field.")
        for _ in 0..<3 where !field.isHittable { app.swipeUp() }
        tapWhenReady(field, "Cuisine field should be reachable.")
        // A rerun on the same simulator finds last run's cuisine saved; clear it rather than append.
        if let existing = field.value as? String, !existing.isEmpty, existing != field.placeholderValue {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count))
        }
        field.typeText("American")
        checkpoint(app, "after typing cuisine")
        tapWhenReady(app.navigationBars["Details"].buttons["Update"], "Focused editor should offer Update.")

        let chip = app.buttons["recipe.cuisineChip"]
        tapWhenReady(chip, "Recipe should show its cuisine as a chip after saving.")
        checkpoint(app, "after tapping cuisine chip")

        XCTAssertTrue(chip.waitForNonExistence(timeout: 5), "The chip should leave the recipe for the Recipes list.")
        let activeFilter = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "American")).firstMatch
        XCTAssertTrue(activeFilter.waitForExistence(timeout: 5),
                      "Recipes should show the cuisine as an active filter.")
        XCTAssertTrue(element(app, id: "recipe.row").waitForExistence(timeout: 5),
                      "The filtered list should include the recipe just tagged.")
    }

    /// Kitchen you can find (owner 2026-11-17): the kitchen is one tap from Groceries, and the header field adds to it.
    @MainActor
    func testGroceriesReachesAtHomeInOneTap() {
        let app = launchApp()
        app.tabBars.buttons["Groceries"].tap()

        let atHome = app.buttons["At home"]
        tapWhenReady(atHome, "Groceries should offer an At home switch at the top.")
        checkpoint(app, "after tapping At home")
        XCTAssertTrue(element(app, id: "groceries.atHome").waitForExistence(timeout: 5),
                      "One tap on At home should show the kitchen.")

        // A name unique to this test, so a rerun on a shared simulator finds it already there rather than toggled off.
        let field = app.textFields["groceries.search"]
        tapWhenReady(field, "The header field should be there on At home.")
        field.typeText("Saffron threads\n")
        checkpoint(app, "after adding to the kitchen")
        // The suggestions echo what was typed ("Add \"Saffron threads\""); they close only once the add went through.
        XCTAssertTrue(app.staticTexts["Suggested Ingredients"].waitForNonExistence(timeout: 5),
                      "Return on At home should add the item and close the suggestions.")
        let added = app.staticTexts["Saffron threads"]
        XCTAssertTrue(added.waitForExistence(timeout: 5), "The new item should be listed in the kitchen.")

        // Leave the shared simulator's kitchen as it was (later screenshots and Today shelves read it).
        added.swipeLeft()
        let delete = app.buttons["Delete"]
        if delete.waitForExistence(timeout: 2) { delete.tap() }
        checkpoint(app, "after removing the test item")

        tapWhenReady(app.buttons["To buy"], "The switch should lead back to the shopping list.")
        XCTAssertTrue(element(app, id: "groceries.atHome").waitForNonExistence(timeout: 5),
                      "To buy should show the shopping list, not the kitchen.")
    }

    /// Inbox 🟡 (2026-11-16): Today's "Keep browsing →" must leave a recipe opened on Recipes, not land on it.
    /// Rows push with destination links outside `navigationPath`, so clearing the path alone left the recipe up.
    @MainActor
    func testKeepBrowsingPopsAnOpenRecipe() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-seed-tonight-plan"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15), "App should reach the main tabs.")
        dismissBadgeSheet(app)
        app.tabBars.buttons["Recipes"].tap()

        tapWhenReady(element(app, id: "recipe.row"), "Recipes home should list at least one recipe.")
        let detailMenu = app.buttons["More actions"]
        XCTAssertTrue(detailMenu.waitForExistence(timeout: 10), "Tapping a row should open the recipe.")

        app.tabBars.buttons["Today"].tap()
        let keepBrowsing = element(app, id: "today.keepBrowsing")
        XCTAssertTrue(keepBrowsing.waitForExistence(timeout: 10), "Today's Tonight card should offer Keep browsing.")
        for _ in 0..<3 where !keepBrowsing.isHittable { app.swipeUp() }
        tapWhenReady(keepBrowsing, "Keep browsing should be reachable.")
        checkpoint(app, "after Keep browsing")

        let recipesTab = app.tabBars.buttons["Recipes"]
        XCTAssertEqual(XCTWaiter().wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isSelected == true"), object: recipesTab)], timeout: 5), .completed,
                       "Keep browsing should open Recipes.")
        XCTAssertTrue(detailMenu.waitForNonExistence(timeout: 5),
                      "Keep browsing should pop the open recipe back to the top of Recipes.")
    }

    /// A badge earned at launch (seeding a plan can unlock one) would cover the tabs; drag it away if it shows.
    @MainActor
    private func dismissBadgeSheet(_ app: XCUIApplication) {
        let badgeSheet = app.staticTexts.matching(NSPredicate(format: "label ==[c] 'Badge Earned!'")).firstMatch
        if badgeSheet.waitForExistence(timeout: 3) {
            let window = app.windows.firstMatch
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
                .press(forDuration: 0.05, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)))
            XCTAssertTrue(badgeSheet.waitForNonExistence(timeout: 5), "The badge sheet should close.")
        }
    }

    /// Delete must be reachable from the detail screen, not only via the list's long-press. Asserts the menu item
    /// exists only — tapping it could delete a real recipe if "don't ask again" was persisted.
    @MainActor
    func testRecipeDetailMenuOffersDelete() {
        let app = launchApp()

        tapWhenReady(element(app, id: "recipe.row"), "Recipes home should list at least one recipe.")
        tapWhenReady(app.buttons["More actions"], "Recipe detail should show the overflow menu.")
        checkpoint(app, "after More actions")

        XCTAssertTrue(app.buttons["Delete Recipe"].waitForExistence(timeout: 5),
                      "Detail overflow menu should offer Delete Recipe.")
    }
}
