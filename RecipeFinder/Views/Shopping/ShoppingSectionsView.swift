import SwiftUI

/// Shopping list as bare `List` `Section`s (no own `List`/title) so Groceries hosts it in one scroll; row actions go straight to `ShoppingListManager.shared`.
struct ShoppingSectionsView: View {
    @Binding var collapsedCategories: Set<String>
    /// Store being shopped at; nil shows every item.
    let store: String?
    let onManageStores: () -> Void

    @Environment(\.shopping) private var manager
    @Environment(\.kitchen) private var kitchen

    /// Lowercased kitchen item names so each shopping row can flag "you already have this".
    private var kitchenNameSet: Set<String> {
        Set(kitchen.items.map { $0.name.lowercased() })
            .union(kitchen.inventoryItems.map { $0.name.lowercased() })
    }

    private var groupedItems: [(key: String, value: [ShoppingListModel])] {
        ShoppingListGrouping.grouped(manager.items.filter { $0.isAvailable(at: store) })
    }

    var body: some View {
        ForEach(groupedItems, id: \.key) { group in
            categorySection(for: group.key, items: group.value)
        }
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
            ShoppingCategoryHeader(
                category: category,
                items: items,
                isCollapsed: collapsedCategories.contains(category),
                onToggle: {
                    withAnimation(.appSpring) {
                        if collapsedCategories.contains(category) {
                            collapsedCategories.remove(category)
                        } else {
                            collapsedCategories.insert(category)
                        }
                    }
                }
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
                allCategories: CategoryClassifier.categoryOrder
            )
            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }
}
