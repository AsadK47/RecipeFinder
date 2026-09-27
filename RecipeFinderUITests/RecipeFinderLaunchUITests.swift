import XCTest

/// Critical-flow launch test: a clean-state launch (`-resetState`) must wipe
/// persisted auth and land on the signed-out screen. Smallest end-to-end proof
/// that launch + reset works, before the other UI tests build on it.
final class RecipeFinderLaunchUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        // A launch failure invalidates everything after it — stop immediately.
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchLandsOnSignInScreen() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-resetState"]
        app.launch()

        // Tagline is unique to the signed-out screen, so its presence proves the reset dropped us to a clean state.
        let tagline = app.staticTexts["Discover, Create, Cook"]
        XCTAssertTrue(
            tagline.waitForExistence(timeout: 10),
            "A clean-state launch should land on the sign-in screen."
        )

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Launch — Sign In screen"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
