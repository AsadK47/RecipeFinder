import XCTest

/// Automated accessibility audits using Apple's `performAccessibilityAudit` API
/// (XCUIAutomation, iOS 17+). Runs the same checks as Accessibility Inspector:
/// contrast, element descriptions, hit regions, Dynamic Type, clipped text,
/// traits, and element detection. A failure here is a real regression — fix it,
/// don't suppress it.
///
/// Screens covered:
///   - Sign-in (auth screen, clean reset state)
///   - Import tab
///   - Groceries tab while a search is active (surfaces GrocerySearchResultsView
///     with its action-icon buttons — the area we just improved for a11y)
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

        try app.performAccessibilityAudit(for: .all, auditHandler)
    }

    // MARK: - Groceries search results

    @MainActor
    func testGroceriesSearchResultsPassesAudit() throws {
        let app = launchAuthenticated()

        app.tabBars.buttons["Groceries"].tap()

        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5), "Groceries search field should exist.")
        search.tap()
        search.typeText("Apple")

        XCTAssertTrue(
            app.staticTexts["Suggested Ingredients"].waitForExistence(timeout: 5),
            "Search suggestions should appear."
        )

        try app.performAccessibilityAudit(for: .all, auditHandler)
    }

    // MARK: - Helpers

    @MainActor
    private func launchAuthenticated() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-skip-auth"]
        app.launch()
        return app
    }

    /// Issue handler: attaches a detail string for every failing issue so CI
    /// reports show exactly what element and rule failed. Always returns `false`
    /// (fail) — suppress nothing unless there is a documented reason.
    private var auditHandler: (XCUIAccessibilityAuditIssue) throws -> Bool {
        { [self] issue in
            let detail = """
            Type:    \(issue.auditType)
            Issue:   \(issue.compactDescription)
            Detail:  \(issue.detailedDescription)
            """
            let attachment = XCTAttachment(string: detail)
            attachment.name = "A11y issue — \(issue.compactDescription)"
            attachment.lifetime = .keepAlways
            add(attachment)
            return false
        }
    }
}
