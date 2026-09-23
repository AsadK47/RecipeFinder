import Foundation

/// Groups and orders shopping list items for display, and renders the shareable
/// text. Extracted from `ShoppingListView` so the logic is unit-testable and no
/// longer computed inline in a SwiftUI `body`.
enum ShoppingListGrouping {

    // Pre-built rank map eliminates O(C) firstIndex scans inside the sorted comparator.
    private static let categoryRank: [String: Int] = Dictionary(
        uniqueKeysWithValues: CategoryClassifier.categoryOrder.enumerated().map { ($1, $0) }
    )

    /// Groups `items` by category, sorts each group so unchecked items come
    /// before checked ones, and orders the groups by `CategoryClassifier.categoryOrder`
    /// (falling back to alphabetical for categories not in that order).
    static func grouped(_ items: [ShoppingListModel]) -> [(key: String, value: [ShoppingListModel])] {
        Dictionary(grouping: items, by: { $0.category })
            .map { (key: $0.key, value: $0.value.sorted { !$0.isChecked && $1.isChecked }) }
            .sorted { first, second in
                switch (categoryRank[first.key], categoryRank[second.key]) {
                case let (f?, s?): return f < s
                case (_?, nil):   return true
                case (nil, _?):   return false
                case (nil, nil):  return first.key < second.key
                }
            }
    }

    /// A plain-text rendering of the grouped shopping list, suitable for sharing.
    static func shareText(for groups: [(key: String, value: [ShoppingListModel])]) -> String {
        var text = "🛒 Groceries\n\n"

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
