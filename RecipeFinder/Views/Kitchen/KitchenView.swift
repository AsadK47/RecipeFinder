import SwiftUI

struct KitchenView: View {
    @Binding var recipes: [RecipeModel]
    @ObservedObject var shoppingListManager: ShoppingListManager
    @StateObject private var kitchenManager = KitchenInventoryManager()
    @State private var searchText = ""
    @State private var showAddIngredientSheet = false
    @State private var cachedCategorizedIngredients: [(category: String, ingredients: [String])] = []
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
                                
                                // Quick Add section prominently shown when empty
                                quickAddSection
                                    .padding(.top, 16)
                            } else if !searchText.isEmpty {
                                searchResultsView
                            } else {
                                // Recipe Matches at the TOP (most important)
                                if !quickMatchRecipes.isEmpty {
                                    quickRecipeMatchesView
                                        .padding(.bottom, 8)
                                }
                                
                                // Quick Add section below recipe matches
                                quickAddSection
                                
                                // Kitchen items at the bottom
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
        VStack(spacing: 16) {
            ZStack {
                HStack {
                    // Add Ingredient button on the LEFT
                    Button(action: {
                        showAddIngredientSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(cardStyle == .solid && colorScheme == .light ? .black : .white)
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
                    
                    Spacer()
                    
                    // Options menu on the RIGHT (only show when kitchen has items)
                    if !kitchenManager.items.isEmpty {
                        Menu {
                            Button(action: shareKitchenInventory) {
                                Label("Share Kitchen", systemImage: "square.and.arrow.up")
                            }
                            
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
                                .foregroundColor(cardStyle == .solid && colorScheme == .light ? .black : .white)
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
            
            Text("Tap the + button above to add ingredients from the USDA-approved foods list")
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
                            colors: [
                                Color.purple.opacity(0.4),
                                Color.pink.opacity(0.3),
                                Color.orange.opacity(0.2)
                            ],
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
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                        .font(.title3)
                    
                    Text("Quick Add")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text("Browse \(USDAFoodsList.getAllFoods().count)+ USDA-approved ingredients")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            
            // Show top 5 most important categories
            ForEach(Array(categorizedIngredients.prefix(5).enumerated()), id: \.element.category) { index, element in
                KitchenQuickAddCategoryCard(
                    category: element.category,
                    ingredients: element.ingredients,
                    kitchenManager: kitchenManager,
                    defaultExpanded: false
                )
            }
            .padding(.horizontal, 20)
            
            // Show "More Categories" button if there are more than 5 categories
            if categorizedIngredients.count > 5 {
                Button(action: {
                    showAddIngredientSheet = true
                }) {
                    HStack {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppTheme.accentColor(for: appTheme))
                        
                        Text("More Categories")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Spacer()
                        
                        Text("\(categorizedIngredients.count - 5) more")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
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
    let defaultExpanded: Bool
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
        .onAppear {
            isExpanded = defaultExpanded
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
