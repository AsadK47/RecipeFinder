import SwiftUI

struct IngredientSearchView: View {
    @Binding var recipes: [RecipeModel]
    @State private var searchText = ""
    @State private var viewMode: RecipeViewMode = .list
    @State private var selectedIngredient: String?
    @State private var showAllIngredients = false
    @State private var showFilters = false
    @State private var selectedCategories: Set<String> = []
    @State private var addedIngredients: Set<String> = []
    @State private var showAddedFeedback: String?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var allIngredients: [String] {
        Set(recipes.flatMap { $0.ingredients.map { $0.name } }).sorted()
    }
    
    var popularIngredients: [String] {
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
            let grouped = CategoryClassifier.groupSimilarIngredients(matchedIngredients)
            return grouped.isEmpty ? nil : (category, grouped.sorted())
        }
    }
    
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
        Array(repeating: GridItem(.flexible(), spacing: AppTheme.spacing12), count: viewMode.columns)
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
                                            icon: categoryIcon(for: CategoryClassifier.suggestCategory(for: category.lowercased()))
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
                        ingredientButton(ingredient)
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
                            getVariations: getIngredientVariations
                        )
                    }
                }
                .padding(.horizontal, AppTheme.spacing20)
            }
            .padding(.vertical, AppTheme.spacing16)
        }
    }
    
    private func ingredientButton(_ ingredient: String) -> some View {
        let category = CategoryClassifier.suggestCategory(for: ingredient)
        let isAdded = addedIngredients.contains(ingredient)
        
        return HStack(spacing: 0) {
            Button(
                action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedIngredient = ingredient
                    }
                },
                label: {
                    HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: categoryIcon(for: category))
                        .foregroundColor(categoryColor(for: category))
                        .font(.body)
                    
                    Text(ingredient)
                        .font(.body)
                        .adaptiveForegroundColor()
                    
                    Spacer()
                    
                    Text("\(recipeCount(for: ingredient))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .padding(.horizontal, AppTheme.spacing10)
                        .padding(.vertical, AppTheme.spacing5)
                        .background(
                            Capsule()
                                .fill(AppTheme.accentColor)
                        )
                }
                .padding(.horizontal, AppTheme.spacing16)
                .padding(.vertical, AppTheme.spacing14)
            })
            .buttonStyle(PlainButtonStyle())
            
            Button(
                action: {
                    addToShoppingList(ingredient)
                },
                label: {
                    Image(systemName: isAdded ? "basket.fill" : "basket")
                        .foregroundColor(isAdded ? AppTheme.accentColor : (AppTheme.adaptiveSubtitle(for: colorScheme)))
                        .font(.system(size: AppTheme.fontSize20))
                        .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                        .scaleEffect(isAdded ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAdded)
                }
            )
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, AppTheme.spacing12)
        }
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(AppTheme.cardBackground(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(.regularMaterial)
            }
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
    
    private func recipeCount(for ingredient: String) -> Int {
        recipes.filter { recipe in
            recipe.ingredients.contains { $0.name.localizedCaseInsensitiveContains(ingredient) }
        }.count
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Produce": return "leaf.fill"
        case "Meat": return "fork.knife.circle.fill"
        case "Seafood": return "fish.fill"
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
        case "Meat": return .red
        case "Seafood": return .blue
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
            HStack {
                Button(
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedIngredient = nil
                        }
                    },
                    label: {
                        HStack(spacing: AppTheme.spacing8) {
                            Image(systemName: "chevron.left")
                                .font(.body)
                            Text("Back")
                                .font(.body)
                        }
                        .adaptiveForegroundColor()
                    }
                )
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.vertical, AppTheme.spacing12)
                
                Spacer()
                
                if !filteredRecipes.isEmpty {
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
                    .padding(.horizontal, AppTheme.spacing20)
                }
            }
            
            if let ingredient = selectedIngredient {
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: "leaf.fill")
                        .adaptiveForegroundColor()
                        .font(.title3)
                    
                    Text(ingredient)
                        .font(.title2)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()
                    
                    Spacer()
                    
                    Text("\(filteredRecipes.count) recipe\(filteredRecipes.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                }
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.bottom, AppTheme.spacing16)
            }
            
            ScrollView {
                if viewMode == .list {
                    LazyVStack(spacing: AppTheme.spacing16) {
                        ForEach(filteredRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                RecipeCard(recipe: recipe, viewMode: .list)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: AppTheme.spacing16) {
                        ForEach(filteredRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                CompactRecipeCard(recipe: recipe)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.vertical, AppTheme.spacing8)
                }
            }
        }
    }
}

