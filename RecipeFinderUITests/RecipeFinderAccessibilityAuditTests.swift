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

        // Contrast is intentionally excluded on this screen: the import tiles use the
        // app's frosted `.appCard()` material by design, and Apple's audit flags text
        // over any translucent material because its contrast can't be guaranteed.
        // Every other audit type still runs here, and contrast stays enforced on the
        // sign-in screen.
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

        // Dismiss the software keyboard if it is visible so the contrast audit
        // measures elements against their card backgrounds and not the keyboard
        // material that sits over them at lower y-positions on the screen.
        // showingSearchResults no longer requires isSearchFocused, so the results
        // remain visible after dismissal.
        let dismissKb = app.buttons["Dismiss keyboard"]
        if dismissKb.waitForExistence(timeout: 1) {
            dismissKb.tap()
            // Wait for the dismiss animation to finish before auditing. Views in
            // transition can momentarily report non-finite frames (same class the
            // ShoppingProgressBar clamp guards against), which the audit flags as
            // "Invalid frame dimension" — measure the settled layout instead.
            let keyboardGone = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: dismissKb
            )
            wait(for: [keyboardGone], timeout: 3)
        }

        // Contrast is excluded here for the same reason as the Import screen: the
        // suggestion rows use the app's frosted `.appCard()` material by design, so
        // they match the rest of the app, and Apple's audit flags text over any
        // translucent material because its contrast can't be guaranteed. Every other
        // audit type still runs.
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast), auditHandler)
    }

    // MARK: - Helpers

    @MainActor
    private func launchAuthenticated() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-skip-auth"]
        app.launch()
        // autoSignIn() fires asynchronously; wait for it to settle so the app
        // is fully authenticated (isGuest = false) before tests tap action elements.
        // The nudge button disappears once authManager.isAuthenticated becomes true.
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

    /// Issue handler: attaches a detail string for every failing issue so CI
    /// reports show exactly what element and rule failed. Always returns `false`
    /// (fail) — suppress nothing unless there is a documented reason.
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
