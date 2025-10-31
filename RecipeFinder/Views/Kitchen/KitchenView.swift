import SwiftUI

struct KitchenView: View {
    @Binding var recipes: [RecipeModel]
    @ObservedObject var shoppingListManager: ShoppingListManager
    @StateObject private var kitchenManager = KitchenInventoryManager()
    @State private var searchText = ""
    @State private var showAddIngredientSheet = false
    @State private var cachedCategorizedIngredients: [(category: String, ingredients: [String])] = []
    @State private var collapsedCategories: Set<String> = []
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    // Use USDA foods list instead of recipe ingredients
    var allIngredients: [String] {
        USDAFoodsList.getAllFoods()
    }
    
    var categorizedIngredients: [(category: String, ingredients: [String])] {
        // Return cached value if available
        guard cachedCategorizedIngredients.isEmpty else {
            return cachedCategorizedIngredients
        }
        
        // Use USDA categorized foods
        var result: [(category: String, ingredients: [String])] = []
        
        for category in USDAFoodsList.categories {
            let foods = USDAFoodsList.getFoods(forCategory: category)
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
        return USDAFoodsList.searchFoods(query: searchText)
    }
    
    var quickMatchRecipes: [RecipeModel] {
        guard !kitchenManager.items.isEmpty else { return [] }
        
        let kitchenIngredients = Set(kitchenManager.items.map { $0.name.lowercased() })
        
        return recipes.filter { recipe in
            let recipeIngredients = recipe.ingredients.map { $0.name.lowercased() }
            // Show as soon as even 1 ingredient matches
            return recipeIngredients.contains { recipeIng in
                kitchenIngredients.contains { kitchenIng in
                    recipeIng.contains(kitchenIng) || kitchenIng.contains(recipeIng)
                }
            }
        }.sorted { recipe1, recipe2 in
            matchCount(recipe: recipe1, kitchenIngredients: kitchenIngredients) >
            matchCount(recipe: recipe2, kitchenIngredients: kitchenIngredients)
        }
    }
    
    private func matchCount(recipe: RecipeModel, kitchenIngredients: Set<String>) -> Int {
        let recipeIngredients = recipe.ingredients.map { $0.name.lowercased() }
        return recipeIngredients.filter { recipeIng in
            kitchenIngredients.contains { kitchenIng in
                recipeIng.contains(kitchenIng) || kitchenIng.contains(recipeIng)
            }
        }.count
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
                                // Recipe Matches at the TOP
                                if !quickMatchRecipes.isEmpty {
                                    quickRecipeMatchesView
                                }
                                
                                // Kitchen items grouped by category (collapsible)
                                kitchenItemsView
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showAddIngredientSheet) {
            AddIngredientSheet(kitchenManager: kitchenManager)
        }
        .onAppear {
            // Cache categorized ingredients on first load
            refreshCategorizedIngredients()
        }
    }
    
