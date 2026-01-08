import SwiftUI

struct RecipeSearchView: View {
    @Binding var recipes: [RecipeModel]
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedCategories: Set<String> = []
    @State private var selectedDifficulties: Set<String> = []
    @State private var selectedCookTimes: Set<Int> = []
    @State private var selectedDietaryFilters: Set<String> = []
    @State private var selectedTags: Set<String> = []
    @State private var ingredientSearchText = ""
    @State private var availableIngredientsOnly = false
    @State private var showFavoritesOnly = false
    @State private var showImportSheet = false
    @State private var showRecipeWizard: Bool = false
    @State private var recipeToDelete: RecipeModel?
    @State private var showDeleteAlert: Bool = false
    @State private var dontAskAgainDelete: Bool = false
    @State private var cachedFilteredRecipes: [RecipeModel] = []
    @State private var lastFilterHash: Int = 0
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @AppStorage("skipRecipeDeleteConfirmation") private var skipDeleteConfirmation: Bool = false
    @AppStorage("kitchenInventory") private var kitchenInventoryJSON: String = "[]"
    
    private var availableIngredients: Set<String> {
        guard let data = kitchenInventoryJSON.data(using: .utf8),
              let items = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(items.map { $0.lowercased() })
    }

    // Optimized filtered recipes with caching
    private var filteredRecipes: [RecipeModel] {
        let currentHash = computeFilterHash()
        
        // Return cached result if filters haven't changed
        if currentHash == lastFilterHash && !cachedFilteredRecipes.isEmpty {
            return cachedFilteredRecipes
        }
        
        var results = recipes
        
        // Favorites filter
        if showFavoritesOnly {
            results = results.filter { $0.isFavorite }
        }
        
        // Search filter (recipe name)
        if !searchText.isEmpty {
            results = results.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Ingredient search filter
        if !ingredientSearchText.isEmpty {
            results = results.filter { $0.containsIngredient(ingredientSearchText) }
        }
        
        // Available ingredients only
        if availableIngredientsOnly && !availableIngredients.isEmpty {
            results = results.filter { recipe in
                recipe.ingredientMatchPercentage(availableIngredients: availableIngredients) >= 0.8
            }
        }
        
        // Category filter
        if !selectedCategories.isEmpty {
            results = results.filter { selectedCategories.contains($0.category) }
        }
        
        // Difficulty filter
        if !selectedDifficulties.isEmpty {
            results = results.filter { selectedDifficulties.contains($0.difficulty) }
        }
        
        // Cook time filter
        if !selectedCookTimes.isEmpty {
            results = results.filter { recipe in
                let time = TimeExtractor.extractMinutes(from: recipe.cookingTime)
                return selectedCookTimes.contains { time <= $0 }
            }
        }
        
        // Dietary filters
        if !selectedDietaryFilters.isEmpty {
            results = results.filter { recipe in
                selectedDietaryFilters.allSatisfy { dietaryTag in
                    switch dietaryTag {
                    case "Vegetarian": return recipe.dietaryInfo.isVegetarian
                    case "Vegan": return recipe.dietaryInfo.isVegan
                    case "Gluten-Free": return recipe.dietaryInfo.isGlutenFree
                    case "Dairy-Free": return recipe.dietaryInfo.isDairyFree
                    case "Nut-Free": return recipe.dietaryInfo.isNutFree
                    case "Low-Carb": return recipe.dietaryInfo.isLowCarb
                    case "Keto": return recipe.dietaryInfo.isKeto
                    default: return true
                    }
                }
            }
        }
        
        // Tags filter
        if !selectedTags.isEmpty {
            results = results.filter { recipe in
                !Set(recipe.tags).isDisjoint(with: selectedTags)
            }
        }
        
        // Sort by ingredient match if using "what can I make" mode
        if availableIngredientsOnly && !availableIngredients.isEmpty {
            results.sort { recipe1, recipe2 in
                let match1 = recipe1.ingredientMatchPercentage(availableIngredients: availableIngredients)
                let match2 = recipe2.ingredientMatchPercentage(availableIngredients: availableIngredients)
                return match1 > match2
            }
        }
        
        return results
    }
    
    // Helper to compute hash of current filter state
    private func computeFilterHash() -> Int {
        var hasher = Hasher()
        hasher.combine(searchText)
        hasher.combine(ingredientSearchText)
        hasher.combine(availableIngredientsOnly)
        hasher.combine(showFavoritesOnly)
        hasher.combine(selectedCategories)
        hasher.combine(selectedDifficulties)
        hasher.combine(selectedCookTimes)
        hasher.combine(selectedDietaryFilters)
        hasher.combine(selectedTags)
        hasher.combine(recipes.count)
        return hasher.finalize()
    }
    
    var activeFilterCount: Int {
        return selectedCategories.count + 
               selectedDifficulties.count + 
               selectedCookTimes.count + 
               selectedDietaryFilters.count +
               selectedTags.count +
               (showFavoritesOnly ? 1 : 0) +
               (availableIngredientsOnly ? 1 : 0) +
               (!ingredientSearchText.isEmpty ? 1 : 0)
    }
    
    var availableTags: [String] {
        Array(Set(recipes.flatMap { $0.tags })).sorted()
    }
    
    var categories: [String] {
        let validCategories = ["Breakfast", "Dessert", "Drink", "Main", "Side", "Soup", "Starter"]
        return Array(Set(recipes.map { $0.category }))
            .filter { validCategories.contains($0) }
            .sorted()
    }
    
    var difficulties: [String] {
        ["Basic", "Expert", "Intermediate"]
    }

    var body: some View {
        NavigationStack {
            mainContentView
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar { keyboardToolbar }
                .modifier(SheetPresentationModifier(
                    showFilters: $showFilters,
                    showImportSheet: $showImportSheet,
                    showRecipeWizard: $showRecipeWizard,
                    showDeleteAlert: $showDeleteAlert,
                    filterSheet: filterSheet,
                    importSheet: recipeImportSheet,
                    wizardSheet: recipeWizardSheet,
                    deleteSheet: deleteConfirmationSheet
                ))
                .modifier(FilterCacheUpdateModifier(
                    searchText: searchText,
                    ingredientSearchText: ingredientSearchText,
                    availableIngredientsOnly: availableIngredientsOnly,
                    selectedCategories: selectedCategories,
                    selectedDifficulties: selectedDifficulties,
                    selectedCookTimes: selectedCookTimes,
                    selectedDietaryFilters: selectedDietaryFilters,
                    selectedTags: selectedTags,
                    showFavoritesOnly: showFavoritesOnly,
                    recipes: recipes,
                    updateAction: updateFilterCache
                ))
        }
    }
    
    // MARK: - Main Content Orchestration
    
    private var mainContentView: some View {
        ZStack {
            backgroundView
            contentStack
        }
    }
    
    private var contentStack: some View {
        VStack(spacing: 0) {
            searchHeaderGroup
            activeFiltersSection
            recipeContentArea
        }
    }
    
    private var searchHeaderGroup: some View {
        VStack(spacing: AppTheme.spacingMD) {
            headerSection
            searchBarSection
        }
    }
    
    private var activeFiltersSection: some View {
        Group {
            if activeFilterCount > 0 {
                activeFiltersView
            }
        }
    }
    
    private var recipeContentArea: some View {
        Group {
            if filteredRecipes.isEmpty {
                emptyStateView
            } else {
                recipeListView
            }
        }
    }
    
    // MARK: - Toolbar Components
    
    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
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
    
    // MARK: - View Components
    
    private var backgroundView: some View {
        AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
            .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left spacer for balance - 15% of width or fixed size
                Color.clear
                    .frame(width: max(44, geometry.size.width * 0.15))
                
                Spacer(minLength: 8)
                
                Text("RecipeFinder")
                    .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                    .adaptiveForegroundColor()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Spacer(minLength: 8)
                
                // Right menu - 15% of width or fixed size
                Menu {
                    menuContent
                } label: {
                    ModernCircleButton(icon: "line.3.horizontal") {}
                        .allowsHitTesting(false)
                }
                .frame(width: max(44, geometry.size.width * 0.15))
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private var searchBarSection: some View {
        HStack(spacing: AppTheme.spacingMD) {
            HStack(spacing: AppTheme.spacingMD) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.adaptiveHighEmphasis(for: colorScheme))
                    .font(.system(size: AppTheme.fontSizeBody + 2, weight: .medium))
                
                ZStack(alignment: .leading) {
                    if searchText.isEmpty {
                        Text("What would you like to eat...?")
                            .font(.system(size: AppTheme.fontSizeBody))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.65) : .black.opacity(0.65))
                    }
                    TextField("", text: $searchText)
                        .focused($isSearchFocused)
                        .autocorrectionDisabled()
                        .font(.system(size: AppTheme.fontSizeBody))
                        .adaptiveForegroundColor()
                        .tint(AppTheme.textColor(for: colorScheme))
                }
                
                if !searchText.isEmpty {
                    Button(
                        action: { 
                            searchText = ""
                        },
                        label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: AppTheme.fontSizeBody + 2))
                                .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
            }
            
