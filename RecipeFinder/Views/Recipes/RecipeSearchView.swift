import SwiftUI

struct RecipeSearchView: View {
    @Binding var recipes: [RecipeModel]
    @ObservedObject var shoppingListManager: ShoppingListManager
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedCategories: Set<String> = []
    @State private var selectedDifficulties: Set<String> = []
    @State private var selectedCookTimes: Set<Int> = []
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

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                VStack(spacing: 0) {
                    headerSection
                    
                    // Search bar with cancel option
                    searchBarSection
                    
                    // Active filters chips
                    if activeFilterCount > 0 {
                        activeFiltersView
                    }
                    
                    if filteredRecipes.isEmpty {
                        emptyStateView
                    } else {
                        recipeListView
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showFilters) {
                filterSheet
            }
            .sheet(isPresented: $showImportSheet) {
                recipeImportSheet
            }
            .sheet(isPresented: $showRecipeWizard) {
                recipeWizardSheet
            }
            .onChange(of: searchText) { _, _ in updateFilterCache() }
            .onChange(of: selectedCategories) { _, _ in updateFilterCache() }
            .onChange(of: selectedDifficulties) { _, _ in updateFilterCache() }
            .onChange(of: selectedCookTimes) { _, _ in updateFilterCache() }
            .onChange(of: showFavoritesOnly) { _, _ in updateFilterCache() }
            .onChange(of: recipes) { _, _ in updateFilterCache() }
            .sheet(isPresented: $showDeleteAlert) {
                deleteConfirmationSheet
            }
        }
    }
    
    // MARK: - View Components
    
    private var backgroundView: some View {
        AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
            .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left spacer for balance - 15% of width or fixed size
                    Color.clear
                        .frame(width: max(44, geometry.size.width * 0.15))
                    
                    Spacer(minLength: 8)
                    
                    Text("Recipe Finder")
                        .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
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
    }
    
    private var searchBarSection: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.6))
                    .font(.body)
                
                TextField("What would you like to eat...?", text: $searchText)
                    .focused($isSearchFocused)
                    .autocorrectionDisabled()
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                if !searchText.isEmpty {
                    Button(
                        action: { 
                            searchText = ""
                        },
                        label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                        }
                    )
                }
            }
            .padding(14)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
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
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
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
                shoppingListManager: shoppingListManager,
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
            selectedCategories: $selectedCategories,
            selectedDifficulties: $selectedDifficulties,
            selectedCookTimes: $selectedCookTimes,
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
                        Group {
                            if cardStyle == .solid {
                                Capsule()
                                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
                            } else {
                                Capsule()
                                    .fill(.ultraThinMaterial)
                            }
                        }
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
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
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
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
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
                    
                    VStack(spacing: 24) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 20)
                        
                        // Title and Message
                        VStack(spacing: 12) {
                            Text("Remove this recipe?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(recipeName.isEmpty ? "This recipe will be removed from your collection." : "\(recipeName) will be removed from your collection.")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: geometry.size.width - 48)
                            
                            Text("This can't be undone, but you can always import it again! 📖")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
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
                            HStack(spacing: 12) {
                                Image(systemName: dontAskAgain ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundColor(dontAskAgain ? AppTheme.accentColor : .white.opacity(0.6))
                                
                                Text("Don't ask me again")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .frame(maxWidth: geometry.size.width - 48)
                            .padding(.horizontal, 24)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                HapticManager.shared.light()
                                onConfirm()
                            }) {
                                Text("Remove Recipe")
                                    .font(.headline)
                                    .foregroundColor(.white)
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
                                    .foregroundColor(.white)
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
