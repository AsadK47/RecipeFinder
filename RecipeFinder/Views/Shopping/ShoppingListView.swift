import ConfettiSwiftUI
import SwiftUI

private let logger = AppLogger.logger(category: "ShoppingList")

struct ShoppingListView: View {
    @StateObject private var manager = ShoppingListManager.shared
    @State private var searchText: String = ""
    @State private var showClearConfirmation = false
    @State private var showQuickAdd = false
    @State private var collapsedCategories: Set<String> = []
    @State private var confettiTrigger = 0
    @StateObject private var kitchen = KitchenInventoryManager.shared
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    private var sortedGroupedItems: [(key: String, value: [ShoppingListModel])] {
        ShoppingListGrouping.grouped(manager.items)
    }

    private var searchResults: [String] {
        guard !searchText.isEmpty else { return [] }
        return FoodsList.searchFoods(query: searchText)
    }

    private var showingSearchResults: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty && isSearchFocused
    }

    private var checkedCount: Int {
        manager.items.filter { $0.isChecked }.count
    }

    private var totalCount: Int {
        manager.items.count
    }

    private var isAllCollapsed: Bool {
        collapsedCategories.count == CategoryClassifier.categoryOrder.count
    }

    private func shareShoppingList() {
        let text = ShoppingListGrouping.shareText(for: sortedGroupedItems)

        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }

        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }

        let activityController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        if let popover = activityController.popoverPresentationController {
            popover.sourceView = topController.view
            popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        topController.present(activityController, animated: true)
    }

    var body: some View {
        // Hosted inside `KitchenShoppingView`'s NavigationStack; use a passthrough
        // Group so there's a single navigation container for the merged tab.
        Group {
            ZStack {
                VStack(spacing: 0) {
                    ShoppingListHeader(
                        searchText: $searchText,
                        isSearchFocused: $isSearchFocused,
                        hasItems: !manager.items.isEmpty,
                        isAllCollapsed: isAllCollapsed,
                        cardStyle: cardStyle,
                        colorScheme: colorScheme,
                        onQuickAdd: { showQuickAdd = true },
                        onShare: shareShoppingList,
                        onToggleCollapseAll: toggleCollapseAll,
                        onClearItems: { showClearConfirmation = true },
                        onSubmit: addItem
                    )

                    if !manager.items.isEmpty && !showingSearchResults {
                        ShoppingProgressBar(
                            checkedCount: checkedCount,
                            totalCount: totalCount,
                            selectedTheme: selectedTheme
                        )
                    }

                    if showingSearchResults {
                        ShoppingSearchResultsView(
                            searchText: searchText,
                            searchResults: searchResults,
                            isInList: { ingredient in
                                manager.items.contains { $0.name.lowercased() == ingredient.lowercased() }
                            },
                            onAdd: addItemFromSearch,
                            selectedTheme: selectedTheme,
                            cardStyle: cardStyle,
                            colorScheme: colorScheme
                        )
                    } else {
                        if manager.items.isEmpty {
                            emptyStateView
                        } else {
                            shoppingListContent
                        }
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button {
                            isSearchFocused = false
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .confettiCannon(
                trigger: $confettiTrigger,
                num: AppTheme.confettiCount,
                radius: AppTheme.confettiRadius
            )
            .onChange(of: checkedCount) { _, newValue in
                if !manager.items.isEmpty && newValue == totalCount {
                    HapticManager.shared.success()
                    confettiTrigger += 1
                }
            }
            .confirmationDialog("Clear Items", isPresented: $showClearConfirmation) {
                if checkedCount > 0 {
                    Button("Clear Checked Items (\(checkedCount))", role: .destructive) {
                        manager.clearCheckedItems()
                    }
                }
                Button("Clear All Items (\(totalCount))", role: .destructive) {
                    manager.clearAllItems()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose which items to remove from your shopping list")
            }
            .sheet(isPresented: $showQuickAdd) {
                ShoppingQuickAddSheet()
            }
        }
    }

    private func toggleCollapseAll() {
        if isAllCollapsed {
            collapsedCategories.removeAll()
        } else {
            collapsedCategories = Set(CategoryClassifier.categoryOrder)
        }
    }

    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing16) {
                Image(systemName: "cart.circle.fill")
                    .font(.system(size: AppTheme.fontSize60))
                    .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)

                Text("Start Your Shopping List")
                    .font(.title2)
                    .fontWeight(.bold)
                    .adaptiveForegroundColor()

                Text("Add items to begin shopping")
                    .font(.subheadline)
                    .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.spacing32)
            }
            .padding(.top, AppTheme.spacing40)
        }
    }

    private var shoppingListContent: some View {
        List {
            ForEach(sortedGroupedItems, id: \.key) { group in
                categorySection(for: group.key, items: group.value)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .environment(\.defaultMinListHeaderHeight, 0)
        .padding(.top, -6)
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
                cardStyle: cardStyle,
                colorScheme: colorScheme,
                onToggle: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
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
                onStoreChange: { newStore in
                    if let index = manager.items.firstIndex(where: { $0.id == item.id }) {
                        manager.updateStore(at: index, store: newStore)
                    }
                },
                allCategories: CategoryClassifier.categoryOrder
            )
            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }

    private func addItem() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            logger.error("❌ ShoppingListView: Empty search text")
            return
        }
        logger.debug("🔍 ShoppingListView: Adding item '\(searchText)'")
        manager.addItem(name: searchText)
        searchText = ""
        isSearchFocused = false
        HapticManager.shared.success()
        logger.debug("📊 ShoppingListView: Manager now has \(manager.items.count) items")
    }

    private func addItemFromSearch(_ ingredient: String) {
        logger.debug("🔍 ShoppingListView: Adding item from search '\(ingredient)'")
        manager.addItem(name: ingredient)
        searchText = ""
        isSearchFocused = true
        HapticManager.shared.success()
        logger.debug("📊 ShoppingListView: Manager now has \(manager.items.count) items")
    }

    /// Names the user already has in their kitchen (quick items + inventory),
    /// lowercased, so each shopping row can persistently flag "you already have
    /// this" — clearer and more durable than a transient toast.
    private var kitchenNameSet: Set<String> {
        Set(kitchen.items.map { $0.name.lowercased() })
            .union(kitchen.inventoryItems.map { $0.name.lowercased() })
    }
}