            if isSearchFocused {
                Button(
                    action: {
                        searchText = ""
                        isSearchFocused = false
                    },
                    label: {
                        Text("Cancel")
                            .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                            .adaptiveForegroundColor()
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .animation(.spring(response: 0.3), value: isSearchFocused)
    }
    
    private var menuContent: some View {
        Group {
            // Filter option
            Button(
                action: {
                    HapticManager.shared.light()
                    showFilters.toggle()
                },
                label: {
                    Label(activeFilterCount > 0 ? "Filters (\(activeFilterCount))" : "Filters", systemImage: "line.3.horizontal.decrease.circle")
                }
            )
            
            Divider()
            
            // Import option
            Button(
                action: {
                    HapticManager.shared.selection()
                    showImportSheet = true
                },
                label: {
                    Label("Import Recipe", systemImage: "plus.circle")
                }
            )
            
            // Recipe Wizard option
            Button(
                action: {
                    HapticManager.shared.selection()
                    showRecipeWizard = true
                },
                label: {
                    Label("Recipe Wizard", systemImage: "wand.and.stars")
                }
            )
        }
    }
    
    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacingSM) {
                if showFavoritesOnly {
                    FilterChip(label: "Favorites", icon: "heart.fill") {
                        HapticManager.shared.light()
                        showFavoritesOnly = false
                    }
                }
                
                if availableIngredientsOnly {
                    FilterChip(label: "Can Make Now", icon: "checkmark.circle.fill") {
                        HapticManager.shared.light()
                        availableIngredientsOnly = false
                    }
                }
                
                if !ingredientSearchText.isEmpty {
                    FilterChip(label: "Has: \(ingredientSearchText)", icon: "leaf.fill") {
                        HapticManager.shared.light()
                        ingredientSearchText = ""
                    }
                }
                
                ForEach(Array(selectedCategories), id: \.self) { category in
                    FilterChip(label: category, icon: "fork.knife") {
                        HapticManager.shared.light()
                        selectedCategories.remove(category)
                    }
                }
                
                ForEach(Array(selectedDifficulties), id: \.self) { difficulty in
                    FilterChip(label: difficulty, icon: "chart.bar.fill") {
                        HapticManager.shared.light()
                        selectedDifficulties.remove(difficulty)
                    }
                }
                
                ForEach(Array(selectedCookTimes), id: \.self) { time in
                    FilterChip(label: time > 120 ? "> 120 min" : "≤ \(time) min", icon: "clock.fill") {
                        HapticManager.shared.light()
                        selectedCookTimes.remove(time)
                    }
                }
                
                ForEach(Array(selectedDietaryFilters), id: \.self) { diet in
                    FilterChip(label: diet, icon: "leaf.circle.fill") {
                        HapticManager.shared.light()
                        selectedDietaryFilters.remove(diet)
                    }
                }
                
                ForEach(Array(selectedTags), id: \.self) { tag in
                    FilterChip(label: tag, icon: "tag.fill") {
                        HapticManager.shared.light()
                        selectedTags.remove(tag)
                    }
                }
                
                Button(action: clearAllFilters, label: {
                    Text("Clear All")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.8))
                        )
                })
            }
            .padding(.horizontal, 20)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var recipeListView: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.cardVerticalSpacing) {
                ForEach(filteredRecipes) { recipe in
                    recipeNavigationLink(for: recipe)
                }
            }
            .padding(.horizontal, AppTheme.cardHorizontalPadding)
            .padding(.bottom, AppTheme.cardHorizontalPadding)
        }
    }
    
    private func recipeNavigationLink(for recipe: RecipeModel) -> some View {
        NavigationLink(
            destination: RecipeDetailView(
                recipe: recipe,
                onFavoriteToggle: {
                    refreshRecipes()
                }
            )
        ) {
            RecipeCard(recipe: recipe, viewMode: .list)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                recipeToDelete = recipe
                if skipDeleteConfirmation {
                    deleteRecipe(recipe)
                    recipeToDelete = nil
                } else {
                    showDeleteAlert = true
                    HapticManager.shared.warning()
                }
            } label: {
                Label("Delete Recipe", systemImage: "trash.fill")
            }
        }
    }
    
    private var filterSheet: some View {
        FilterSheet(
            categories: categories,
            difficulties: difficulties,
            availableTags: availableTags,
            availableIngredients: availableIngredients,
            selectedCategories: $selectedCategories,
            selectedDifficulties: $selectedDifficulties,
            selectedCookTimes: $selectedCookTimes,
            selectedDietaryFilters: $selectedDietaryFilters,
            selectedTags: $selectedTags,
            ingredientSearchText: $ingredientSearchText,
            availableIngredientsOnly: $availableIngredientsOnly,
            showFavoritesOnly: $showFavoritesOnly
        )
    }
    
    private var recipeImportSheet: some View {
        RecipeImportView { importedRecipe in
            // Add the imported recipe to the list
            recipes.append(importedRecipe)
            
            // Save to Core Data
            PersistenceController.shared.saveRecipeModel(importedRecipe)
            
            HapticManager.shared.success()
        }
    }
    
    private var recipeWizardSheet: some View {
        RecipeWizardView(prefilledData: nil) { newRecipe in
            // Add the new recipe to the list
            recipes.append(newRecipe)
            
            // Save to Core Data
            PersistenceController.shared.saveRecipeModel(newRecipe)
            
            HapticManager.shared.success()
        }
    }
    
    private var deleteConfirmationSheet: some View {
        RecipeDeleteConfirmationSheet(
            recipeName: recipeToDelete?.name ?? "",
            dontAskAgain: $dontAskAgainDelete,
            onConfirm: {
                if dontAskAgainDelete {
                    skipDeleteConfirmation = true
                }
                if let recipe = recipeToDelete {
                    deleteRecipe(recipe)
                }
                recipeToDelete = nil
                dontAskAgainDelete = false
                showDeleteAlert = false
            },
            onCancel: {
                recipeToDelete = nil
                dontAskAgainDelete = false
                showDeleteAlert = false
            }
        )
    }
    
    // Update cache when filters change
    private func updateFilterCache() {
        let newHash = computeFilterHash()
        if newHash != lastFilterHash {
            cachedFilteredRecipes = filteredRecipes
            lastFilterHash = newHash
        }
    }
    
    // Delete recipe
    private func deleteRecipe(_ recipe: RecipeModel) {
        withAnimation {
            recipes.removeAll { $0.id == recipe.id }
        }
        PersistenceController.shared.deleteRecipe(withId: recipe.id)
        HapticManager.shared.success()
    }
    
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacingXL) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 70))
                    .adaptiveForegroundColor(opacity: 0.4)
                
                Text("No Recipes Found")
                    .font(.title2)
                    .fontWeight(.bold)
                    .adaptiveForegroundColor()
                
                Text("Try adjusting your filters or search")
                    .font(.subheadline)
                    .adaptiveForegroundColor(opacity: 0.7)
                
                if activeFilterCount > 0 {
                    Button(action: clearAllFilters, label: {
                        HStack(spacing: AppTheme.spacingSM) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Clear All Filters")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if cardStyle == .solid {
                                    Capsule()
                                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                                } else {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                }
                            }
                        )
                    })
                }
            }
            .padding(.top, 40)
        }
    }
    
    private func clearAllFilters() {
        HapticManager.shared.medium()
        withAnimation {
            selectedCategories.removeAll()
            selectedDifficulties.removeAll()
            selectedCookTimes.removeAll()
            selectedDietaryFilters.removeAll()
            selectedTags.removeAll()
            ingredientSearchText = ""
            availableIngredientsOnly = false
            showFavoritesOnly = false
        }
    }
    
    private func refreshRecipes() {
        // Reload recipes from Core Data to get updated favorite status
        recipes = PersistenceController.shared.fetchRecipes()
    }
}

