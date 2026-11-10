import XCTest

/// Critical-flow launch test: a launch must land straight on Today (no gate or splash in front of it) — the smallest
/// proof that launch works before other UI tests build on it.
final class RecipeFinderLaunchUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        // A launch failure invalidates everything after it — stop immediately.
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchLandsOnToday() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()

        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.waitForExistence(timeout: 10), "Launch should land on the main tabs.")
        XCTAssertTrue(todayTab.isSelected, "The Today tab should be selected on launch.")

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Launch — Today"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
