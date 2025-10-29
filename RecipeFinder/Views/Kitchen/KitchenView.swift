// swiftlint:disable file_length
import SwiftUI

struct KitchenView: View {
    @Binding var recipes: [RecipeModel]
    @ObservedObject var shoppingListManager: ShoppingListManager
    @StateObject private var kitchenManager = KitchenInventoryManager()
    @State private var searchText = ""
    @State private var cachedCategorizedIngredients: [(category: String, ingredients: [String])] = []
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var allIngredients: [String] {
        Set(recipes.flatMap { $0.ingredients.map { $0.name } }).sorted()
    }
    
    var categorizedIngredients: [(category: String, ingredients: [String])] {
        // Return cached value if available
        guard cachedCategorizedIngredients.isEmpty else {
            return cachedCategorizedIngredients
        }
        
        // Compute and cache
        let result: [(category: String, ingredients: [String])] =
            CategoryClassifier.kitchenCategories.compactMap { category -> (category: String, ingredients: [String])? in
            guard let keywords = CategoryClassifier.kitchenIngredientKeywords[category] else { return nil }
            let matchedIngredients = allIngredients.filter { ingredient in
                // Filter out descriptor-only words
                guard CategoryClassifier.isValidIngredient(ingredient) else { return false }
                
                return keywords.contains { keyword in
                    ingredient.localizedCaseInsensitiveContains(keyword)
                }
            }
            let grouped = CategoryClassifier.groupSimilarIngredients(matchedIngredients)
            return grouped.isEmpty ? nil : (category, grouped.sorted())
        }
        
        return result
    }
    
