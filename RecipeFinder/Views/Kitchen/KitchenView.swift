import SwiftUI

struct KitchenView: View {
    @Binding var recipes: [RecipeModel]
    @ObservedObject var shoppingListManager: ShoppingListManager
    @EnvironmentObject var kitchenManager: KitchenInventoryManager
    @State private var searchText = ""
    @State private var showAddIngredientSheet = false
    @State private var showQuickAdd = false
    @State private var cachedCategorizedIngredients: [(category: String, ingredients: [String])] = []
    @State private var selectedCategory: String? = nil
    @State private var collapsedCategories: Set<String> = []
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    // Use categorized foods list instead of recipe ingredients
    var allIngredients: [String] {
        FoodsList.getAllFoods()
    }
    
    var categorizedIngredients: [(category: String, ingredients: [String])] {
        // Return cached value if available
        guard cachedCategorizedIngredients.isEmpty else {
            return cachedCategorizedIngredients
        }
        
        // Use categorized foods
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
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                    VStack(spacing: 0) {
                    header
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            if let category = selectedCategory {
                                // Show ingredients from selected category
                                categoryIngredientsView(for: category)
                            } else if kitchenManager.items.isEmpty && searchText.isEmpty {
                                emptyPromptView
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
        .sheet(isPresented: $showQuickAdd) {
            KitchenQuickAddSheet(kitchenManager: kitchenManager)
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
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left spacer for balance - 15% of width or fixed size
                    Color.clear
                        .frame(width: max(44, geometry.size.width * 0.15))
                    
                    Spacer(minLength: 8)
                    
                    Text("Kitchen")
                        .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Spacer(minLength: 8)
                    
                    // Right menu - 15% of width or fixed size
                    Menu {
                        Button(action: {
                            showQuickAdd = true
                            HapticManager.shared.light()
                        }) {
                            Label("Quick Add", systemImage: "plus.circle")
                        }
                        
                        Button(action: {
                            isSearchFocused = true
                            HapticManager.shared.light()
                        }) {
                            Label("Search Ingredients", systemImage: "magnifyingglass")
                        }
                        
                        if !kitchenManager.items.isEmpty {
                            Divider()
                            
                            Button(role: .destructive, action: {
                                kitchenManager.clearAll()
                                HapticManager.shared.light()
                            }) {
                                Label("Clear Kitchen", systemImage: "trash")
                            }
                        }
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
            
            // Search bar with cancel option
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.6))
                        .font(.body)
                    
                    TextField("Search ingredients...", text: $searchText)
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
    }
    
    
    // MARK: - Empty Prompt
    private var emptyPromptView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "refrigerator")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.3))
                
                Text("Your Kitchen is Empty")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                
                Text("Add ingredients using Quick Add from the menu or browse categories below")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 20)
            
            // Browse Categories Grid
            browseCategoriesSection
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Browse Categories Section
    private var browseCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2")
                    .font(.caption)
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                Text("Browse by Category")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(FoodsList.categories.prefix(6), id: \.self) { category in
                    categoryCard(category)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "refrigerator")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.3))
                
                Text("Your Kitchen is Empty")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Add ingredients to see recipe matches")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // Browse Categories Grid
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.2x2")
                        .font(.caption)
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    Text("Browse by Category")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(FoodsList.categories.prefix(6), id: \.self) { category in
                        categoryCard(category)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func categoryCard(_ category: String) -> some View {
        Button(action: {
            withAnimation {
                selectedCategory = category
                HapticManager.shared.light()
            }
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(CategoryClassifier.categoryColor(for: category).opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: CategoryClassifier.categoryIcon(for: category))
                        .font(.system(size: 28))
                        .foregroundColor(CategoryClassifier.categoryColor(for: category))
                }
                
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(1)
                
                Text("\(FoodsList.getFoods(forCategory: category).count) items")
                    .font(.caption2)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.08), radius: 6, x: 0, y: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Category Ingredients View
    private func categoryIngredientsView(for category: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with back button and category info
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation {
                        selectedCategory = nil
                        HapticManager.shared.light()
                    }
                }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                Circle()
                    .fill(CategoryClassifier.categoryColor(for: category).opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: CategoryClassifier.categoryIcon(for: category))
                            .font(.title3)
                            .foregroundColor(CategoryClassifier.categoryColor(for: category))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(FoodsList.getFoods(forCategory: category).count) items")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // List of ingredients
            LazyVStack(spacing: 8) {
                ForEach(FoodsList.getFoods(forCategory: category), id: \.self) { ingredient in
                    categoryIngredientButton(ingredient)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func categoryIngredientButton(_ ingredient: String) -> some View {
        let isInKitchen = kitchenManager.hasItem(ingredient)
        let category = CategoryClassifier.suggestCategory(for: ingredient)
        
        return Button {
            withAnimation(.spring(response: 0.3)) {
                kitchenManager.toggleItem(ingredient)
                HapticManager.shared.light()
                
                // Go back to main view after adding
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        selectedCategory = nil
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                    Image(systemName: CategoryClassifier.categoryIcon(for: category))
                        .foregroundStyle(CategoryClassifier.categoryColor(for: category))
                        .font(.body)
                    
                    Text(ingredient)
                        .font(.body)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    Image(systemName: isInKitchen ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundStyle(isInKitchen ? .green : AppTheme.accentColor(for: selectedTheme))
                        .font(.title3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background {
                    if cardStyle == .solid {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    }
                }
            }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var kitchenItemsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Compact header with count and add button
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("My Kitchen")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(kitchenManager.items.count) ingredients")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    showAddIngredientSheet = true
                    HapticManager.shared.light()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                        Text("Add More")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentColor(for: selectedTheme))
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Category Groups
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
            
            // Browse more categories
            browseCategoriesSection
                .padding(.top, 8)
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
        
        return Button {
            withAnimation(.spring(response: 0.3)) {
                kitchenManager.toggleItem(ingredient)
                HapticManager.shared.light()
            }
        } label: {
            HStack(spacing: 12) {
                    Image(systemName: CategoryClassifier.categoryIcon(for: category))
                        .foregroundStyle(CategoryClassifier.categoryColor(for: category))
                        .font(.body)
                    
                    Text(ingredient)
                        .font(.body)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    Image(systemName: isInKitchen ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundStyle(isInKitchen ? .green : AppTheme.accentColor(for: selectedTheme))
                        .font(.title3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background {
                    if cardStyle == .solid {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    }
                }
            }
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
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
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
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    
    var filteredCategories: [String] {
        if !searchText.isEmpty {
            return []
        }
        return FoodsList.categories
    }
    
    var searchResults: [String] {
        if searchText.isEmpty {
            return []
        }
        return FoodsList.searchFoods(query: searchText)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    ModernSearchBar(text: $searchText, placeholder: "Search foods...")
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
                                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                }
                                
                                Text(category)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(FoodsList.getFoods(forCategory: category), id: \.self) { food in
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
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
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
                    
                    Text("\(FoodsList.getFoods(forCategory: category).count) items")
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
                        .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func foodButton(_ food: String) -> some View {
        let isInKitchen = kitchenManager.hasItem(food)
        let category = FoodsList.getCategoryForFood(food) ?? "Other"
        
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
                    .foregroundColor(isInKitchen ? .green : AppTheme.accentColor(for: selectedTheme))
                    .font(.title3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
