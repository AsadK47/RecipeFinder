import SwiftUI

struct RecipeSearchView: View {
    @Binding var recipes: [RecipeModel]
    @ObservedObject var shoppingListManager: ShoppingListManager
    @State private var searchText = ""
    @State private var viewMode: RecipeViewMode = .list
    @State private var showFilters = false
    @State private var selectedCategories: Set<String> = []
    @State private var selectedDifficulties: Set<String> = []
    @State private var selectedCookTimes: Set<Int> = []
    @State private var showFavoritesOnly = false
    @State private var showImportSheet = false
        @State private var showRecipeWizard: Bool = false
    @State private var recipeToDelete: RecipeModel?
    @State private var showDeleteAlert: Bool = false
    @State private var cachedFilteredRecipes: [RecipeModel] = []
    @State private var lastFilterHash: Int = 0
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

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
        
        // Search filter
        if !searchText.isEmpty {
            results = results.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Category filter (OR logic - show if matches any selected category)
        if !selectedCategories.isEmpty {
            results = results.filter { selectedCategories.contains($0.category) }
        }
        
        // Difficulty filter (OR logic - show if matches any selected difficulty)
        if !selectedDifficulties.isEmpty {
            results = results.filter { selectedDifficulties.contains($0.difficulty) }
        }
        
        // Cook time filter (OR logic - show if <= any selected time limit)
        if !selectedCookTimes.isEmpty {
            results = results.filter { recipe in
                let time = TimeExtractor.extractMinutes(from: recipe.cookingTime)
                return selectedCookTimes.contains { time <= $0 }
            }
        }
        
        return results
    }
    
    // Helper to compute hash of current filter state
    private func computeFilterHash() -> Int {
        var hasher = Hasher()
        hasher.combine(searchText)
        hasher.combine(showFavoritesOnly)
        hasher.combine(selectedCategories)
        hasher.combine(selectedDifficulties)
        hasher.combine(selectedCookTimes)
        hasher.combine(recipes.count) // Include recipe count to detect changes
        return hasher.finalize()
    }
    
