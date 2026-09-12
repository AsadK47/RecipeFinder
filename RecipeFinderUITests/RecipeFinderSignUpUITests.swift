import XCTest

/// Critical-flow UI test: email sign-up.
///
/// Builds on the clean-state launch hooks (`-ui-testing`, `-resetState`; see
/// `RecipeFinderApp.init`). From the signed-out screen, opening Sign Up, filling
/// a valid new account, and submitting must land on the welcome screen that only
/// appears after `signUpWithoutLogin` succeeds.
///
/// Note: under `-ui-testing` the password fields render as plain `TextField`s
/// (SignUpView) so iOS's new-password AutoFill can't cap manual entry — hence the
/// password/confirm fields are queried as `textFields`, not `secureTextFields`.
final class RecipeFinderSignUpUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testEmailSignUpLandsOnWelcomeScreen() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-resetState"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Discover, Create, Cook"].waitForExistence(timeout: 10),
            "A clean-state launch should land on the sign-in screen."
        )

        app.buttons["auth.showSignUp"].tap()

        let fullName = app.textFields["signup.fullName"]
        XCTAssertTrue(fullName.waitForExistence(timeout: 5), "Sign Up sheet should present.")

        // Unique email keeps the run independent; -resetState also wipes the keychain.
        let email = "uitest-\(UUID().uuidString.prefix(8))@email.com"

        func type(_ id: String, _ text: String) {
            let field = app.textFields[id]
            field.tap()
            field.typeText(text)
        }

        type("signup.fullName", "UI Tester")
        type("signup.email", email)
        type("signup.password", "Password123!")
        type("signup.confirmPassword", "Password123!")

        let submit = app.buttons["signup.submit"]
        XCTAssertTrue(submit.waitForExistence(timeout: 5), "Create Account button should exist.")
        if !submit.isHittable { app.swipeUp() }
        submit.tap()

        // WelcomeSplashView only appears after a successful sign-up.
        XCTAssertTrue(
            app.staticTexts["Account created successfully"].waitForExistence(timeout: 10),
            "A valid sign-up should land on the welcome screen."
        )

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Sign Up — Welcome screen"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