struct QuickMatchRecipeCard: View {
    let recipe: RecipeModel
    let matchCount: Int
    let totalIngredients: Int
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    private var borderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.15) : AppTheme.secondaryText.opacity(0.15)
    }
    
    private var shadowOpacity: Double {
        cardStyle == .solid ? 0.25 : (colorScheme == .dark ? 0.2 : 0.15)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            imageSection
            contentSection
        }
        .frame(width: AppTheme.width220)
        .background {
            cardBackground
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(shadowOpacity), radius: AppTheme.shadowRadiusLarge, x: 0, y: AppTheme.shadowOffsetLarge)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius16))
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        if cardStyle == .solid {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                .fill(AppTheme.cardBackground(for: colorScheme))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(colorScheme == .dark ? Color.black.opacity(AppTheme.cardDarkOpacity) : Color.white.opacity(AppTheme.shadowDarkOpacity))
                
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(.regularMaterial)
            }
        }
    }
    
    private var imageSection: some View {
        ZStack(alignment: .topTrailing) {
            RecipeImageView(imageName: recipe.imageName, height: AppTheme.height160)
                .frame(width: AppTheme.width220, height: AppTheme.height160)
                .clipped()
            
            matchBadge
        }
    }
    
    private var matchBadge: some View {
        HStack(spacing: AppTheme.spacing4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .adaptiveForegroundColor()
            
            Text("\(matchCount)/\(totalIngredients)")
                .font(.caption2)
                .fontWeight(.bold)
                .adaptiveForegroundColor()
        }
        .padding(.horizontal, AppTheme.spacing8)
        .padding(.vertical, AppTheme.spacing4)
        .background(Capsule().fill(Color.green))
        .shadow(color: Color.black.opacity(AppTheme.overlayLightOpacity), radius: 4, x: 0, y: 2)
        .padding(AppTheme.spacing10)
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            recipeNameText
            metadataRow
        }
        .padding(AppTheme.spacing12)
        .frame(width: AppTheme.width220, alignment: .leading)
        .background(contentBackground)
    }
    
    private var contentBackground: Color {
        colorScheme == .dark ? Color.white.opacity(AppTheme.glassSubtleOpacity) : Color.white
    }
    
    private var recipeNameText: some View {
        Text(recipe.name)
            .font(.headline)
            .fontWeight(.semibold)
            .adaptiveForegroundColor()
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(height: AppTheme.height40, alignment: .top)
    }
    
    private var metadataRow: some View {
        HStack(spacing: AppTheme.spacing6) {
            timeInfo
            
            Text("•")
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.lowEmphasisOpacity) : .black.opacity(AppTheme.lowEmphasisOpacity))
            
            categoryText
        }
    }
    
    private var timeInfo: some View {
        HStack(spacing: AppTheme.spacing3) {
            Image(systemName: "clock.fill")
                .font(.caption2)
                .foregroundColor(.orange)
            Text(recipe.prepTime)
                .font(.caption)
                .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
        }
    }
    
    private var categoryText: some View {
        Text(recipe.category)
            .font(.caption)
            .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
            .lineLimit(1)
    }
}

