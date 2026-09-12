import XCTest

/// Critical-flow launch test.
///
/// Exercises the app's UI-test launch hooks (`-ui-testing`, `-resetState`; see
/// `RecipeFinderApp.init`): a clean-state launch must wipe persisted auth and
/// land on the signed-out authentication screen. This is the smallest end-to-end
/// proof that launch + reset works before the sign-in and import UI tests build
/// on top of it.
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

        // The tagline is unique to the signed-out auth screen, so its presence
        // proves the reset dropped us to a clean, logged-out state.
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
