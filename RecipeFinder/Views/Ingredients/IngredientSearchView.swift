import SwiftUI

struct IngredientSearchView: View {
    @Binding var recipes: [RecipeModel]
    @State private var searchText = ""
    @State private var viewMode: RecipeViewMode = .list
    @State private var selectedIngredient: String?
    @State private var showAllIngredients = false
    @Environment(\.colorScheme) var colorScheme
    
    // Ingredient categories
    let ingredientCategories: [String: [String]] = [
        "Proteins": ["chicken", "beef", "lamb", "mutton", "pork", "fish", "cod", "eggs", "tofu"],
        "Vegetables": ["onion", "tomato", "carrot", "cabbage", "potato", "bell pepper", "capsicum", "cucumber", "eggplant", "bok choy"],
        "Spices & Herbs": ["cumin", "coriander", "turmeric", "paprika", "ginger", "garlic", "chili", "cinnamon", "cardamom", "garam masala", "cilantro", "parsley", "mint", "basil"],
        "Dairy & Eggs": ["milk", "butter", "yogurt", "cream", "cheese", "egg"],
        "Grains & Noodles": ["rice", "flour", "noodles", "pasta", "bread", "oats"],
        "Sauces & Condiments": ["soy sauce", "oyster sauce", "vinegar", "ketchup", "mustard", "mayo"]
    ]
    
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
        ingredientCategories.compactMap { category, keywords in
            let matchedIngredients = allIngredients.filter { ingredient in
                keywords.contains { keyword in
                    ingredient.localizedCaseInsensitiveContains(keyword)
                }
            }
            return matchedIngredients.isEmpty ? nil : (category, matchedIngredients.sorted())
        }
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
                            // Empty spacer for alignment (only when menu is visible)
                            if selectedIngredient != nil {
                                Color.clear
                                    .frame(width: 48, height: 48)
                            }
                            
                            Spacer()
                            
                            Text("Search by Ingredient")
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
                                                .fill(.ultraThinMaterial)
                                        )
                                }
                            } else {
                                Color.clear
                                    .frame(width: 48, height: 48)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        ModernSearchBar(text: $searchText, placeholder: "What's in the fridge...?")
                            .padding(.horizontal, 20)
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
        }
    }
    
    // MARK: - Search Results View
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
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
            .padding()
        }
    }
    
    // MARK: - Main Ingredient Browser
    private var ingredientBrowserView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Popular Ingredients Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Popular Ingredients")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(popularIngredients, id: \.self) { ingredient in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedIngredient = ingredient
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(AppTheme.accentColor.opacity(0.2))
                                                .frame(width: 60, height: 60)
                                            
                                            Image(systemName: ingredientIcon(for: ingredient))
                                                .font(.title2)
                                                .foregroundColor(AppTheme.accentColor)
                                        }
                                        
                                        Text(ingredient)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                            .frame(width: 70)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // Categories Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Browse by Category")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    ForEach(categorizedIngredients, id: \.category) { category, ingredients in
                        CategoryCard(
                            category: category,
                            ingredients: ingredients,
                            onSelectIngredient: { ingredient in
                                withAnimation(.spring(response: 0.3)) {
                                    selectedIngredient = ingredient
                                }
                            }
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
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedIngredient = ingredient
            }
        }) {
            CardView {
                HStack(spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(AppTheme.accentColor.opacity(0.7))
                        .font(.body)
                    
                    Text(ingredient)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(recipeCount(for: ingredient))")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppTheme.accentColor)
                        )
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.accentColor.opacity(0.6))
                        .font(.caption)
                }
                .padding()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func ingredientIcon(for ingredient: String) -> String {
        let lowercased = ingredient.lowercased()
        if lowercased.contains("chicken") || lowercased.contains("beef") || lowercased.contains("lamb") || lowercased.contains("meat") {
            return "fork.knife"
        } else if lowercased.contains("onion") || lowercased.contains("tomato") || lowercased.contains("carrot") || lowercased.contains("pepper") {
            return "carrot.fill"
        } else if lowercased.contains("rice") || lowercased.contains("flour") || lowercased.contains("noodle") {
            return "takeoutbag.and.cup.and.straw.fill"
        } else if lowercased.contains("milk") || lowercased.contains("butter") || lowercased.contains("cream") || lowercased.contains("cheese") {
            return "cup.and.saucer.fill"
        } else {
            return "leaf.fill"
        }
    }
    
    private func recipeCount(for ingredient: String) -> Int {
        recipes.filter { recipe in
            recipe.ingredients.contains { $0.name.localizedCaseInsensitiveContains(ingredient) }
        }.count
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
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                RecipeCard(recipe: recipe, viewMode: .list)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(filteredRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
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

// MARK: - Category Card Component
struct CategoryCard: View {
    let category: String
    let ingredients: [String]
    let onSelectIngredient: (String) -> Void
    @State private var isExpanded = false
    
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
        CardView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(categoryColor.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: categoryIcon)
                                .foregroundColor(categoryColor)
                                .font(.title3)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("\(ingredients.count) ingredient\(ingredients.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Expanded ingredients
                if isExpanded {
                    VStack(spacing: 0) {
                        Divider()
                            .padding(.vertical, 12)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(ingredients, id: \.self) { ingredient in
                                Button(action: {
                                    onSelectIngredient(ingredient)
                                }) {
                                    Text(ingredient)
                                        .font(.subheadline)
                                        .foregroundColor(categoryColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(categoryColor.opacity(0.15))
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
        }
    }
}

// MARK: - Flow Layout for ingredient chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, subviewSize.height)
                currentX += subviewSize.width + spacing
                size.width = max(size.width, currentX - spacing)
            }
            
            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}