struct CategoryCard: View {
    let category: String
    let ingredients: [String]
    @Binding var addedIngredients: Set<String>
    let onSelectIngredient: (String) -> Void
    let onAddToShoppingList: (String) -> Void
    let getVariations: (String) -> [String]
    @State private var isExpanded = false
    @State private var expandedIngredients: Set<String> = []
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var categoryIcon: String {
        switch category {
        case "Meat": return "fork.knife.circle.fill"
        case "Seafood": return "fish.fill"
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
        case "Meat": return .red
        case "Seafood": return .blue
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
            Button(
                action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                },
                label: {
                    HStack(spacing: AppTheme.spacing16) {
                        ZStack {
                            Circle()
                                .fill(categoryColor.opacity(AppTheme.shadowDarkOpacity))
                                .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                            
                            Image(systemName: categoryIcon)
                                .foregroundColor(categoryColor)
                                .font(.title3)
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                            Text(category)
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            Text("\(ingredients.count) ingredient\(ingredients.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
                        }
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
                            .font(.caption)
                    }
                    .padding(AppTheme.spacing16)
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(AppTheme.cardBackground(for: colorScheme))
                        } else {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(.regularMaterial)
                        }
                    }
                }
            )
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: AppTheme.spacing8) {
                    ForEach(ingredients, id: \.self) { mainIngredient in
                        ingredientGroup(mainIngredient)
                    }
                }
                .padding(.top, AppTheme.spacing8)
            }
        }
    }
    
    private func ingredientGroup(_ mainIngredient: String) -> some View {
        let variations = getVariations(mainIngredient)
        let isGroupExpanded = expandedIngredients.contains(mainIngredient)
        
        return VStack(spacing: AppTheme.spacing4) {
            HStack(spacing: 0) {
                Button(
                    action: {
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
                    HStack(spacing: AppTheme.spacing12) {
                        Text(mainIngredient)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.cardLightHighOpacity) : .black.opacity(0.9))
                        
                        if variations.contains(where: { KitchenInventoryManager.shared.hasItem($0) }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        if variations.count > 1 {
                            Text("(\(variations.count))")
                                .font(.caption)
                                .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                        }
                        
                        Spacer()
                        
                        if variations.count > 1 {
                            Image(systemName: isGroupExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing16)
                    .padding(.vertical, AppTheme.spacing12)
                }
                .buttonStyle(PlainButtonStyle())
                
                if variations.count == 1 {
                    let ingredient = variations[0]
                    let isAdded = addedIngredients.contains(ingredient)
                    
                    Button(
                        action: {
                            onAddToShoppingList(ingredient)
                        },
                        label: {
                            Image(systemName: isAdded ? "basket.fill" : "basket")
                                .foregroundColor(isAdded ? AppTheme.accentColor : (AppTheme.adaptiveSubtitle(for: colorScheme)))
                                .font(.system(size: AppTheme.fontSize18))
                                .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                                .scaleEffect(isAdded ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAdded)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, AppTheme.spacing12)
                }
            }
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                        .fill(AppTheme.cardBackground(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                        .fill(.regularMaterial)
                }
            }
            
            if isGroupExpanded && variations.count > 1 {
                VStack(spacing: AppTheme.spacing4) {
                    ForEach(variations, id: \.self) { variation in
                        variationRow(variation)
                    }
                }
                .padding(.leading, AppTheme.spacing20)
            }
        }
    }
    
    private func variationRow(_ ingredient: String) -> some View {
        let isAdded = addedIngredients.contains(ingredient)
        
        return HStack(spacing: 0) {
            Button(
                action: {
                    onSelectIngredient(ingredient)
                },
                label: {
                    HStack(spacing: AppTheme.spacing12) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: AppTheme.fontSize4))
                            .foregroundColor(AppTheme.adaptiveSecondaryIndicator(for: colorScheme))
                        
                        Text(ingredient)
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme, level: colorScheme == .dark ? 0.85 : 0.75))
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.spacing16)
                    .padding(.vertical, AppTheme.spacing12)
                }
            )
            .buttonStyle(PlainButtonStyle())
            
            Button(
                action: {
                    onAddToShoppingList(ingredient)
                },
                label: {
                    Image(systemName: isAdded ? "basket.fill" : "basket")
                        .foregroundColor(isAdded ? AppTheme.accentColor : (AppTheme.adaptiveSubtitle(for: colorScheme)))
                        .font(.system(size: AppTheme.fontSize18))
                        .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                        .scaleEffect(isAdded ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAdded)
                }
            )
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, AppTheme.spacing12)
        }
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                    .fill(AppTheme.cardBackground(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                    .fill(.regularMaterial)
            }
        }
    }
}

struct IngredientFilterSheet: View {
    let categories: [String]
    @Binding var selectedCategories: Set<String>
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacing32) {
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            Text("Ingredient Categories")
                                .font(.headline)
                                .adaptiveForegroundColor()
                                .padding(.horizontal, AppTheme.spacing20)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: AppTheme.spacing12) {
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
                            .padding(.horizontal, AppTheme.spacing20)
                        }
                    }
                    .padding(.vertical, AppTheme.spacing20)
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
                    .adaptiveForegroundColor()
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !selectedCategories.isEmpty {
                        Button("Clear All") {
                            selectedCategories.removeAll()
                        }
                        .adaptiveForegroundColor()
                    }
                }
            }
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "produce": return "leaf.fill"
        case "meat": return "fork.knife.circle.fill"
        case "seafood": return "fish.fill"
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
        case "meat": return .red
        case "seafood": return .blue
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
