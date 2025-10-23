import SwiftUI

struct IngredientSearchView: View {
    @Binding var recipes: [RecipeModel]
    @ObservedObject var shoppingListManager: ShoppingListManager
    @ObservedObject var pantryManager: KitchenInventoryManager
    @State private var searchText = ""
    @State private var viewMode: RecipeViewMode = .list
    @State private var selectedIngredient: String?
    @State private var showAllIngredients = false
    @State private var showFilters = false
    @State private var selectedCategories: Set<String> = []
    @State private var addedIngredients: Set<String> = []
    @State private var showAddedFeedback: String?
    @Environment(\.colorScheme) var colorScheme
    
    var allIngredients: [String] {
        Set(recipes.flatMap { $0.ingredients.map { $0.name } }).sorted()
    }
    
    var popularIngredients: [String] {
        // Get top 12 most common ingredients
        let ingredientCounts = recipes.flatMap { $0.ingredients.map { $0.name } }
            .reduce(into: [:]) { counts, ingredient in
                counts[ingredient, default: 0] += 1
            }
        return ingredientCounts.sorted { $0.value > $1.value }
            .prefix(12)
            .map { $0.key }
    }
    
    var categorizedIngredients: [(category: String, ingredients: [String])] {
        CategoryClassifier.kitchenCategories.compactMap { category in
            guard let keywords = CategoryClassifier.kitchenIngredientKeywords[category] else { return nil }
            let matchedIngredients = allIngredients.filter { ingredient in
                keywords.contains { keyword in
                    ingredient.localizedCaseInsensitiveContains(keyword)
                }
            }
            // Group similar ingredients and capitalize
            let grouped = CategoryClassifier.groupSimilarIngredients(matchedIngredients)
            return grouped.isEmpty ? nil : (category, grouped.sorted())
        }
    }
    
    // Get all variations of a main ingredient
    private func getIngredientVariations(_ mainIngredient: String) -> [String] {
        return allIngredients.filter { ingredient in
            ingredient.localizedCaseInsensitiveContains(mainIngredient)
        }.sorted()
    }
    
    var filteredCategorizedIngredients: [(category: String, ingredients: [String])] {
        if selectedCategories.isEmpty {
            return categorizedIngredients
        }
        return categorizedIngredients.filter { selectedCategories.contains($0.category) }
    }
    
    var activeFilterCount: Int {
        return selectedCategories.count
    }
    
