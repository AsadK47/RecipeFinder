import ConfettiSwiftUI
import SwiftUI

/// "Groceries" tab: a To buy | At home switch over the shopping list and the kitchen (remembered between launches).
struct KitchenShoppingView: View {
    @Environment(\.shopping) var shopping
    @Environment(\.kitchen) var kitchen
    @Environment(\.mealPlanning) var mealPlanning
    @Environment(\.recipeStore) var recipeStore
    @AppStorage(GroceriesMode.modeKey) private var mode: GroceriesMode = GroceriesMode.defaultMode
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var shoppingCollapsed: Set<String> = []
    /// Kept here so typing in the header (which swaps in suggestions) doesn't re-open collapsed kitchen categories.
    @State private var kitchenCollapsed: Set<String> = []
    @State private var confettiTrigger = 0
    @State private var showShoppingQuickAdd = false
    @State private var showClearShopping = false
    @State private var showAddIngredient = false
    @State private var showKitchenQuickAdd = false
    @State private var showClearKitchen = false
    @State private var showManageStores = false
    @State private var assigningStore: GroceryStoreSelection?
    /// What the next seven days of plans still need; refreshed on data change, not in `body`.
    @State var planNeeds = WeekGroceryPlan.empty
    /// Last store filter, remembered between launches; "" means All.
    @AppStorage("groceriesStoreFilter") private var storeFilter = ""


    private var searchResults: [String] {
        guard !searchText.isEmpty else { return [] }
        return FoodsList.searchFoods(query: searchText)
    }

    private var showingSearchResults: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var checkedCount: Int { shopping.items.filter { $0.isChecked }.count }
    private var totalCount: Int { shopping.items.count }

