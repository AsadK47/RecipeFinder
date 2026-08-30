import SwiftUI

private let logger = AppLogger.logger(category: "KitchenView")

struct KitchenView: View {
    @Binding var recipes: [RecipeModel]
    @StateObject private var manager = KitchenInventoryManager.shared
    @State private var searchText = ""
    @State private var showAddIngredientSheet = false
    @State private var showQuickAdd = false
    @State private var cachedCategorizedIngredients: [(category: String, ingredients: [String])] = []
    @State private var collapsedCategories: Set<String> = []
    @State private var quickMatches: [RecipeModel] = []
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    var categorizedIngredients: [(category: String, ingredients: [String])] {
        guard cachedCategorizedIngredients.isEmpty else {
            return cachedCategorizedIngredients
        }

        var result: [(category: String, ingredients: [String])] = []

        for category in FoodsList.categories {
            let foods = FoodsList.getFoods(forCategory: category)
            if !foods.isEmpty {
                result.append((category, foods))
            }
        }

        return result
    }

    var searchResults: [String] {
        if searchText.isEmpty {
            return []
        }
        return FoodsList.searchFoods(query: searchText)
    }

    var quickMatchRecipes: [RecipeModel] { quickMatches }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                    VStack(spacing: 0) {
                    KitchenHeader(
                        searchText: $searchText,
                        isSearchFocused: $isSearchFocused,
                        hasItems: !manager.items.isEmpty,
                        cardStyle: cardStyle,
                        colorScheme: colorScheme,
                        onQuickAdd: {
                            showQuickAdd = true
                            HapticManager.shared.light()
                        },
                        onClearKitchen: {
                            KitchenInventoryManager.shared.clearAll()
                            HapticManager.shared.light()
                        }
                    )

                    if manager.items.isEmpty && searchText.isEmpty {
                        ScrollView {
                            emptyPromptView
                                .padding(.vertical, AppTheme.spacing16)
                        }
                    } else if !searchText.isEmpty {
                        ScrollView {
                            KitchenSearchResultsView(
                                searchText: $searchText,
                                isSearchFocused: $isSearchFocused,
                                searchResults: searchResults,
                                selectedTheme: selectedTheme,
                                cardStyle: cardStyle,
                                colorScheme: colorScheme
                            )
                            .padding(.vertical, AppTheme.spacing16)
                        }
                    } else {
                        kitchenListContent
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showQuickAdd) {
            KitchenQuickAddSheet()
        }
        .sheet(isPresented: $showAddIngredientSheet) {
            AddIngredientSheet()
        }
        .onAppear {
            refreshCategorizedIngredients()
            recomputeQuickMatches()
        }
        .onChange(of: manager.items) { _, _ in
            recomputeQuickMatches()
        }
        .onChange(of: recipes) { _, _ in
            recomputeQuickMatches()
        }
    }

    private func refreshCategorizedIngredients() {
        cachedCategorizedIngredients = categorizedIngredients
    }

    private func recomputeQuickMatches() {
        quickMatches = KitchenRecipeMatcher.quickMatches(
            recipes: recipes,
            kitchenItemNames: manager.items.map { $0.name }
        )
    }

    /// Refreshes the recipe list after a favorite toggle from the quick matches strip.
    private func refreshRecipesAfterFavoriteToggle() {
        guard PersistenceController.shared.hasCurrentUserScope() else {
            logger.debug("⚠️ Skipping recipe refresh from Kitchen quick matches because user scope is unavailable")
            return
        }
        recipes = PersistenceController.shared.fetchRecipes()
    }

    private var emptyPromptView: some View {
        VStack(spacing: AppTheme.spacing16) {
            Image(systemName: "refrigerator")
                .font(.system(size: AppTheme.fontSize60))
                .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)

            Text("Your Kitchen is Empty")
                .font(.title2)
                .fontWeight(.bold)
                .adaptiveForegroundColor()

            Text("Add ingredients to see matching recipes")
                .font(.subheadline)
                .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.spacing40)
        }
        .padding(.top, AppTheme.spacing40)
        .frame(maxWidth: .infinity)
    }

    private var kitchenListContent: some View {
        List {
            if !quickMatchRecipes.isEmpty {
                Section {
                    KitchenQuickMatchesView(
                        quickMatches: quickMatchRecipes,
                        kitchenItemNames: manager.items.map { $0.name },
                        selectedTheme: selectedTheme,
                        colorScheme: colorScheme,
                        onFavoriteToggle: refreshRecipesAfterFavoriteToggle
                    )
                    .padding(.vertical, AppTheme.spacing8)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            Section {
                HStack(spacing: AppTheme.spacing12) {
                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                        Text("My Kitchen")
                            .font(.title3)
                            .fontWeight(.bold)
                            .adaptiveForegroundColor()
                        Text("\(manager.items.count) ingredients")
                            .font(.caption)
                            .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
                    }
                    Spacer()
                    Button(action: {
                        showAddIngredientSheet = true
                        HapticManager.shared.light()
                    }) {
                        HStack(spacing: AppTheme.spacing6) {
                            Image(systemName: "plus.circle.fill").font(.caption)
                            Text("Add More").font(.caption).fontWeight(.semibold)
                        }
                        .adaptiveForegroundColor()
                        .padding(.horizontal, AppTheme.spacing12)
                        .padding(.vertical, AppTheme.spacing6)
                        .background(Capsule().fill(AppTheme.accentColor(for: selectedTheme)))
                    }
                }
                .padding(.horizontal, AppTheme.spacing4)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            ForEach(KitchenInventoryManager.shared.groupedItems(), id: \.category) { group in
                Section {
                    if !collapsedCategories.contains(group.category) {
                        ForEach(group.items) { item in
                            KitchenItemRow(item: item)
                                .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                            KitchenInventoryManager.shared.removeItem(item)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                } header: {
                    kitchenCategoryHeader(category: group.category, items: group.items)
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
    private func kitchenCategoryHeader(category: String, items: [KitchenItem]) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                if collapsedCategories.contains(category) {
                    collapsedCategories.remove(category)
                } else {
                    collapsedCategories.insert(category)
                }
            }
        }) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: CategoryClassifier.categoryIcon(for: category))
                    .font(.body)
                    .foregroundColor(CategoryClassifier.categoryColor(for: category))
                    .frame(width: AppTheme.iconSize28)
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                Text("(\(items.count))")
                    .font(.footnote)
                    .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.caption)
                    .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                    .rotationEffect(.degrees(collapsedCategories.contains(category) ? 180 : 0))
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(.ultraThinMaterial)
                }
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.top, AppTheme.spacing2)
        }
        .buttonStyle(.plain)
        .textCase(nil)
        .listRowInsets(EdgeInsets())
        .headerProminence(.standard)
    }
}