    var searchResults: [String] {
        if searchText.isEmpty {
            return []
        }
        return allIngredients.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var filteredRecipes: [RecipeModel] {
        if let ingredient = selectedIngredient {
            return recipes.filter { recipe in
                recipe.ingredients.contains { $0.name.localizedCaseInsensitiveContains(ingredient) }
            }
        }
        return recipes
    }
    
    var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: viewMode.columns)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        HStack {
                            // Filter button
                            if selectedIngredient == nil {
                                Button(action: { showFilters.toggle() }) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(systemName: "line.3.horizontal.decrease.circle")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .padding(12)
                                            .background(
                                                Circle()
                                                    .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                                            )
                                        
                                        if activeFilterCount > 0 {
                                            Text("\(activeFilterCount)")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .frame(width: 18, height: 18)
                                                .background(Circle().fill(Color.red))
                                                .offset(x: 4, y: -4)
                                        }
                                    }
                                }
                            } else {
                                Color.clear
                                    .frame(width: 48, height: 48)
                            }
                            
                            Spacer()
                            
                            Text("Ingredients")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if selectedIngredient != nil {
                                Menu {
                                    ForEach(RecipeViewMode.allCases, id: \.self) { mode in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3)) {
                                                viewMode = mode
                                            }
                                        }) {
                                            Label(mode.rawValue, systemImage: mode.icon)
                                        }
                                    }
                                } label: {
                                    Image(systemName: viewMode.icon)
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(
                                            Circle()
                                                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                                        )
                                }
                            } else {
                                Color.clear
                                    .frame(width: 48, height: 48)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        ModernSearchBar(text: $searchText, placeholder: "Search for ingredients...")
                            .padding(.horizontal, 20)
                        
                        // Active filters chips
                        if activeFilterCount > 0 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(selectedCategories), id: \.self) { category in
                                        FilterChip(label: category, icon: categoryIcon(for: CategoryClassifier.suggestCategory(for: category.lowercased()))) {
                                            selectedCategories.remove(category)
                                        }
                                    }
                                    
                                    Button(action: clearAllFilters) {
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
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.top, 20)
                    
                    if selectedIngredient == nil {
                        if !searchText.isEmpty {
                            searchResultsView
                        } else {
                            ingredientBrowserView
                        }
                    } else {
                        recipeResultsView
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
    
    // MARK: - Search Results View
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("No ingredients found")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    ForEach(searchResults, id: \.self) { ingredient in
                        ingredientButton(ingredient)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Main Ingredient Browser
    private var ingredientBrowserView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Categories Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Browse by Category")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    ForEach(filteredCategorizedIngredients, id: \.category) { category, ingredients in
                        CategoryCard(
                            category: category,
                            ingredients: ingredients,
                            shoppingListManager: shoppingListManager,
                            pantryManager: pantryManager,
                            addedIngredients: $addedIngredients,
                            onSelectIngredient: { ingredient in
                                withAnimation(.spring(response: 0.3)) {
                                    selectedIngredient = ingredient
                                }
                            },
                            onAddToShoppingList: addToShoppingList,
                            getVariations: getIngredientVariations
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Helper Views
    private func ingredientButton(_ ingredient: String) -> some View {
        let category = CategoryClassifier.suggestCategory(for: ingredient)
        let isAdded = addedIngredients.contains(ingredient)
        
        return HStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    selectedIngredient = ingredient
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: categoryIcon(for: category))
                        .foregroundColor(categoryColor(for: category))
                        .font(.body)
                    
                    Text(ingredient)
                        .font(.body)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    Text("\(recipeCount(for: ingredient))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(AppTheme.accentColor)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Basket button
            Button(action: {
                addToShoppingList(ingredient)
            }) {
                Image(systemName: isAdded ? "basket.fill" : "basket")
                    .foregroundColor(isAdded ? AppTheme.accentColor : (colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5)))
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .scaleEffect(isAdded ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAdded)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        )
    }
    
    private func addToShoppingList(_ ingredient: String) {
        shoppingListManager.addItem(name: ingredient)
        addedIngredients.insert(ingredient)
        showAddedFeedback = ingredient
        
        // Remove the visual feedback after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if self.showAddedFeedback == ingredient {
                self.showAddedFeedback = nil
            }
        }
        
        // Reset the added state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.addedIngredients.remove(ingredient)
        }
    }
    
    private func recipeCount(for ingredient: String) -> Int {
        recipes.filter { recipe in
            recipe.ingredients.contains { $0.name.localizedCaseInsensitiveContains(ingredient) }
        }.count
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Produce": return "leaf.fill"
        case "Meat & Seafood": return "fish.fill"
        case "Dairy & Eggs": return "drop.fill"
        case "Bakery": return "birthday.cake.fill"
    case "Kitchen": return "cabinet.fill"
        case "Frozen": return "snowflake"
        case "Beverages": return "cup.and.saucer.fill"
        case "Spices & Seasonings": return "sparkles"
        default: return "basket.fill"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Produce": return .green
        case "Meat & Seafood": return .red
        case "Dairy & Eggs": return .blue
        case "Bakery": return .orange
    case "Kitchen": return .brown
        case "Frozen": return .cyan
        case "Beverages": return .purple
        case "Spices & Seasonings": return .yellow
        default: return .gray
        }
    }
    
    private func clearAllFilters() {
        withAnimation(.spring(response: 0.3)) {
            selectedCategories.removeAll()
        }
    }
    
    private var recipeResultsView: some View {
        VStack(spacing: 0) {
            // Back button with selected ingredient
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedIngredient = nil
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.body)
                        Text("Back")
                            .font(.body)
                    }
                    .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                Spacer()
                
                if !filteredRecipes.isEmpty {
                    Menu {
                        ForEach(RecipeViewMode.allCases, id: \.self) { mode in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    viewMode = mode
                                }
                            }) {
                                Label(mode.rawValue, systemImage: mode.icon)
                            }
                        }
                    } label: {
                        Image(systemName: viewMode.icon)
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // Selected ingredient header
            if let ingredient = selectedIngredient {
                HStack(spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.title3)
                    
                    Text(ingredient)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(filteredRecipes.count) recipe\(filteredRecipes.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            
            // Recipe results
            ScrollView {
                if viewMode == .list {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe, shoppingListManager: shoppingListManager)) {
                                RecipeCard(recipe: recipe, viewMode: .list)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(filteredRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe, shoppingListManager: shoppingListManager)) {
                                CompactRecipeCard(recipe: recipe)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

// MARK: - Quick Match Recipe Card Component
struct QuickMatchRecipeCard: View {
    let recipe: RecipeModel
    let matchPercentage: Double
    @Environment(\.colorScheme) var colorScheme
    
    private var backgroundFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white
    }
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : Color.gray.opacity(0.15)
    }
    
    private var shadowOpacity: Double {
        colorScheme == .dark ? 0.3 : 0.08
    }
    
    var body: some View {
        VStack(spacing: 0) {
            imageSection
            contentSection
        }
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(shadowOpacity), radius: 8, x: 0, y: 4)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            RecipeImageView(imageName: recipe.imageName, height: 160)
                .frame(width: 220, height: 160)
                .clipped()
            
            matchBadge
        }
    }
    
    private var matchBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.white)
            
            Text("\(Int(matchPercentage * 100))%")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.green))
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        .padding(10)
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            recipeNameText
            metadataRow
        }
        .padding(12)
        .frame(width: 220, alignment: .leading)
        .background(contentBackground)
    }
    
    private var contentBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.05) : Color.white
    }
    
    private var recipeNameText: some View {
        Text(recipe.name)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(height: 40, alignment: .top)
    }
    
    private var metadataRow: some View {
        HStack(spacing: 6) {
            timeInfo
            
            Text("•")
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.4) : .black.opacity(0.4))
            
            categoryText
        }
    }
    
    private var timeInfo: some View {
        HStack(spacing: 3) {
            Image(systemName: "clock.fill")
                .font(.caption2)
                .foregroundColor(.orange)
            Text(recipe.prepTime)
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
        }
    }
    
    private var categoryText: some View {
        Text(recipe.category)
            .font(.caption)
            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
            .lineLimit(1)
    }
}

