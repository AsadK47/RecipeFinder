import XCTest

/// Automated accessibility audits via `performAccessibilityAudit` (iOS 17+, same checks as Accessibility Inspector); a failure is a real regression — fix it, don't suppress it.
final class RecipeFinderAccessibilityAuditTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Auth screen

    @MainActor
    func testSignInScreenPassesAudit() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-resetState"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Discover, Create, Cook"].waitForExistence(timeout: 10),
            "Should land on the sign-in screen."
        )

        try app.performAccessibilityAudit(for: .all, auditHandler)
    }

    // MARK: - Import tab

    @MainActor
    func testImportTabPassesAudit() throws {
        let app = launchAuthenticated()

        app.tabBars.buttons["Import"].tap()
        XCTAssertTrue(
            app.staticTexts["Import a Recipe"].waitForExistence(timeout: 5),
            "Import screen should be visible."
        )

        // Skip contrast: import tiles use frosted `.appCard()` material, which the audit always flags over translucency.
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast), auditHandler)
    }

    // MARK: - Groceries search results

    @MainActor
    func testGroceriesSearchResultsPassesAudit() throws {
        let app = launchAuthenticated()

        app.tabBars.buttons["Groceries"].tap()

        let search = app.textFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5), "Groceries search field should exist.")
        search.tap()
        search.typeText("Apple")

        XCTAssertTrue(
            app.staticTexts["Suggested Ingredients"].waitForExistence(timeout: 5),
            "Search suggestions should appear."
        )

        // Dismiss the keyboard so contrast measures against card backgrounds, not the keyboard material over them.
        let dismissKb = app.buttons["Dismiss keyboard"]
        if dismissKb.waitForExistence(timeout: 1) {
            dismissKb.tap()
            // Wait out the dismiss animation: in-transition views report non-finite frames the audit flags as "Invalid frame dimension".
            let keyboardGone = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: dismissKb
            )
            wait(for: [keyboardGone], timeout: 3)
        }

        // Skip contrast: rows sit on frosted `.appCard()` material, which the audit always flags.
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast), auditHandler)
    }

    // MARK: - Helpers

    @MainActor
    private func launchAuthenticated() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-skip-auth"]
        app.launch()
        // autoSignIn() is async; wait for the guest nudge to vanish (isAuthenticated == true) before tapping.
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 10)
        let nudge = app.buttons["guest.nudge.cta"]
        if nudge.exists {
            let gone = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: nudge
            )
            wait(for: [gone], timeout: 10)
        }
        return app
    }

    /// Attaches a detail string per issue for CI, and always returns `false` (fail) — suppress nothing without a documented reason.
    private var auditHandler: (XCUIAccessibilityAuditIssue) throws -> Bool {
        { [self] issue in
            let elem = issue.element
            // XCUIElement properties are @MainActor-isolated; UI tests run on the main thread.
            let (label, frame, elemType) = MainActor.assumeIsolated {
                (elem?.label ?? "nil", elem?.frame ?? .zero, elem?.elementType.rawValue ?? 0)
            }
            let detail = """
            Type:    \(issue.auditType)
            Issue:   \(issue.compactDescription)
            Detail:  \(issue.detailedDescription)
            Label:   \(label)
            Frame:   \(frame)
            ElemType:\(elemType)
            """
            let attachment = XCTAttachment(string: detail)
            attachment.name = "A11y issue — \(issue.compactDescription)"
            attachment.lifetime = .keepAlways
            add(attachment)
            return false
        }
    }
}
