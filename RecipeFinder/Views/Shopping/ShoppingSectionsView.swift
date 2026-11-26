import SwiftUI

/// Shopping list as bare `List` `Section`s (no own `List`/title) so Groceries hosts it in one scroll; row actions go straight to `ShoppingListManager.shared`.
struct ShoppingSectionsView: View {
    @Binding var collapsedCategories: Set<String>
    /// Store being shopped at; nil shows every item.
    let store: String?
    let onManageStores: () -> Void
    /// Switches Groceries to At home (the rows' "In kitchen" tag).
    var onShowKitchen: (() -> Void)?

    @Environment(\.shopping) private var manager
    @Environment(\.kitchen) private var kitchen

    /// Lowercased kitchen item names so each shopping row can flag "you already have this".
    private var kitchenNameSet: Set<String> {
        Set(kitchen.items.map { $0.name.lowercased() })
            .union(kitchen.inventoryItems.map { $0.name.lowercased() })
    }

    private func grouped(_ items: [ShoppingListModel]) -> [(key: String, value: [ShoppingListModel])] {
        ShoppingListGrouping.grouped(items, aisleOrder: manager.aisleOrder, store: store)
    }

    var body: some View {
        let split = ShoppingListGrouping.split(manager.items, at: store)
        if let store, !split.atStore.isEmpty, !split.anywhere.isEmpty {
            // A picked store leads with what's set to it, so the filter visibly changes the list.
            tierTitle("At \(store)")
            sections(split.atStore)
            tierTitle("Anywhere")
            sections(split.anywhere)
        } else {
            sections(split.atStore + split.anywhere)
        }
    }

    private func sections(_ items: [ShoppingListModel]) -> some View {
        ForEach(grouped(items), id: \.key) { group in
            categorySection(for: group.key, items: group.value)
        }
    }

    private func tierTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .adaptiveForegroundColor()
            .accessibilityAddTraits(.isHeader)
            .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 4, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private func categorySection(for category: String, items: [ShoppingListModel]) -> some View {
        Section {
            if !collapsedCategories.contains(category) {
                rowList(items)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        } header: {
            GroceryCategoryHeader(
                category: category, count: GroceryCategoryHeader.remainingCount(items), collapsed: $collapsedCategories
            )
        }
    }

    @ViewBuilder
    private func rowList(_ items: [ShoppingListModel]) -> some View {
        ForEach(items) { item in
            ShoppingListItemRow(
                item: item,
                isInKitchen: kitchenNameSet.contains(item.name.lowercased()),
                onToggle: {
                    if let index = manager.items.firstIndex(where: { $0.id == item.id }) {
                        manager.toggleItem(at: index)
                    }
                },
                onQuantityChange: { newQuantity in
                    if let index = manager.items.firstIndex(where: { $0.id == item.id }) {
                        manager.updateQuantity(at: index, quantity: newQuantity)
                    }
                },
                onDelete: {
                    if let index = manager.items.firstIndex(where: { $0.id == item.id }) {
                        manager.deleteItem(at: index)
                    }
                },
                onCategoryChange: { newCategory in
                    if let index = manager.items.firstIndex(where: { $0.id == item.id }) {
                        manager.updateCategory(at: index, category: newCategory)
                    }
                },
                availableStores: manager.stores,
                onToggleStore: { store in
                    manager.setStore(store, assigned: !item.stores.contains(store), forItemIDs: [item.id])
                },
                onManageStores: onManageStores,
                onToggleRecurring: {
                    if let index = manager.items.firstIndex(where: { $0.id == item.id }) {
                        manager.toggleRecurring(at: index)
                    }
                },
                allCategories: CategoryClassifier.categoryOrder,
                onShowKitchen: onShowKitchen
            )
            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }
}