// MARK: - Category Card Component
struct CategoryCard: View {
    let category: String
    let ingredients: [String]
    @ObservedObject var shoppingListManager: ShoppingListManager
    @ObservedObject var pantryManager: KitchenInventoryManager
    @Binding var addedIngredients: Set<String>
    let onSelectIngredient: (String) -> Void
    let onAddToShoppingList: (String) -> Void
    let getVariations: (String) -> [String]
    @State private var isExpanded = false
    @State private var expandedIngredients: Set<String> = []
    @Environment(\.colorScheme) var colorScheme
    
    var categoryIcon: String {
        switch category {
        case "Proteins": return "fork.knife"
        case "Vegetables": return "carrot.fill"
        case "Spices & Herbs": return "leaf.fill"
        case "Dairy & Eggs": return "cup.and.saucer.fill"
        case "Grains & Noodles": return "takeoutbag.and.cup.and.straw.fill"
        case "Sauces & Condiments": return "drop.fill"
        default: return "bag.fill"
        }
    }
    
    var categoryColor: Color {
        switch category {
        case "Proteins": return .red
        case "Vegetables": return .green
        case "Spices & Herbs": return .orange
        case "Dairy & Eggs": return .blue
        case "Grains & Noodles": return .yellow
        case "Sauces & Condiments": return .purple
        default: return AppTheme.accentColor
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Header - Tappable
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(categoryColor.opacity(0.3))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: categoryIcon)
                            .foregroundColor(categoryColor)
                            .font(.title3)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category)
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Text("\(ingredients.count) ingredient\(ingredients.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                        .font(.caption)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Ingredients List
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(ingredients, id: \.self) { mainIngredient in
                        ingredientGroup(mainIngredient)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func ingredientGroup(_ mainIngredient: String) -> some View {
        let variations = getVariations(mainIngredient)
        let isGroupExpanded = expandedIngredients.contains(mainIngredient)
        
        return VStack(spacing: 4) {
            // Main ingredient row
            HStack(spacing: 0) {
                Button(action: {
                    if variations.count > 1 {
                        withAnimation(.spring(response: 0.3)) {
                            if isGroupExpanded {
                                expandedIngredients.remove(mainIngredient)
                            } else {
                                expandedIngredients.insert(mainIngredient)
                            }
                        }
                    } else if variations.count == 1 {
                        onSelectIngredient(variations[0])
                    }
                }) {
                    HStack(spacing: 12) {
                        Text(mainIngredient)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.95) : .black.opacity(0.9))
                        
                        // Kitchen indicator
                        if variations.contains(where: { pantryManager.hasItem($0) }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        if variations.count > 1 {
                            Text("(\(variations.count))")
                                .font(.caption)
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.4))
                        }
                        
                        Spacer()
                        
                        if variations.count > 1 {
                            Image(systemName: isGroupExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Basket button for single variation
                if variations.count == 1 {
                    let ingredient = variations[0]
                    let isAdded = addedIngredients.contains(ingredient)
                    
                    Button(action: {
                        onAddToShoppingList(ingredient)
                    }) {
                        Image(systemName: isAdded ? "basket.fill" : "basket")
                            .foregroundColor(isAdded ? AppTheme.accentColor : (colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5)))
                            .font(.system(size: 18))
                            .frame(width: 44, height: 44)
                            .scaleEffect(isAdded ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAdded)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
            )
            
            // Sub-ingredients (variations)
            if isGroupExpanded && variations.count > 1 {
                VStack(spacing: 4) {
                    ForEach(variations, id: \.self) { variation in
                        variationRow(variation)
                    }
                }
                .padding(.leading, 20)
            }
        }
    }
    
    private func variationRow(_ ingredient: String) -> some View {
        let isAdded = addedIngredients.contains(ingredient)
        
        return HStack(spacing: 0) {
            Button(action: {
                onSelectIngredient(ingredient)
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 4))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.4))
                    
                    Text(ingredient)
                        .font(.subheadline)
                        .fontWeight(.regular)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.85) : .black.opacity(0.75))
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Basket button
            Button(action: {
                onAddToShoppingList(ingredient)
            }) {
                Image(systemName: isAdded ? "basket.fill" : "basket")
                    .foregroundColor(isAdded ? AppTheme.accentColor : (colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5)))
                    .font(.system(size: 18))
                    .frame(width: 44, height: 44)
                    .scaleEffect(isAdded ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAdded)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
        )
    }
}

