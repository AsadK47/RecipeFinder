import XCTest

/// Critical-flow UI test: email sign-in.
///
/// Builds on the clean-state launch hooks (`-ui-testing`, `-resetState`; see
/// `RecipeFinderApp.init`). From the signed-out screen, tapping "Sign In with
/// Email", entering the test account credentials, and submitting must land on
/// the main app with its tab bar visible.
///
/// The `-resetState` hook now also sets `hasCompletedOnboarding` and
/// `hasSeenBiometricOnboarding`, so sign-in lands directly on the main content
/// rather than an interstitial onboarding screen.
final class RecipeFinderSignInUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testEmailSignInLandsOnMainApp() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-resetState"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Discover, Create, Cook"].waitForExistence(timeout: 10),
            "A clean-state launch should land on the sign-in screen."
        )

        // Navigate to the email sign-in form.
        let signInLink = app.buttons["auth.showSignIn"]
        XCTAssertTrue(signInLink.waitForExistence(timeout: 5), "Sign In with Email button should exist.")
        signInLink.tap()

        // Fill in the test account credentials (created by AuthTestHelper.ensureTestAccountExists).
        let emailField = app.textFields["signin.email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5), "Email field should appear after navigation.")
        emailField.tap()
        emailField.typeText("test@email.com")

        let passwordField = app.textFields["signin.password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5), "Password field should appear.")
        passwordField.tap()
        passwordField.typeText("Password123!")

        let submitButton = app.buttons["signin.submit"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5), "Sign In button should exist.")
        submitButton.tap()

        // A successful sign-in navigates to the main tab bar.
        XCTAssertTrue(
            app.tabBars.buttons["Recipes"].waitForExistence(timeout: 10),
            "A valid sign-in should land on the main app showing the tab bar."
        )

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Sign In — Main app"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
