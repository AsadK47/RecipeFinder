import SwiftUI

struct IngredientSearchView: View {
    @Binding var recipes: [RecipeModel]
    @State private var searchText = ""
    @State private var viewMode: RecipeViewMode = .list
    @State private var selectedIngredient: String?
    @State private var showFilters = false
    @State private var selectedCategories: Set<String> = []
    @State private var addedIngredients: Set<String> = []
    @State private var showAddedFeedback: String?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    /// Pure ingredient/recipe queries; see `IngredientCatalog`.
    private var catalog: IngredientCatalog {
        IngredientCatalog(recipes: recipes)
    }

    var filteredCategorizedIngredients: [(category: String, ingredients: [String])] {
        catalog.categorizedIngredients(filteredBy: selectedCategories)
    }

    var activeFilterCount: Int {
        selectedCategories.count
    }

    var searchResults: [String] {
        catalog.searchResults(for: searchText)
    }

    var filteredRecipes: [RecipeModel] {
        catalog.recipes(containing: selectedIngredient)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: AppTheme.spacing24) {
                    VStack(spacing: AppTheme.spacing16) {
                        HStack {
                            if selectedIngredient == nil {
                                Button(action: { showFilters.toggle() }, label: {
                                    ZStack(alignment: .topTrailing) {
                                        Image(systemName: "line.3.horizontal.decrease.circle")
                                            .font(.title2)
                                            .foregroundColor(cardStyle == .solid && colorScheme == .light ? .black : .white)
                                            .padding(AppTheme.spacing12)
                                            .background {
                                                if cardStyle == .solid {
                                                    Circle()
                                                        .fill(AppTheme.cardBackground(for: colorScheme))
                                                } else {
                                                    Circle()
                                                        .fill(.regularMaterial)
                                                }
                                            }

                                        if activeFilterCount > 0 {
                                            Text("\(activeFilterCount)")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .adaptiveForegroundColor()
                                                .frame(width: AppTheme.iconSize18, height: 18)
                                                .background(Circle().fill(Color.red))
                                                .offset(x: 4, y: -4)
                                        }
                                    }
                                })
                            } else {
                                Color.clear
                                    .frame(width: AppTheme.iconSize48, height: AppTheme.height48)
                            }

                            Spacer()

                            Text("Ingredients")
                                .font(.system(size: AppTheme.fontSize34, weight: .bold))
                                .adaptiveForegroundColor()

                            Spacer()

                            if selectedIngredient != nil {
                                Menu {
                                    ForEach(RecipeViewMode.allCases, id: \.self) { mode in
                                        Button(
                                            action: {
                                                withAnimation(.spring(response: 0.3)) {
                                                    viewMode = mode
                                                }
                                            },
                                            label: {
                                                Label(mode.rawValue, systemImage: mode.icon)
                                            }
                                        )
                                    }
                                } label: {
                                    Image(systemName: viewMode.icon)
                                        .font(.title2)
                                        .foregroundColor(cardStyle == .solid && colorScheme == .light ? .black : .white)
                                        .padding(AppTheme.spacing12)
                                        .background {
                                            if cardStyle == .solid {
                                                Circle()
                                                    .fill(AppTheme.cardBackground(for: colorScheme))
                                            } else {
                                                Circle()
                                                    .fill(.regularMaterial)
                                            }
                                        }
                                }
                            } else {
                                Color.clear
                                    .frame(width: AppTheme.iconSize48, height: AppTheme.height48)
                            }
                        }
                        .padding(.horizontal, AppTheme.spacing20)

                        SearchBar(text: $searchText, placeholder: "Search for Ingredients...")
                            .padding(.horizontal, AppTheme.spacing20)

                        if activeFilterCount > 0 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.spacing8) {
                                    ForEach(Array(selectedCategories), id: \.self) { category in
                                        FilterChip(
                                            label: category,
                                            icon: CategoryClassifier.categoryIcon(for: CategoryClassifier.suggestCategory(for: category.lowercased()))
                                        ) {
                                            selectedCategories.remove(category)
                                        }
                                    }

                                    Button(action: clearAllFilters, label: {
                                        Text("Clear All")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .adaptiveForegroundColor()
                                            .padding(.horizontal, AppTheme.spacing12)
                                            .padding(.vertical, AppTheme.spacing6)
                                            .background(
                                                Capsule()
                                                    .fill(Color.red.opacity(AppTheme.highEmphasisOpacity))
                                            )
                                    })
                                }
                                .padding(.horizontal, AppTheme.spacing20)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.top, AppTheme.spacing20)

                    if selectedIngredient == nil {
                        if !searchText.isEmpty {
                            searchResultsView
                        } else {
                            ingredientBrowserView
                        }
                    } else {
                        IngredientRecipeResultsView(
                            selectedIngredient: $selectedIngredient,
                            viewMode: $viewMode,
                            filteredRecipes: filteredRecipes,
                            cardStyle: cardStyle,
                            colorScheme: colorScheme
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showFilters) {
                IngredientFilterSheet(
                    categories: CategoryClassifier.kitchenCategories,
                    selectedCategories: $selectedCategories
                )
            }
        }
    }

    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.spacing12) {
                if searchResults.isEmpty {
                    VStack(spacing: AppTheme.spacing16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: AppTheme.fontSize60))
                            .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)

                        Text("No ingredients found")
                            .font(.headline)
                            .adaptiveForegroundColor()

                        Text("Try a different search term")
                            .font(.subheadline)
                            .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppTheme.spacing60)
                } else {
                    ForEach(searchResults, id: \.self) { ingredient in
                        IngredientRow(
                            ingredient: ingredient,
                            recipeCount: catalog.recipeCount(for: ingredient),
                            isAdded: addedIngredients.contains(ingredient),
                            onSelect: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedIngredient = ingredient
                                }
                            },
                            onAddToShoppingList: { addToShoppingList(ingredient) },
                            cardStyle: cardStyle,
                            colorScheme: colorScheme
                        )
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.vertical, AppTheme.spacing16)
        }
    }

    private var ingredientBrowserView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing32) {
                VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                    Text("Browse by Category")
                        .font(.title3)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()

                    ForEach(filteredCategorizedIngredients, id: \.category) { category, ingredients in
                        CategoryCard(
                            category: category,
                            ingredients: ingredients,
                            addedIngredients: $addedIngredients,
                            onSelectIngredient: { ingredient in
                                withAnimation(.spring(response: 0.3)) {
                                    selectedIngredient = ingredient
                                }
                            },
                            onAddToShoppingList: addToShoppingList,
                            getVariations: catalog.variations
                        )
                    }
                }
                .padding(.horizontal, AppTheme.spacing20)
            }
            .padding(.vertical, AppTheme.spacing16)
        }
    }

    private func addToShoppingList(_ ingredient: String) {
        ShoppingListManager.shared.addItem(name: ingredient)
        addedIngredients.insert(ingredient)
        showAddedFeedback = ingredient

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            if self.showAddedFeedback == ingredient {
                self.showAddedFeedback = nil
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayXLong) {
            self.addedIngredients.remove(ingredient)
        }
    }

    private func clearAllFilters() {
        withAnimation(.spring(response: 0.3)) {
            selectedCategories.removeAll()
        }
    }
}