    /// The filter's store, or nil (All) when none is picked or the picked one was renamed/deleted.
    private var activeStore: String? {
        shopping.stores.contains(storeFilter) ? storeFilter : nil
    }
    private var visibleItems: [ShoppingListModel] { shopping.items.filter { $0.isAvailable(at: activeStore) } }
    private var isAllCollapsed: Bool {
        shoppingCollapsed.count == CategoryClassifier.categoryOrder.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    GroceriesHeader(
                        searchText: $searchText,
                        isSearchFocused: $isSearchFocused,
                        placeholder: mode.searchPlaceholder,
                        onSubmit: addTypedItem,
                        menuContent: { overflowMenu }
                    )

                    if GroceriesMode.showsModePicker(isSearching: showingSearchResults) {
                        modePicker
                    }

                    if GroceriesMode.showsStoreFilter(
                        mode: mode, hasStores: !shopping.stores.isEmpty, isSearching: showingSearchResults
                    ) {
                        GroceryStoreFilterBar(
                            stores: shopping.stores,
                            selected: activeStore,
                            onSelect: { storeFilter = $0 ?? "" },
                            onAssign: { assigningStore = GroceryStoreSelection(name: $0) },
                            onManage: { showManageStores = true }
                        )
                    }

                    content
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button { isSearchFocused = false } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .adaptiveSecondaryForeground()
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Dismiss keyboard")
                    }
                }
            }
            .appNavigationChrome()
        }
        .onAppear(perform: refreshPlanNeeds)
        .onChange(of: shopping.items) { refreshPlanNeeds() }
        .onChange(of: kitchen.items) { refreshPlanNeeds() }
        .onChange(of: kitchen.inventoryItems) { refreshPlanNeeds() }
        .onChange(of: recipeStore.recipes.count) { refreshPlanNeeds() }
        .confettiCannon(trigger: $confettiTrigger, num: AppTheme.confettiCount, radius: AppTheme.confettiRadius)
        .onChange(of: checkedCount) { oldValue, newValue in
            // Only celebrate when a check completes the list — `newValue > oldValue` avoids firing when deleting a checked item drops the count onto totalCount.
            if !shopping.items.isEmpty && newValue == totalCount && newValue > oldValue {
                HapticManager.shared.success()
                confettiTrigger += 1
            }
        }
        .confirmationDialog("Clear Groceries", isPresented: $showClearShopping, titleVisibility: .visible) {
            if checkedCount > 0 {
                Button("Clear Checked Items (\(checkedCount))", role: .destructive) { shopping.clearCheckedItems() }
            }
            Button("Clear All Items (\(totalCount))", role: .destructive) { shopping.clearAllItems() }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showShoppingQuickAdd) { ShoppingQuickAddSheet() }
        .confirmationDialog("Clear Kitchen", isPresented: $showClearKitchen, titleVisibility: .visible) {
            Button("Clear All Ingredients", role: .destructive) { kitchen.clearAll() }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showAddIngredient) { AddIngredientSheet() }
        .sheet(isPresented: $showKitchenQuickAdd) { KitchenQuickAddSheet() }
        .sheet(isPresented: $showManageStores) { GroceryStoresSheet() }
        .sheet(item: $assigningStore) { AssignStoreSheet(store: $0.name) }
    }

    @ViewBuilder
    private var content: some View {
        if showingSearchResults {
            GrocerySearchResultsView(
                searchText: searchText,
                searchResults: searchResults,
                listName: mode.listName,
                isAdded: isAdded,
                onAdd: addItemFromSearch
            )
        } else if mode == .atHome {
            KitchenAtHomeView(collapsed: $kitchenCollapsed, onAddIngredient: { showAddIngredient = true })
        } else if shopping.items.isEmpty {
            emptyState
        } else if let activeStore, visibleItems.isEmpty {
            storeEmptyState(activeStore)
        } else {
            shoppingList
        }
    }

    private var shoppingList: some View {
        List {
            if !planNeeds.candidates.isEmpty {
                PlanGroceriesCard(plan: planNeeds, onAdd: addPlanNeeds)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            ShoppingProgressBar(
                checkedCount: visibleItems.filter(\.isChecked).count,
                totalCount: visibleItems.count
            )
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            ShoppingSectionsView(
                collapsedCategories: $shoppingCollapsed,
                store: activeStore,
                onManageStores: { showManageStores = true },
                onShowKitchen: { mode = .atHome }
            )
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .environment(\.defaultMinListHeaderHeight, 0)
        .padding(.top, -6)
    }

    private var emptyState: some View {
        ScrollView {
            if planNeeds.candidates.isEmpty {
                EmptyStateView(
                    icon: "cart.circle.fill",
                    title: "Your groceries list is empty",
                    message: "Search above to add items to your list."
                )
            } else {
                PlanGroceriesCard(plan: planNeeds, onAdd: addPlanNeeds)
                    .padding(.horizontal, AppTheme.cardHorizontalPadding)
            }
        }
    }

    private func storeEmptyState(_ store: String) -> some View {
        ScrollView {
            EmptyStateView(
                icon: "storefront",
                title: "Nothing to buy at \(store)",
                message: "Every item on your list is set to another store.",
                actionTitle: "Choose Items",
                onAction: { assigningStore = GroceryStoreSelection(name: store) }
            )
        }
    }

    private var modePicker: some View {
        Picker("Show", selection: $mode) {
            ForEach(GroceriesMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, AppTheme.cardHorizontalPadding)
        .padding(.bottom, AppTheme.spacing8)
        .accessibilityIdentifier("groceries.mode")
    }

    @ViewBuilder
    private var overflowMenu: some View {
        switch mode {
        case .toBuy: shoppingMenu
        case .atHome: kitchenMenu
        }
    }

    @ViewBuilder
    private var kitchenMenu: some View {
        Button { showAddIngredient = true } label: { Label("Add Ingredient", systemImage: "plus.circle") }
        Button { showKitchenQuickAdd = true } label: { Label("Quick Add", systemImage: "bolt") }
        if !kitchen.items.isEmpty {
            Divider()
            Button(role: .destructive) { showClearKitchen = true } label: {
                Label("Clear Kitchen", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var shoppingMenu: some View {
        Button { showShoppingQuickAdd = true } label: { Label("Quick Add", systemImage: "plus.circle") }
        Button { showManageStores = true } label: { Label("Stores", systemImage: "storefront") }
        Button(action: shareShoppingList) { Label("Share Groceries", systemImage: "square.and.arrow.up") }
        Button(action: toggleCollapseAll) {
            Label(isAllCollapsed ? "Expand All" : "Collapse All",
                  systemImage: isAllCollapsed ? "chevron.down" : "chevron.up")
        }
        Button(role: .destructive) { showClearShopping = true } label: { Label("Clear Groceries", systemImage: "trash") }
    }

    private func isAdded(_ name: String) -> Bool {
        switch mode {
        case .toBuy: GroceriesMode.contains(name, in: shopping.items.map(\.name))
        case .atHome: GroceriesMode.contains(name, in: kitchen.items.map(\.name))
        }
    }

    /// Return in the header field: adds what was typed to the side that's showing.
    private func addTypedItem() {
        add(searchText)
    }

    private func addItemFromSearch(_ ingredient: String) {
        guard !isAdded(ingredient) else { return }
        add(ingredient)
    }

    private func add(_ text: String) {
        switch mode.add(text, kitchenNames: kitchen.items.map(\.name)) {
        case .shopping(let name):
            shopping.addItem(name: name)
            HapticManager.shared.success()
        case .kitchen(let name):
            // The kitchen plays its own add haptic.
            kitchen.toggleItem(name, category: nil)
        case .alreadyInKitchen:
            // Nothing added: keep the text so the suggestions show it as "Already in kitchen".
            HapticManager.shared.warning()
            return
        case .nothing:
            return
        }
        searchText = ""
        isSearchFocused = false
    }

    private func toggleCollapseAll() {
        if isAllCollapsed {
            shoppingCollapsed.removeAll()
        } else {
            shoppingCollapsed = Set(CategoryClassifier.categoryOrder)
        }
    }

    private func shareShoppingList() {
        let text = ShoppingListGrouping.shareText(for: ShoppingListGrouping.grouped(shopping.items))

        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }

        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }

        let activityController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let popover = activityController.popoverPresentationController {
            let viewBounds = topController.view.bounds
            popover.sourceView = topController.view
            popover.sourceRect = CGRect(x: viewBounds.midX, y: viewBounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        topController.present(activityController, animated: true)
    }
}

#Preview {
    KitchenShoppingView()
}
