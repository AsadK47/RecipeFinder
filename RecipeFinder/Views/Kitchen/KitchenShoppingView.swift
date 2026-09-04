import ConfettiSwiftUI
import SwiftUI

/// The "Groceries" tab: one screen, one title, one search, one scroll — showing two
/// sections, **Shopping** and **In your kitchen**. Replaces the old segmented
/// Shopping/Kitchen switch so the tab reads like every other tab. The two stores
/// (`ShoppingListManager`, `KitchenInventoryManager`) remain separate — this is a
/// UI/IA merge, not a data-model merge.
struct KitchenShoppingView: View {
    @Binding var recipes: [RecipeModel]

    @ObservedObject private var shopping = ShoppingListManager.shared
    @ObservedObject private var kitchen = KitchenInventoryManager.shared
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var shoppingCollapsed: Set<String> = []
    @State private var kitchenCollapsed: Set<String> = []
    @State private var shoppingSectionCollapsed = false
    @State private var kitchenSectionCollapsed = false
    @State private var quickMatches: [RecipeModel] = []
    @State private var confettiTrigger = 0
    @State private var showShoppingQuickAdd = false
    @State private var showKitchenQuickAdd = false
    @State private var showAddIngredient = false
    @State private var showClearShopping = false
    @State private var showClearKitchen = false

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    private var searchResults: [String] {
        guard !searchText.isEmpty else { return [] }
        return FoodsList.searchFoods(query: searchText)
    }

