import XCTest

/// Critical-flow UI test: email sign-up lands on the welcome screen.
/// Under `-ui-testing` password fields render as plain `TextField`s (AutoFill can't cap manual entry), so they're queried as `textFields`, not `secureTextFields`.
final class RecipeFinderSignUpUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testEmailSignUpLandsOnWelcomeScreen() {
        let app = XCUIApplication()
        // `-force-auth-ui` overrides the guest-only AuthUIGate so this test still exercises the
        // (otherwise hidden) sign-up flow. Remove it when AuthUIGate.showAuthUI becomes the default.
        app.launchArguments += ["-ui-testing", "-resetState", "-force-auth-ui"]
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
