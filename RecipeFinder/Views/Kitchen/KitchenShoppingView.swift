import ConfettiSwiftUI
import SwiftUI

/// "Groceries" tab: focused shopping list; kitchen inventory tucked behind the header fridge button so it doesn't compete for space.
struct KitchenShoppingView: View {
    @Environment(\.shopping) private var shopping
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var shoppingCollapsed: Set<String> = []
    @State private var confettiTrigger = 0
    @State private var showShoppingQuickAdd = false
    @State private var showClearShopping = false
    @State private var showKitchenSheet = false

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    private var searchResults: [String] {
        guard !searchText.isEmpty else { return [] }
        return FoodsList.searchFoods(query: searchText)
    }

    private var showingSearchResults: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var checkedCount: Int { shopping.items.filter { $0.isChecked }.count }
    private var totalCount: Int { shopping.items.count }
    private var isAllCollapsed: Bool {
        shoppingCollapsed.count == CategoryClassifier.categoryOrder.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    GroceriesHeader(
                        searchText: $searchText,
                        isSearchFocused: $isSearchFocused,
                        onSubmit: addShoppingItem,
                        menuContent: { overflowMenu }
                    )

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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
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
        .sheet(isPresented: $showKitchenSheet) { KitchenInventorySheet() }
    }

    @ViewBuilder
    private var content: some View {
        if showingSearchResults {
            GrocerySearchResultsView(
                searchText: searchText,
                searchResults: searchResults,
                isInShopping: { ingredient in
                    shopping.items.contains { $0.name.lowercased() == ingredient.lowercased() }
                },
                onAddToShopping: addShoppingItemFromSearch,
                selectedTheme: selectedTheme
            )
        } else if shopping.items.isEmpty {
            emptyState
        } else {
            shoppingList
        }
    }

    private var shoppingList: some View {
        List {
            ShoppingProgressBar(checkedCount: checkedCount, totalCount: totalCount, selectedTheme: selectedTheme)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            ShoppingSectionsView(collapsedCategories: $shoppingCollapsed)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .environment(\.defaultMinListHeaderHeight, 0)
        .padding(.top, -6)
    }

    private var emptyState: some View {
        ScrollView {
            EmptyStateView(
                icon: "cart.circle.fill",
                title: "Your groceries list is empty",
                message: "Search above to add items to your list."
            )
        }
    }

    @ViewBuilder
    private var overflowMenu: some View {
        Button { showKitchenSheet = true } label: { Label("Kitchen", systemImage: "refrigerator") }
        Divider()
        Button { showShoppingQuickAdd = true } label: { Label("Quick Add", systemImage: "plus.circle") }
        Button(action: shareShoppingList) { Label("Share Groceries", systemImage: "square.and.arrow.up") }
        Button(action: toggleCollapseAll) {
            Label(isAllCollapsed ? "Expand All" : "Collapse All",
                  systemImage: isAllCollapsed ? "chevron.down" : "chevron.up")
        }
        Button(role: .destructive) { showClearShopping = true } label: { Label("Clear Groceries", systemImage: "trash") }
    }

    private func addShoppingItem() {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        shopping.addItem(name: trimmed)
        searchText = ""
        isSearchFocused = false
        HapticManager.shared.success()
    }

    private func addShoppingItemFromSearch(_ ingredient: String) {
        guard !shopping.items.contains(where: { $0.name.lowercased() == ingredient.lowercased() }) else { return }
        shopping.addItem(name: ingredient)
        searchText = ""
        isSearchFocused = false
        HapticManager.shared.success()
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

// MARK: - Kitchen sheet

private struct KitchenInventorySheet: View {
    @Environment(\.kitchen) private var manager
    @State private var collapsed: Set<String> = []
    @State private var showAddIngredient = false
    @State private var showQuickAdd = false
    @State private var showClear = false
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScreenTitleHeader("Kitchen") {
                        Menu {
                            overflowMenu
                        } label: {
                            CircleButton(icon: "line.3.horizontal") {}
                                .allowsHitTesting(false)
                        }
                        .accessibilityLabel("Kitchen options")
                    }

                    if manager.items.isEmpty {
                        emptyState
                    } else {
                        List {
                            KitchenSectionsView(
                                collapsedCategories: $collapsed,
                                onAddMore: { showAddIngredient = true }
                            )
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .environment(\.defaultMinListHeaderHeight, 0)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showAddIngredient) { AddIngredientSheet() }
        .sheet(isPresented: $showQuickAdd) { KitchenQuickAddSheet() }
        .confirmationDialog("Clear Kitchen", isPresented: $showClear, titleVisibility: .visible) {
            Button("Clear All Ingredients", role: .destructive) { manager.clearAll() }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private var overflowMenu: some View {
        Button { showAddIngredient = true } label: { Label("Add Ingredient", systemImage: "plus.circle") }
        Button { showQuickAdd = true } label: { Label("Quick Add", systemImage: "bolt") }
        if !manager.items.isEmpty {
            Divider()
            Button(role: .destructive) { showClear = true } label: { Label("Clear Kitchen", systemImage: "trash") }
        }
    }

    private var emptyState: some View {
        ScrollView {
            EmptyStateView(
                icon: "refrigerator",
                title: "Your kitchen is empty",
                message: "Add ingredients you have at home.",
                actionTitle: "Add Ingredient",
                onAction: { showAddIngredient = true }
            )
        }
    }
}

#Preview {
    KitchenShoppingView()
        .environment(\.appTheme, .teal)
}
