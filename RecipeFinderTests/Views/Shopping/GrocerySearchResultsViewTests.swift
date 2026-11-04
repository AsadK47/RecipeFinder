import Testing
import SwiftUI
import ViewInspector
@testable import RecipeFinder

/// Fast render-logic tests for the Groceries suggestions view using ViewInspector — proves the feature the
/// slow (flaky) `testGroceriesSearchResultsPassesAudit` UI test relies on, without a simulator. ViewInspector
/// tests "view is a function of its state"; presentation-timing races stay in the XCUITest/logic suites.
@MainActor
@Suite struct GrocerySearchResultsViewTests {

    private func make(searchText: String, results: [String], onAdd: @escaping (String) -> Void = { _ in }) -> GrocerySearchResultsView {
        GrocerySearchResultsView(
            searchText: searchText,
            searchResults: results,
            isInShopping: { _ in false },
            onAddToShopping: onAdd
        )
    }

    @Test("Renders the suggestions header and a row per match")
    func rendersHeaderAndRows() throws {
        let view = try make(searchText: "Ap", results: ["Apple", "Apricot"]).inspect()
        _ = try view.find(text: "Suggested Ingredients")
        _ = try view.find(text: "Apple")
        _ = try view.find(text: "Apricot")
        // A novel (non-matching) query also offers a free-text "Add" row.
        _ = try view.find(text: "Add \"Ap\"")
    }

    @Test("No free-text add row when the query exactly matches a suggestion")
    func noFreeTextRowOnExactMatch() throws {
        let view = try make(searchText: "Apple", results: ["Apple"]).inspect()
        _ = try view.find(text: "Apple")
        #expect(throws: (any Error).self) { try view.find(text: "Add \"Apple\"") }
    }

    @Test("Tapping a suggestion's Add button reports it to the handler")
    func addButtonInvokesHandler() throws {
        var added: String?
        // Exact-match query ⇒ only the single result row renders, so there's exactly one Add button to tap.
        let view = try make(searchText: "Apple", results: ["Apple"], onAdd: { added = $0 }).inspect()
        try view.find(ViewType.Button.self).tap()
        #expect(added == "Apple")
    }
}