    var activeFilterCount: Int {
        return selectedCategories.count + selectedDifficulties.count + selectedCookTimes.count + (showFavoritesOnly ? 1 : 0)
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
    
    var gridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                // Left spacer for balance - 15% of width or fixed size
                                Color.clear
                                    .frame(width: max(44, geometry.size.width * 0.15))
                                
                                Spacer(minLength: 8)
                                
                                Text("Recipe Finder")
                                    .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                
                                Spacer(minLength: 8)
                                
                                // Right menu - 15% of width or fixed size
                                Menu {
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
                        
                        ModernSearchBar(text: $searchText, placeholder: "What would you like to eat...?")
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                        
                    }
                    
                    // Active filters chips
                    if activeFilterCount > 0 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                if showFavoritesOnly {
                                    FilterChip(label: "Favorites", icon: "heart.fill") {
                                        HapticManager.shared.light()
                                        showFavoritesOnly = false
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
                                
                                Button(action: clearAllFilters, label: {
                                    Text("Clear All")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
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
                    
                    if filteredRecipes.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            if viewMode == .list {
                                LazyVStack(spacing: AppTheme.cardVerticalSpacing) {
                                    ForEach(filteredRecipes) { recipe in
                                        NavigationLink(
                                            destination: RecipeDetailView(
                                                recipe: recipe,
                                                shoppingListManager: shoppingListManager,
                                                onFavoriteToggle: {
                                            refreshRecipes()
                                        })) {
                                            RecipeCard(recipe: recipe, viewMode: .list)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .simultaneousGesture(TapGesture().onEnded {
                                            HapticManager.shared.light()
                                        })
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                recipeToDelete = recipe
                                                showDeleteAlert = true
                                                HapticManager.shared.warning()
                                            } label: {
                                                Label("Delete", systemImage: "trash.fill")
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, AppTheme.cardHorizontalPadding)
                                .padding(.bottom, AppTheme.cardHorizontalPadding)
                            } else {
                                LazyVGrid(columns: gridColumns, spacing: 16) {
                                    ForEach(filteredRecipes) { recipe in
                                        NavigationLink(
                                            destination: RecipeDetailView(
                                                recipe: recipe,
                                                shoppingListManager: shoppingListManager,
                                                onFavoriteToggle: {
                                            refreshRecipes()
                                        })) {
                                            CompactRecipeCard(recipe: recipe)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .simultaneousGesture(TapGesture().onEnded {
                                            HapticManager.shared.light()
                                        })
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                recipeToDelete = recipe
                                                showDeleteAlert = true
                                                HapticManager.shared.warning()
                                            } label: {
                                                Label("Delete Recipe", systemImage: "trash.fill")
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .padding(.bottom, 20)
                            }
                        }
                        .id(viewMode) // Force refresh when view mode changes
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showFilters) {
                FilterSheet(
                    categories: categories,
                    difficulties: difficulties,
                    selectedCategories: $selectedCategories,
                    selectedDifficulties: $selectedDifficulties,
                    selectedCookTimes: $selectedCookTimes,
                    showFavoritesOnly: $showFavoritesOnly
                )
            }
            .sheet(isPresented: $showImportSheet) {
                RecipeImportView { importedRecipe in
                    // Add the imported recipe to the list
                    recipes.append(importedRecipe)
                    
                    // Save to Core Data
                    PersistenceController.shared.saveRecipeModel(importedRecipe)
                    
                    HapticManager.shared.success()
                }
            }
            .sheet(isPresented: $showRecipeWizard) {
                RecipeWizardView(prefilledData: nil) { newRecipe in
                    // Add the new recipe to the list
                    recipes.append(newRecipe)
                    
                    // Save to Core Data
                    PersistenceController.shared.saveRecipeModel(newRecipe)
                    
                    HapticManager.shared.success()
                }
            }
            .onChange(of: searchText) { _, _ in updateFilterCache() }
            .onChange(of: selectedCategories) { _, _ in updateFilterCache() }
            .onChange(of: selectedDifficulties) { _, _ in updateFilterCache() }
            .onChange(of: selectedCookTimes) { _, _ in updateFilterCache() }
            .onChange(of: showFavoritesOnly) { _, _ in updateFilterCache() }
            .onChange(of: recipes) { _, _ in updateFilterCache() }
            .alert("Delete Recipe?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    recipeToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let recipe = recipeToDelete {
                        deleteRecipe(recipe)
                    }
                    recipeToDelete = nil
                }
            } message: {
                Text("This will permanently delete '\(recipeToDelete?.name ?? "this recipe")'. This action cannot be reversed.")
            }
        }
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
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No recipes found")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Try adjusting your filters or search")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            if activeFilterCount > 0 {
                Button(action: clearAllFilters, label: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear All Filters")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.regularMaterial)
                    )
                })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
    
    private func clearAllFilters() {
        HapticManager.shared.medium()
        withAnimation {
            selectedCategories.removeAll()
            selectedDifficulties.removeAll()
            selectedCookTimes.removeAll()
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
    @Environment(\.appTheme) var appTheme
    
    let categories: [String]
    let difficulties: [String]
    @Binding var selectedCategories: Set<String>
    @Binding var selectedDifficulties: Set<String>
    @Binding var selectedCookTimes: Set<Int>
    @Binding var showFavoritesOnly: Bool
    
    let cookTimeOptions = [15, 30, 45, 60, 90, 121] // 121 represents "> 120"
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 8, alignment: .center)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Favorites Toggle
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Show Favorites Only")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Toggle("", isOn: $showFavoritesOnly)
                                    .tint(AppTheme.accentColor)
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Category Filter
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Course / Category")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: columns, spacing: 8) {
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
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Difficulty")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: columns, spacing: 8) {
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
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Max Cooking Time")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: columns, spacing: 8) {
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
                    .padding(20)
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
                        showFavoritesOnly = false
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
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
                .foregroundColor(.white)
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