    var searchResults: [String] {
        if searchText.isEmpty {
            return []
        }
        return allIngredients.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var quickMatchRecipes: [RecipeModel] {
        guard !kitchenManager.items.isEmpty else { return [] }
        
        let kitchenIngredients = Set(kitchenManager.items.map { $0.name.lowercased() })
        
        return recipes.filter { recipe in
            let recipeIngredients = recipe.ingredients.map { $0.name.lowercased() }
            let matchCount = recipeIngredients.filter { recipeIng in
                kitchenIngredients.contains { kitchenIng in
                    recipeIng.contains(kitchenIng) || kitchenIng.contains(recipeIng)
                }
            }.count
            let percentage = Double(matchCount) / Double(recipeIngredients.count)
            return matchCount >= 2 || percentage >= 0.2
        }.sorted { recipe1, recipe2 in
            matchPercentage(recipe: recipe1, kitchenIngredients: kitchenIngredients) >
            matchPercentage(recipe: recipe2, kitchenIngredients: kitchenIngredients)
        }
    }
    
    private func matchPercentage(recipe: RecipeModel, kitchenIngredients: Set<String>) -> Double {
        let recipeIngredients = recipe.ingredients.map { $0.name.lowercased() }
        let matchCount = recipeIngredients.filter { recipeIng in
            kitchenIngredients.contains { kitchenIng in
                recipeIng.contains(kitchenIng) || kitchenIng.contains(recipeIng)
            }
        }.count
        return Double(matchCount) / Double(recipeIngredients.count)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    header
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if kitchenManager.items.isEmpty && searchText.isEmpty {
                                emptyStateView
                            } else if !searchText.isEmpty {
                                searchResultsView
                            } else {
                                if !quickMatchRecipes.isEmpty {
                                    quickRecipeMatchesView
                                        .padding(.top, 8)
                                }
                                kitchenItemsView
                            }
                            
                            if searchText.isEmpty {
                                quickAddSection
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear {
            // Cache categorized ingredients on first load
            if cachedCategorizedIngredients.isEmpty {
                cachedCategorizedIngredients = categorizedIngredients
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            ZStack {
                HStack {
                    Spacer()
                    if !kitchenManager.items.isEmpty {
                        Menu {
                            Button(
                                role: .destructive,
                                action: {
                                    kitchenManager.clearAll()
                                },
                                label: {
                                    Label("Clear All", systemImage: "trash")
                                }
                            )
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background {
                                    if cardStyle == .solid {
                                        Circle()
                                            .fill(colorScheme == .dark ? Color(white: 0.2) : Color.white.opacity(0.9))
                                    } else {
                                        Circle()
                                            .fill(.regularMaterial)
                                    }
                                }
                        }
                    }
                }

                Text("Kitchen")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            
            ModernSearchBar(text: $searchText, placeholder: "Search kitchen ingredients...")
                .padding(.horizontal, 20)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "refrigerator")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Your Kitchen is Empty")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Add ingredients you have at home to see recipe suggestions")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var kitchenItemsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Items in Your Kitchen")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            ForEach(kitchenManager.groupedItems, id: \.category) { group in
                KitchenCategoryCard(
                    category: group.category,
                    items: group.items,
                    kitchenManager: kitchenManager
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Results")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            if searchResults.isEmpty {
                Text("No ingredients found")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(searchResults, id: \.self) { ingredient in
                        kitchenIngredientButton(ingredient)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var quickRecipeMatchesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.yellow)
                    
                    Text("Quick Recipe Matches")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text(matchCountText)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .padding(.horizontal, 20)
            
                ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(quickMatchRecipes.prefix(10)) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe, shoppingListManager: shoppingListManager, onFavoriteToggle: {
                            // Refresh recipes when favorite is toggled
                            recipes = PersistenceController.shared.fetchRecipes()
                        })) {
                            QuickMatchRecipeCard(
                                recipe: recipe,
                                matchPercentage: matchPercentage(
                                    recipe: recipe,
                                    kitchenIngredients: Set(kitchenManager.items.map { $0.name.lowercased() })
                                )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var matchCountText: String {
        let count = quickMatchRecipes.count
        if count == 1 {
            return "You can make this recipe right now!"
        } else {
            return "You can make \(count) recipes right now!"
        }
    }
    
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Add to Kitchen")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            ForEach(categorizedIngredients, id: \.category) { category, ingredients in
                KitchenQuickAddCategoryCard(
                    category: category,
                    ingredients: ingredients,
                    kitchenManager: kitchenManager
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func kitchenIngredientButton(_ ingredient: String) -> some View {
        let isInKitchen = kitchenManager.hasItem(ingredient)
        let category = CategoryClassifier.suggestCategory(for: ingredient)
        
        return Button(
            action: {
                withAnimation(.spring(response: 0.3)) {
                    kitchenManager.toggleItem(ingredient)
                }
            },
            label: {
                HStack(spacing: 12) {
                    Image(systemName: categoryIcon(for: category))
                        .foregroundColor(categoryColor(for: category))
                        .font(.body)
                    
                    Text(ingredient)
                        .font(.body)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    Image(systemName: isInKitchen ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundColor(isInKitchen ? .green : AppTheme.accentColor)
                        .font(.title3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background {
                    if cardStyle == .solid {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.regularMaterial)
                    }
                }
            }
        )
        .buttonStyle(PlainButtonStyle())
    }
    
    private func categoryIcon(for category: String) -> String {
        CategoryClassifier.categoryIcon(for: category)
    }
    
    private func categoryColor(for category: String) -> Color {
        CategoryClassifier.categoryColor(for: category)
    }
}

// Kitchen Category Card
struct KitchenCategoryCard: View {
    let category: String
    let items: [KitchenItem]
    @ObservedObject var kitchenManager: KitchenInventoryManager
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(CategoryClassifier.categoryColor(for: category).opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: CategoryClassifier.categoryIcon(for: category))
                            .foregroundColor(CategoryClassifier.categoryColor(for: category))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text("\(items.count) items")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            FlowLayout(spacing: 8) {
                ForEach(items) { item in
                    KitchenItemChip(item: item, kitchenManager: kitchenManager)
                }
            }
        }
        .padding(16)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            }
        }
    }
}

struct KitchenItemChip: View {
    let item: KitchenItem
    @ObservedObject var kitchenManager: KitchenInventoryManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            Text(item.name)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Button(
                action: {
                    withAnimation(.spring(response: 0.3)) {
                        kitchenManager.removeItem(item)
                    }
                },
                label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppTheme.accentColor.opacity(0.2))
        )
    }
}

struct KitchenQuickAddCategoryCard: View {
    let category: String
    let ingredients: [String]
    @ObservedObject var kitchenManager: KitchenInventoryManager
    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(
                action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                },
                label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(CategoryClassifier.categoryColor(for: category).opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: CategoryClassifier.categoryIcon(for: category))
                                    .foregroundColor(CategoryClassifier.categoryColor(for: category))
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category)
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("\(ingredients.count) ingredients")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.gray)
                    }
                }
            )
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                FlowLayout(spacing: 8) {
                    ForEach(ingredients, id: \.self) { ingredient in
                        KitchenQuickAddChip(ingredient: ingredient, kitchenManager: kitchenManager)
                    }
                }
            }
        }
        .padding(16)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            }
        }
    }
}

// Kitchen Quick Add Chip
struct KitchenQuickAddChip: View {
    let ingredient: String
    @ObservedObject var kitchenManager: KitchenInventoryManager
    @Environment(\.colorScheme) var colorScheme
    
    var isInKitchen: Bool {
        kitchenManager.hasItem(ingredient)
    }
    
    var body: some View {
        Button(
            action: {
                withAnimation(.spring(response: 0.3)) {
                    kitchenManager.toggleItem(ingredient)
                }
            },
            label: {
                HStack(spacing: 6) {
                    Text(ingredient)
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Image(systemName: isInKitchen ? "checkmark.circle.fill" : "plus.circle")
                        .font(.caption)
                        .foregroundColor(isInKitchen ? .green : .gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isInKitchen ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                )
            }
        )
        .buttonStyle(PlainButtonStyle())
    }
}
