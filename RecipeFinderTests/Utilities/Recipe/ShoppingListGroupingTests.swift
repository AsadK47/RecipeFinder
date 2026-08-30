import Testing
import Foundation
@testable import RecipeFinder

@Suite("ShoppingListGrouping")
struct ShoppingListGroupingTests {

    private func item(_ name: String, category: String, checked: Bool = false) -> ShoppingListModel {
        ShoppingListModel(name: name, isChecked: checked, category: category)
    }

    @Test("Items are grouped by category")
    func groupsByCategory() {
        let cat = CategoryClassifier.categoryOrder.first ?? "Other"
        let groups = ShoppingListGrouping.grouped([
            item("A", category: cat),
            item("B", category: cat)
        ])

        #expect(groups.count == 1)
        #expect(groups.first?.key == cat)
        #expect(groups.first?.value.count == 2)
    }

    @Test("Within a group, unchecked items come before checked ones")
    func uncheckedBeforeChecked() {
        let cat = CategoryClassifier.categoryOrder.first ?? "Other"
        let groups = ShoppingListGrouping.grouped([
            item("Checked", category: cat, checked: true),
            item("Unchecked", category: cat, checked: false)
        ])

        let names = groups.first?.value.map { $0.name }
        #expect(names == ["Unchecked", "Checked"])
    }

    @Test("Groups are ordered by the category order")
    func ordersGroupsByCategoryOrder() throws {
        try #require(CategoryClassifier.categoryOrder.count >= 2)
        let earlier = CategoryClassifier.categoryOrder[0]
        let later = CategoryClassifier.categoryOrder[1]

        // Supply them out of order to prove the grouping re-orders them.
        let groups = ShoppingListGrouping.grouped([
            item("Late", category: later),
            item("Early", category: earlier)
        ])

        #expect(groups.map { $0.key } == [earlier, later])
    }

    @Test("Categories outside the known order fall back to alphabetical")
    func unknownCategoriesSortAlphabetically() {
        // Two categories very unlikely to be in categoryOrder.
        let groups = ShoppingListGrouping.grouped([
            item("Z", category: "ZZZ_Unknown"),
            item("A", category: "AAA_Unknown")
        ])

        #expect(groups.map { $0.key } == ["AAA_Unknown", "ZZZ_Unknown"])
    }

    // MARK: - shareText

    @Test("Share text renders each category with checkboxes and quantities")
    func shareTextRendersItems() {
        let groups = ShoppingListGrouping.grouped([
            item("Milk", category: "Dairy", checked: true),
            ShoppingListModel(name: "Apples", isChecked: false, quantity: 3, category: "Dairy")
        ])

        let text = ShoppingListGrouping.shareText(for: groups)

        #expect(text.hasPrefix("🛒 Shopping List\n\n"))
        #expect(text.contains("Dairy\n"))
        #expect(text.contains("○ (3) Apples\n"))
        #expect(text.contains("✓ Milk\n"))
    }
}