    private func refreshCategorizedIngredients() {
        cachedCategorizedIngredients = categorizedIngredients
    }
    
    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                
                Text("Kitchen")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Search bar
            ModernSearchBar(text: $searchText, placeholder: "Search ingredients...")
                .focused($isSearchFocused)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.clear, location: 0),
                    .init(color: Color.black.opacity(0.1), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "refrigerator")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.3))
                
                Text("Your Kitchen is Empty")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Search to add ingredients")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Suggestions
            VStack(alignment: .leading, spacing: 16) {
                Text("Popular Ingredients")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                LazyVStack(spacing: 8) {
                    ForEach(["Chicken", "Rice", "Tomato", "Onion", "Garlic", "Olive Oil"], id: \.self) { ingredient in
                        kitchenIngredientButton(ingredient)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
    
    private var kitchenItemsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(kitchenManager.groupedItems, id: \.category) { group in
                KitchenCategoryCard(
                    category: group.category,
                    items: group.items,
                    kitchenManager: kitchenManager,
                    isCollapsed: collapsedCategories.contains(group.category),
                    onToggleCollapse: {
                        withAnimation {
                            if collapsedCategories.contains(group.category) {
                                collapsedCategories.remove(group.category)
                            } else {
                                collapsedCategories.insert(group.category)
                            }
                        }
                    }
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
    
    private func kitchenIngredientButton(_ ingredient: String) -> some View {
        let isInKitchen = kitchenManager.hasItem(ingredient)
        let category = CategoryClassifier.suggestCategory(for: ingredient)
        
        return Button(
            action: {
                withAnimation(.spring(response: 0.3)) {
                    kitchenManager.toggleItem(ingredient)
                    HapticManager.shared.light()
                }
            },
            label: {
                HStack(spacing: 12) {
                    Image(systemName: CategoryClassifier.categoryIcon(for: category))
                        .foregroundStyle(CategoryClassifier.categoryColor(for: category))
                        .font(.body)
                    
                    Text(ingredient)
                        .font(.body)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    Image(systemName: isInKitchen ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundStyle(isInKitchen ? .green : AppTheme.accentColor(for: appTheme))
                        .font(.title3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                }
            }
        )
        .buttonStyle(PlainButtonStyle())
    }
    
    private var quickRecipeMatchesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundColor(.yellow)
                    
                    Text("Quick Recipe Matches")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(matchCountText)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                
                Text("Tap any recipe to view full details and cooking instructions")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.4),
                                Color.pink.opacity(0.3),
                                Color.orange.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
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
                                matchCount: matchCount(
                                    recipe: recipe,
                                    kitchenIngredients: Set(kitchenManager.items.map { $0.name.lowercased() })
                                ),
                                totalIngredients: recipe.ingredients.count
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
    
    private func shareKitchenInventory() {
        var text = "🏠 MY KITCHEN INVENTORY\n"
        text += String(repeating: "━", count: 40) + "\n\n"
        
        for group in kitchenManager.groupedItems {
            let icon = CategoryClassifier.categoryIcon(for: group.category)
            text += "\(icon) \(group.category.uppercased())\n"
            text += String(repeating: "─", count: 40) + "\n"
            
            for item in group.items {
                text += "  • \(item.name)\n"
            }
            text += "\n"
        }
        
        text += String(repeating: "━", count: 40) + "\n"
        text += "Created with RecipeFinder\n"
        
        // Use proper view finder
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        
        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        let activityController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        // iPad support
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = topController.view
            popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        topController.present(activityController, animated: true)
    }
}

// Kitchen Category Card
struct KitchenCategoryCard: View {
    let category: String
    let items: [KitchenItem]
    @ObservedObject var kitchenManager: KitchenInventoryManager
    let isCollapsed: Bool
    let onToggleCollapse: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggleCollapse) {
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
                    
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if !isCollapsed {
                FlowLayout(spacing: 8) {
                    ForEach(items) { item in
                        KitchenItemChip(item: item, kitchenManager: kitchenManager)
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

// MARK: - Add Ingredient Sheet
struct AddIngredientSheet: View {
    @ObservedObject var kitchenManager: KitchenInventoryManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    
    var filteredCategories: [String] {
        if !searchText.isEmpty {
            return []
        }
        return USDAFoodsList.categories
    }
    
    var searchResults: [String] {
        if searchText.isEmpty {
            return []
        }
        return USDAFoodsList.searchFoods(query: searchText)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    ModernSearchBar(text: $searchText, placeholder: "Search USDA foods...")
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                    
                    if !searchText.isEmpty {
                        // Search Results
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(searchResults, id: \.self) { food in
                                    foodButton(food)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                    } else if let category = selectedCategory {
                        // Category Foods
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                Button(action: {
                                    withAnimation {
                                        selectedCategory = nil
                                        HapticManager.shared.light()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                        Text("Back to Categories")
                                    }
                                    .foregroundColor(AppTheme.accentColor(for: appTheme))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                }
                                
                                Text(category)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(USDAFoodsList.getFoods(forCategory: category), id: \.self) { food in
                                        foodButton(food)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.vertical, 12)
                        }
                    } else {
                        // Categories List
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredCategories, id: \.self) { category in
                                    categoryButton(category)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .navigationTitle("Add Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor(for: appTheme))
                }
            }
        }
    }
    
    private func categoryButton(_ category: String) -> some View {
        Button(action: {
            withAnimation {
                selectedCategory = category
                HapticManager.shared.light()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: CategoryClassifier.categoryIcon(for: category))
                    .font(.title3)
                    .foregroundColor(CategoryClassifier.categoryColor(for: category))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text("\(USDAFoodsList.getFoods(forCategory: category).count) items")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
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
        .buttonStyle(PlainButtonStyle())
    }
    
    private func foodButton(_ food: String) -> some View {
        let isInKitchen = kitchenManager.hasItem(food)
        let category = USDAFoodsList.getCategoryForFood(food) ?? "Other"
        
        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                kitchenManager.toggleItem(food)
                HapticManager.shared.light()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: CategoryClassifier.categoryIcon(for: category))
                    .foregroundColor(CategoryClassifier.categoryColor(for: category))
                    .font(.body)
                
                Text(food)
                    .font(.body)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                Image(systemName: isInKitchen ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundColor(isInKitchen ? .green : AppTheme.accentColor(for: appTheme))
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
        .buttonStyle(PlainButtonStyle())
    }
}