// MARK: - Ingredient Filter Sheet
struct IngredientFilterSheet: View {
    let categories: [String]
    @Binding var selectedCategories: Set<String>
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Categories Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ingredient Categories")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(categories, id: \.self) { category in
                                    FilterButton(
                                        label: category,
                                        icon: categoryIcon(for: CategoryClassifier.suggestCategory(for: category.lowercased())),
                                        color: categoryColor(for: CategoryClassifier.suggestCategory(for: category.lowercased())),
                                        isSelected: selectedCategories.contains(category)
                                    ) {
                                        if selectedCategories.contains(category) {
                                            selectedCategories.remove(category)
                                        } else {
                                            selectedCategories.insert(category)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Filter Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !selectedCategories.isEmpty {
                        Button("Clear All") {
                            selectedCategories.removeAll()
                        }
                        .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "produce": return "leaf.fill"
        case "meat & seafood": return "fish.fill"
        case "dairy & eggs": return "drop.fill"
        case "bakery": return "birthday.cake.fill"
    case "kitchen": return "shippingbox.fill"
        case "frozen": return "snowflake"
        case "beverages": return "cup.and.saucer.fill"
        case "spices & herbs": return "sparkles"
        default: return "tag.fill"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "produce": return .green
        case "meat & seafood": return .red
        case "dairy & eggs": return .blue
        case "bakery": return .orange
    case "kitchen": return .brown
        case "frozen": return .cyan
        case "beverages": return .purple
        case "spices & herbs": return .yellow
        default: return .gray
        }
    }
}