// Filter Sheet
struct FilterSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    let categories: [String]
    let difficulties: [String]
    let availableTags: [String]
    let availableIngredients: Set<String>
    @Binding var selectedCategories: Set<String>
    @Binding var selectedDifficulties: Set<String>
    @Binding var selectedCookTimes: Set<Int>
    @Binding var selectedDietaryFilters: Set<String>
    @Binding var selectedTags: Set<String>
    @Binding var ingredientSearchText: String
    @Binding var availableIngredientsOnly: Bool
    @Binding var showFavoritesOnly: Bool
    
    let cookTimeOptions = [15, 30, 45, 60, 90, 121]
    let dietaryOptions = ["Vegetarian", "Vegan", "Gluten-Free", "Dairy-Free", "Nut-Free", "Low-Carb", "Keto"]
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: AppTheme.spacingSM, alignment: .center)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacingXXL) {
                        // Favorites Toggle
                        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                            HStack {
                                Text("Show Favorites Only")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                                
                                Spacer()
                                
                                Toggle("", isOn: $showFavoritesOnly)
                                    .tint(AppTheme.accentColor)
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // What Can I Make Filter
                        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                            HStack {
                                VStack(alignment: .leading, spacing: AppTheme.spacingXS) {
                                    Text("What Can I Make?")
                                        .font(.headline)
                                        .adaptiveForegroundColor()
                                    Text("Recipes using ingredients you have")
                                        .font(.caption)
                                        .adaptiveForegroundColor(opacity: 0.7)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $availableIngredientsOnly)
                                    .tint(AppTheme.accentColor)
                                    .disabled(availableIngredients.isEmpty)
                            }
                            
                            if availableIngredients.isEmpty {
                                Text("Add ingredients in Kitchen Inventory first")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Search by Ingredient
                        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                            Text("Search by Ingredient")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            TextField("E.g., Chicken, Tomato...", text: $ingredientSearchText)
                                .textFieldStyle(.plain)
                                .padding(AppTheme.spacingMD)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.15))
                                )
                                .adaptiveForegroundColor()
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Dietary Filters
                        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                            Text("Dietary Preferences")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            LazyVGrid(columns: columns, spacing: AppTheme.spacingSM) {
                                ForEach(dietaryOptions, id: \.self) { diet in
                                    RecipeFilterButton(
                                        label: diet,
                                        isSelected: selectedDietaryFilters.contains(diet)
                                    ) {
                                        toggleSelection(diet, in: $selectedDietaryFilters)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Tags
                        if !availableTags.isEmpty {
                            VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                                Text("Tags")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                                
                                LazyVGrid(columns: columns, spacing: AppTheme.spacingSM) {
                                    ForEach(availableTags, id: \.self) { tag in
                                        RecipeFilterButton(
                                            label: tag,
                                            isSelected: selectedTags.contains(tag)
                                        ) {
                                            toggleSelection(tag, in: $selectedTags)
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                        }
                        
                        // Category Filter
                        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                            Text("Course / Category")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            LazyVGrid(columns: columns, spacing: AppTheme.spacingSM) {
                                ForEach(categories, id: \.self) { category in
                                    RecipeFilterButton(
                                        label: category,
                                        isSelected: selectedCategories.contains(category)
                                    ) {
                                        toggleSelection(category, in: $selectedCategories)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Difficulty Filter
                        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                            Text("Difficulty")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            LazyVGrid(columns: columns, spacing: AppTheme.spacingSM) {
                                ForEach(difficulties, id: \.self) { difficulty in
                                    RecipeFilterButton(
                                        label: difficulty,
                                        isSelected: selectedDifficulties.contains(difficulty)
                                    ) {
                                        toggleSelection(difficulty, in: $selectedDifficulties)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Cook Time Filter
                        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                            Text("Max Cooking Time")
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            LazyVGrid(columns: columns, spacing: AppTheme.spacingSM) {
                                ForEach(cookTimeOptions, id: \.self) { time in
                                    RecipeFilterButton(
                                        label: time > 120 ? "> 120 min" : "≤ \(time) min",
                                        isSelected: selectedCookTimes.contains(time)
                                    ) {
                                        toggleSelection(time, in: $selectedCookTimes)
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppTheme.spacingXL)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedCategories.removeAll()
                        selectedDifficulties.removeAll()
                        selectedCookTimes.removeAll()
                        selectedDietaryFilters.removeAll()
                        selectedTags.removeAll()
                        ingredientSearchText = ""
                        availableIngredientsOnly = false
                        showFavoritesOnly = false
                    }
                    .adaptiveForegroundColor()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .adaptiveForegroundColor()
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func toggleSelection<T: Hashable>(_ item: T, in set: Binding<Set<T>>) {
        if set.wrappedValue.contains(item) {
            set.wrappedValue.remove(item)
        } else {
            set.wrappedValue.insert(item)
        }
    }
}

// Recipe Filter Button Component (specific styling for recipe filters)
struct RecipeFilterButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .adaptiveForegroundColor()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    Capsule()
                        .fill(isSelected ? AppTheme.accentColor : Color.white.opacity(0.15))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                )
        })
        .buttonStyle(.plain)
    }
}

// Recipe Delete Confirmation Sheet
struct RecipeDeleteConfirmationSheet: View {
    let recipeName: String
    @Binding var dontAskAgain: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Handle bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                    
                    VStack(spacing: AppTheme.spacingXXL) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: AppTheme.fontSizeEmoji))
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 20)
                        
                        // Title and Message
                        VStack(spacing: AppTheme.spacingMD) {
                            Text("Remove this recipe?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .adaptiveForegroundColor()
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(recipeName.isEmpty ? "This recipe will be removed from your collection." : "\(recipeName) will be removed from your collection.")
                                .font(.body)
                                .adaptiveForegroundColor(opacity: 0.85)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: geometry.size.width - 48)
                            
                            Text("This can't be undone, but you can always import it again! 📖")
                                .font(.subheadline)
                                .adaptiveForegroundColor(opacity: 0.7)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: geometry.size.width - 48)
                                .padding(.top, 4)
                        }
                        .padding(.horizontal, 24)
                    
                        // Don't ask again checkbox
                        Button(action: {
                            dontAskAgain.toggle()
                            HapticManager.shared.selection()
                        }) {
                            HStack(spacing: AppTheme.spacingMD) {
                                Image(systemName: dontAskAgain ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundColor(dontAskAgain ? AppTheme.accentColor : .white.opacity(AppTheme.mediumEmphasisOpacity))
                                
                                Text("Don't ask me again")
                                    .font(.subheadline)
                                    .adaptiveForegroundColor()
                                
                                Spacer()
                            }
                            .frame(maxWidth: geometry.size.width - 48)
                            .padding(.horizontal, 24)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Action Buttons
                        VStack(spacing: AppTheme.spacingMD) {
                            Button(action: {
                                HapticManager.shared.light()
                                onConfirm()
                            }) {
                                Text("Remove Recipe")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                                    .frame(maxWidth: geometry.size.width - 48)
                                    .padding(.vertical, 16)
                                    .background(Color.orange)
                                    .cornerRadius(14)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                HapticManager.shared.light()
                                onCancel()
                            }) {
                                Text("Keep It")
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                                    .frame(maxWidth: geometry.size.width - 48)
                                    .padding(.vertical, 16)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(14)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.height(480)])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - View Modifiers

/// Encapsulates all sheet presentation logic following Single Responsibility Principle
struct SheetPresentationModifier: ViewModifier {
    @Binding var showFilters: Bool
    @Binding var showImportSheet: Bool
    @Binding var showRecipeWizard: Bool
    @Binding var showDeleteAlert: Bool
    
    let filterSheet: AnyView
    let importSheet: AnyView
    let wizardSheet: AnyView
    let deleteSheet: AnyView
    
    init(showFilters: Binding<Bool>,
         showImportSheet: Binding<Bool>,
         showRecipeWizard: Binding<Bool>,
         showDeleteAlert: Binding<Bool>,
         filterSheet: some View,
         importSheet: some View,
         wizardSheet: some View,
         deleteSheet: some View) {
        self._showFilters = showFilters
        self._showImportSheet = showImportSheet
        self._showRecipeWizard = showRecipeWizard
        self._showDeleteAlert = showDeleteAlert
        self.filterSheet = AnyView(filterSheet)
        self.importSheet = AnyView(importSheet)
        self.wizardSheet = AnyView(wizardSheet)
        self.deleteSheet = AnyView(deleteSheet)
    }
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showFilters) {
                filterSheet
            }
            .sheet(isPresented: $showImportSheet) {
                importSheet
            }
            .sheet(isPresented: $showRecipeWizard) {
                wizardSheet
            }
            .sheet(isPresented: $showDeleteAlert) {
                deleteSheet
            }
    }
}

/// Manages filter state change observation and cache updates
struct FilterCacheUpdateModifier: ViewModifier {
    let searchText: String
    let ingredientSearchText: String
    let availableIngredientsOnly: Bool
    let selectedCategories: Set<String>
    let selectedDifficulties: Set<String>
    let selectedCookTimes: Set<Int>
    let selectedDietaryFilters: Set<String>
    let selectedTags: Set<String>
    let showFavoritesOnly: Bool
    let recipes: [RecipeModel]
    let updateAction: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onChange(of: searchText) { _, _ in updateAction() }
            .onChange(of: ingredientSearchText) { _, _ in updateAction() }
            .onChange(of: availableIngredientsOnly) { _, _ in updateAction() }
            .onChange(of: selectedCategories) { _, _ in updateAction() }
            .onChange(of: selectedDifficulties) { _, _ in updateAction() }
            .onChange(of: selectedCookTimes) { _, _ in updateAction() }
            .onChange(of: selectedDietaryFilters) { _, _ in updateAction() }
            .onChange(of: selectedTags) { _, _ in updateAction() }
            .onChange(of: showFavoritesOnly) { _, _ in updateAction() }
            .onChange(of: recipes) { _, _ in updateAction() }
    }
}
