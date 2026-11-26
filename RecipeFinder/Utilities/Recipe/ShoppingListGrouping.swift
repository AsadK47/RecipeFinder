import Foundation

/// Groups/orders shopping list items and renders the shareable text; extracted from `ShoppingListView` so the logic is testable, not inline in `body`.
enum ShoppingListGrouping {

    // Pre-built rank map eliminates O(C) firstIndex scans inside the sorted comparator.
    private static let categoryRank: [String: Int] = Dictionary(
        uniqueKeysWithValues: CategoryClassifier.categoryOrder.enumerated().map { ($1, $0) }
    )

    /// Groups `items` by category, unchecked before checked within each, groups in the aisle order learned for `store`
    /// (`AisleOrder`), else `CategoryClassifier.categoryOrder` (alphabetical fallback).
    static func grouped(
        _ items: [ShoppingListModel], aisleOrder: AisleOrder = AisleOrder(), store: String? = nil
    ) -> [(key: String, value: [ShoppingListModel])] {
        let usual = usualOrder(items)
        let arranged = aisleOrder.arranged(usual.map(\.key), at: store)
        guard arranged != usual.map(\.key) else { return usual }
        let groups = Dictionary(uniqueKeysWithValues: usual.map { ($0.key, $0.value) })
        return arranged.map { (key: $0, value: groups[$0] ?? []) }
    }

    private static func usualOrder(_ items: [ShoppingListModel]) -> [(key: String, value: [ShoppingListModel])] {
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

    /// What To buy shows at `store`: the items set to it, then the items with no store (bought anywhere). Items set to
    /// other stores stay off. With no store picked (All), every item is in `atStore` and `anywhere` is empty.
    static func split(
        _ items: [ShoppingListModel], at store: String?
    ) -> (atStore: [ShoppingListModel], anywhere: [ShoppingListModel]) {
        guard let store else { return (items, []) }
        // Same rule as `isAvailable(at:)` (progress bar, shop mode), split by whether the item names this store.
        let available = items.filter { $0.isAvailable(at: store) }
        return (available.filter { $0.stores.contains(store) }, available.filter { $0.stores.isEmpty })
    }

    /// The tiers To buy shows: one untitled tier for All or when the store has nothing of its own (or nothing else),
    /// else "At <store>" then "Anywhere". Empty tiers are dropped. One shape for every case, so assigning the first
    /// item doesn't rebuild the whole list.
    static func tiers(_ items: [ShoppingListModel], at store: String?) -> [(title: String?, items: [ShoppingListModel])] {
        let parts = Self.split(items, at: store)
        guard let store, !parts.atStore.isEmpty, !parts.anywhere.isEmpty else {
            let all = parts.atStore + parts.anywhere
            return all.isEmpty ? [] : [(nil, all)]
        }
        return [("At \(store)", parts.atStore), ("Anywhere", parts.anywhere)]
    }

    /// Whether To buy should offer "Choose items" for `store`: it's picked and nothing on the list is set to it yet.
    static func offersChooseItems(_ items: [ShoppingListModel], at store: String?) -> Bool {
        guard let store else { return false }
        return !items.contains { $0.stores.contains(store) }
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
