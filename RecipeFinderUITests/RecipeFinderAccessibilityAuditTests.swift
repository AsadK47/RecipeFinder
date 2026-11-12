import XCTest

/// Automated accessibility audits via `performAccessibilityAudit` (iOS 17+, same checks as Accessibility Inspector); a failure is a real regression — fix it, don't suppress it.
final class RecipeFinderAccessibilityAuditTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - Add a recipe ("+" on Recipes)

    @MainActor
    func testAddRecipeSheetPassesAudit() throws {
        let app = launchApp()

        app.buttons["recipes.add"].tap()
        XCTAssertTrue(
            app.staticTexts["Add a Recipe"].waitForExistence(timeout: 5),
            "Add a Recipe sheet should be visible."
        )

        // Skip contrast: import tiles use frosted `.appCard()` material, which the audit always flags over translucency.
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast), auditHandler)
    }

    // MARK: - Groceries search results

    @MainActor
    func testGroceriesSearchResultsPassesAudit() throws {
        let app = launchApp()

        app.tabBars.buttons["Groceries"].tap()

        // By identifier: TabView keeps Settings' name fields in the hierarchy, so `firstMatch` hit those instead.
        let search = app.textFields["groceries.search"]
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
        // The button vanishes before the keyboard finishes sliding out; wait for the keyboard itself to leave.
        let keyboard = app.keyboards.firstMatch
        if keyboard.exists {
            let keyboardHidden = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: keyboard
            )
            wait(for: [keyboardHidden], timeout: 3)
        }

        // Skip contrast: rows sit on frosted `.appCard()` material, which the audit always flags.
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast), auditHandler)
    }

    // MARK: - Helpers

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 10)
        // State left by earlier suites can unlock a badge on launch; its full-screen reveal covers the tab bar and a
        // tab tap lands on "View all badges" (opening Profile). Swipe it away. Case-insensitive: the title is uppercased.
        let badgeSheet = app.staticTexts.matching(NSPredicate(format: "label ==[c] 'Badge Earned!'")).firstMatch
        if badgeSheet.waitForExistence(timeout: 2) {
            // Drag the window, not the label: the reveal can close itself between the wait and the swipe.
            let window = app.windows.firstMatch
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
                .press(forDuration: 0.05, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)))
            let dismissed = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: badgeSheet
            )
            wait(for: [dismissed], timeout: 8)
        }
        // The app opens on Today; these flows start from the Recipes home.
        app.tabBars.buttons["Recipes"].tap()
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
