import XCTest

/// Critical-flow launch test: a launch must land straight on the recipe list (no gate or splash in front of it) — the smallest
/// proof that launch works before other UI tests build on it.
final class RecipeFinderLaunchUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        // A launch failure invalidates everything after it — stop immediately.
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchLandsOnRecipeList() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()

        let recipesTab = app.tabBars.buttons["Recipes"]
        XCTAssertTrue(recipesTab.waitForExistence(timeout: 10), "Launch should land on the main tabs.")
        XCTAssertTrue(recipesTab.isSelected, "The Recipes tab should be selected on launch.")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Launch — Recipe list"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