    private var showingSearchResults: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty && isSearchFocused
    }

    private var checkedCount: Int { shopping.items.filter { $0.isChecked }.count }
    private var totalCount: Int { shopping.items.count }
    private var isAllShoppingCollapsed: Bool {
        shoppingCollapsed.count == CategoryClassifier.categoryOrder.count
    }
    private var bothEmpty: Bool { shopping.items.isEmpty && kitchen.items.isEmpty }

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
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .confettiCannon(trigger: $confettiTrigger, num: AppTheme.confettiCount, radius: AppTheme.confettiRadius)
        .onAppear(perform: recomputeQuickMatches)
        .onChange(of: kitchen.items) { _, _ in recomputeQuickMatches() }
        .onChange(of: recipes) { _, _ in recomputeQuickMatches() }
        .onChange(of: checkedCount) { _, newValue in
            if !shopping.items.isEmpty && newValue == totalCount {
                HapticManager.shared.success()
                confettiTrigger += 1
            }
        }
        .confirmationDialog("Clear Shopping List", isPresented: $showClearShopping, titleVisibility: .visible) {
            if checkedCount > 0 {
                Button("Clear Checked Items (\(checkedCount))", role: .destructive) { shopping.clearCheckedItems() }
            }
            Button("Clear All Items (\(totalCount))", role: .destructive) { shopping.clearAllItems() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Clear Kitchen", isPresented: $showClearKitchen, titleVisibility: .visible) {
            Button("Clear All Ingredients", role: .destructive) { kitchen.clearAll() }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showShoppingQuickAdd) { ShoppingQuickAddSheet() }
        .sheet(isPresented: $showKitchenQuickAdd) { KitchenQuickAddSheet() }
        .sheet(isPresented: $showAddIngredient) { AddIngredientSheet() }
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
                isInKitchen: { ingredient in
                    kitchen.items.contains { $0.name.lowercased() == ingredient.lowercased() }
                },
                onAddToShopping: addShoppingItemFromSearch,
                onAddToKitchen: addKitchenItemFromSearch,
                selectedTheme: selectedTheme,
                cardStyle: cardStyle,
                colorScheme: colorScheme
            )
        } else if bothEmpty {
            combinedEmptyState
        } else {
            groceriesList
        }
    }

    private var groceriesList: some View {
        List {
            groupHeader("Shopping", systemImage: "cart.fill", count: totalCount,
                        isCollapsed: shoppingSectionCollapsed) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    shoppingSectionCollapsed.toggle()
                }
                HapticManager.shared.selection()
            }
            if !shoppingSectionCollapsed {
                if shopping.items.isEmpty {
                    placeholderRow("Nothing on your list yet")
                } else {
                    ShoppingProgressBar(checkedCount: checkedCount, totalCount: totalCount, selectedTheme: selectedTheme)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    ShoppingSectionsView(collapsedCategories: $shoppingCollapsed)
                }
            }

            groupHeader("In your kitchen", systemImage: "refrigerator.fill", count: kitchen.items.count,
                        isCollapsed: kitchenSectionCollapsed) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    kitchenSectionCollapsed.toggle()
                }
                HapticManager.shared.selection()
            }
            if !kitchenSectionCollapsed {
                if kitchen.items.isEmpty {
                    placeholderRow("No ingredients yet")
                } else {
                    KitchenSectionsView(
                        collapsedCategories: $kitchenCollapsed,
                        quickMatches: quickMatches,
                        onAddMore: { showAddIngredient = true },
                        onFavoriteToggle: refreshRecipesAfterFavoriteToggle
                    )
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .environment(\.defaultMinListHeaderHeight, 0)
        .padding(.top, -6)
    }

    @ViewBuilder
    private func groupHeader(_ title: String, systemImage: String, count: Int,
                            isCollapsed: Bool, onToggle: @escaping () -> Void) -> some View {
        Button(action: onToggle) {
            HStack(spacing: AppTheme.spacing8) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                Text(title)
                    .font(.title3).fontWeight(.bold)
                    .adaptiveForegroundColor()
                if count > 0 {
                    Text("\(count)")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
                }
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                    .rotationEffect(.degrees(isCollapsed ? 180 : 0))
            }
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.top, AppTheme.spacing16)
            .padding(.bottom, AppTheme.spacing4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }

    private func placeholderRow(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.vertical, AppTheme.spacing8)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }

    private var combinedEmptyState: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing16) {
                Image(systemName: "cart.circle.fill")
                    .font(.system(size: AppTheme.fontSize60))
                    .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
                Text("Your groceries are empty")
                    .font(.title2).fontWeight(.bold)
                    .adaptiveForegroundColor()
                Text("Search above to add items to your shopping list or kitchen.")
                    .font(.subheadline)
                    .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.spacing32)
            }
            .padding(.top, AppTheme.spacing40)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var overflowMenu: some View {
        Section("Shopping") {
            Button { showShoppingQuickAdd = true } label: { Label("Quick Add", systemImage: "plus.circle") }
            Button(action: shareShoppingList) { Label("Share List", systemImage: "square.and.arrow.up") }
            Button(action: toggleCollapseAllShopping) {
                Label(isAllShoppingCollapsed ? "Expand All" : "Collapse All",
                      systemImage: isAllShoppingCollapsed ? "chevron.down" : "chevron.up")
            }
            Button(role: .destructive) { showClearShopping = true } label: { Label("Clear List", systemImage: "trash") }
        }
        Section("Kitchen") {
            Button { showAddIngredient = true } label: { Label("Add Ingredient", systemImage: "plus.circle") }
            Button { showKitchenQuickAdd = true } label: { Label("Quick Add", systemImage: "bolt") }
            Button(role: .destructive) { showClearKitchen = true } label: { Label("Clear Kitchen", systemImage: "trash") }
        }
    }

    private func addShoppingItem() {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        shopping.addItem(name: trimmed)
        searchText = ""
        isSearchFocused = false
        HapticManager.shared.success()
    }

    /// Adds from the shared search without clearing the query, so the same result can
    /// also be sent to the other destination and the row can show an "added" check.
    private func addShoppingItemFromSearch(_ ingredient: String) {
        guard !shopping.items.contains(where: { $0.name.lowercased() == ingredient.lowercased() }) else { return }
        shopping.addItem(name: ingredient)
        HapticManager.shared.success()
    }

    private func addKitchenItemFromSearch(_ ingredient: String) {
        guard !kitchen.items.contains(where: { $0.name.lowercased() == ingredient.lowercased() }) else { return }
        kitchen.addItem(name: ingredient)
        HapticManager.shared.success()
    }

    private func toggleCollapseAllShopping() {
        if isAllShoppingCollapsed {
            shoppingCollapsed.removeAll()
        } else {
            shoppingCollapsed = Set(CategoryClassifier.categoryOrder)
        }
    }

    private func recomputeQuickMatches() {
        quickMatches = KitchenRecipeMatcher.quickMatches(
            recipes: recipes,
            kitchenItemNames: kitchen.items.map { $0.name }
        )
    }

    private func refreshRecipesAfterFavoriteToggle() {
        guard PersistenceController.shared.hasCurrentUserScope() else { return }
        recipes = PersistenceController.shared.fetchRecipes()
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
            popover.sourceView = topController.view
            popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        topController.present(activityController, animated: true)
    }
}

#Preview {
    KitchenShoppingView(recipes: .constant([]))
        .environment(\.appTheme, .teal)
}
