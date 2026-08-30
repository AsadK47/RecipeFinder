import Foundation

/// Groups and orders shopping list items for display, and renders the shareable
/// text. Extracted from `ShoppingListView` so the logic is unit-testable and no
/// longer computed inline in a SwiftUI `body`.
enum ShoppingListGrouping {

    /// Groups `items` by category, sorts each group so unchecked items come
    /// before checked ones, and orders the groups by `CategoryClassifier.categoryOrder`
    /// (falling back to alphabetical for categories not in that order).
    static func grouped(_ items: [ShoppingListModel]) -> [(key: String, value: [ShoppingListModel])] {
        Dictionary(grouping: items, by: { $0.category })
            .map { (key: $0.key, value: $0.value.sorted { !$0.isChecked && $1.isChecked }) }
            .sorted { first, second in
                guard let firstIndex = CategoryClassifier.categoryOrder.firstIndex(of: first.key),
                      let secondIndex = CategoryClassifier.categoryOrder.firstIndex(of: second.key) else {
                    return first.key < second.key
                }
                return firstIndex < secondIndex
            }
    }

    /// A plain-text rendering of the grouped shopping list, suitable for sharing.
    static func shareText(for groups: [(key: String, value: [ShoppingListModel])]) -> String {
        var text = "🛒 Shopping List\n\n"

        for group in groups {
            text += "\(group.key)\n"
            for item in group.value {
                let checkbox = item.isChecked ? "✓" : "○"
                let qty = item.quantity > 1 ? "(\(item.quantity)) " : ""
                text += "\(checkbox) \(qty)\(item.name)\n"
            }
            text += "\n"
        }

        return text
    }
}
