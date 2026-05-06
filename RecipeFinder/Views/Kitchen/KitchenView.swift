import SwiftUI

struct KitchenView: View {
    @Binding var recipes: [RecipeModel]
    @StateObject private var manager = KitchenInventoryManager.shared
    @State private var searchText = ""
    @State private var showAddIngredientSheet = false
    @State private var showQuickAdd = false
    @State private var cachedCategorizedIngredients: [(category: String, ingredients: [String])] = []
    @State private var collapsedCategories: Set<String> = []
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    var allIngredients: [String] {
        FoodsList.getAllFoods()
    }
    
    var categorizedIngredients: [(category: String, ingredients: [String])] {
        guard cachedCategorizedIngredients.isEmpty else {
            return cachedCategorizedIngredients
        }
        
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
        guard !manager.items.isEmpty else { return [] }
        
        let kitchenIngredients = Set(manager.items.map { $0.name.lowercased() })
        
        return recipes.filter { recipe in
            let recipeIngredients = recipe.ingredients.map { $0.name.lowercased() }
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
                        VStack(alignment: .leading, spacing: AppTheme.spacing32) {
                            if manager.items.isEmpty && searchText.isEmpty {
                                emptyPromptView
                            } else if !searchText.isEmpty {
                                searchResultsView
                            } else {
                                if !quickMatchRecipes.isEmpty {
                                    quickRecipeMatchesView
                                }
                                
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
            KitchenQuickAddSheet()
        }
        .sheet(isPresented: $showAddIngredientSheet) {
            AddIngredientSheet()
        }
        .onAppear {
            refreshCategorizedIngredients()
        }
    }
    
    private func refreshCategorizedIngredients() {
        cachedCategorizedIngredients = categorizedIngredients
    }
    
    private var header: some View {
        VStack(spacing: AppTheme.spacing12) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: 44, height: 44)
                    
                    Spacer()
                    
                    Text("Kitchen")
                        .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                        .adaptiveForegroundColor()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            showQuickAdd = true
                            HapticManager.shared.light()
                        }) {
                            Label("Quick Add", systemImage: "plus.circle")
                        }
                        
                        if !manager.items.isEmpty {
                            Divider()
                            
                            Button(role: .destructive, action: {
                                KitchenInventoryManager.shared.clearAll()
                                HapticManager.shared.light()
                            }) {
                                Label("Clear Kitchen", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: AppTheme.fontSize20))
                            .adaptiveForegroundColor()
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Kitchen menu")
                    .accessibilityHint("Opens menu to add ingredients or clear kitchen inventory")
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            HStack(spacing: AppTheme.spacing12) {
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.adaptiveHighEmphasis(for: colorScheme))
                        .font(.body)
                    
                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text("Search ingredients...")
                                .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                        }
                        TextField("", text: $searchText)
                            .focused($isSearchFocused)
                            .autocorrectionDisabled()
                            .adaptiveForegroundColor()
                    }
                    
                    if !searchText.isEmpty {
                        Button(
                            action: { 
                                searchText = ""
                            },
                            label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
                            }
                        )
                    }
                }
                .padding(AppTheme.spacing16)
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
                                .adaptiveForegroundColor()
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
    
    private var emptyPromptView: some View {
        VStack(spacing: AppTheme.spacing16) {
            Image(systemName: "refrigerator")
                .font(.system(size: AppTheme.fontSize60))
                .adaptiveForegroundColor(opacity: 0.4)
            
            Text("Your Kitchen is Empty")
                .font(.title2)
                .fontWeight(.bold)
                .adaptiveForegroundColor()
            
            Text("Add ingredients to see matching recipes")
                .font(.subheadline)
                .adaptiveForegroundColor(opacity: 0.7)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity)
    }
    
    private var kitchenItemsView: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
            HStack(spacing: AppTheme.spacing12) {
                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text("My Kitchen")
                        .font(.title3)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()
                    
                    Text("\(manager.items.count) ingredients")
                        .font(.caption)
                        .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
                }
                
                Spacer()
                
                Button(action: {
                    showAddIngredientSheet = true
                    HapticManager.shared.light()
                }) {
                    HStack(spacing: AppTheme.spacing6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                        Text("Add More")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .adaptiveForegroundColor()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentColor(for: selectedTheme))
                    )
                }
            }
            .padding(.horizontal, 20)
            
            ForEach(KitchenInventoryManager.shared.groupedItems(), id: \.category) { group in
                KitchenCategoryCard(
                    category: group.category,
                    items: group.items,
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
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Search Results")
                .font(.title3)
                .fontWeight(.bold)
                .adaptiveForegroundColor()
                .padding(.horizontal, 20)
            
            if searchResults.isEmpty {
                Text("No ingredients found")
                    .font(.body)
                    .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: AppTheme.spacing8) {
                    ForEach(searchResults, id: \.self) { ingredient in
                        kitchenIngredientButton(ingredient)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private func kitchenIngredientButton(_ ingredient: String) -> some View {
        let isInKitchen = KitchenInventoryManager.shared.hasItem(ingredient)
        let category = CategoryClassifier.suggestCategory(for: ingredient)
        
        return Button {
            withAnimation(.spring(response: 0.3)) {
                KitchenInventoryManager.shared.toggleItem(ingredient)
                HapticManager.shared.light()
            }
        } label: {
            HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: CategoryClassifier.categoryIcon(for: category))
                        .foregroundStyle(CategoryClassifier.categoryColor(for: category))
                        .font(.body)
                    
                    Text(ingredient)
                        .font(.body)
                        .foregroundStyle(AppTheme.textColor(for: colorScheme))
                    
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
                            .fill(AppTheme.adaptiveCard(for: colorScheme))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    }
                }
            }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var quickRecipeMatchesView: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                HStack(spacing: AppTheme.spacing10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: AppTheme.fontSize28))
                        .foregroundColor(.yellow)
                    
                    Text("Quick Recipe Matches")
                        .font(.system(size: AppTheme.fontSize28, weight: .bold))
                        .adaptiveForegroundColor()
                }
                
                Text(matchCountText)
                    .font(.body)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.cardLightOpacity) : .black.opacity(AppTheme.highEmphasisOpacity))
                
                Text("Tap any recipe to view full details and cooking instructions")
                    .font(.caption)
                    .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
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
                HStack(spacing: AppTheme.spacing16) {
                    ForEach(quickMatchRecipes.prefix(10)) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe, onFavoriteToggle: {
                            recipes = PersistenceController.shared.fetchRecipes()
                        })) {
                            QuickMatchRecipeCard(
                                recipe: recipe,
                                matchCount: matchCount(
                                    recipe: recipe,
                                    kitchenIngredients: Set(manager.items.map { $0.name.lowercased() })
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
        
        for group in KitchenInventoryManager.shared.groupedItems() {
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
        
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        let activityController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = topController.view
            popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        topController.present(activityController, animated: true)
    }
}

struct KitchenCategoryCard: View {
    let category: String
    let items: [KitchenItem]
    let isCollapsed: Bool
    let onToggleCollapse: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Button(action: onToggleCollapse) {
                HStack(spacing: AppTheme.spacing12) {
                    Circle()
                        .fill(CategoryClassifier.categoryColor(for: category).opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: CategoryClassifier.categoryIcon(for: category))
                                .foregroundColor(CategoryClassifier.categoryColor(for: category))
                        )
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                        Text(category)
                            .font(.headline)
                            .adaptiveForegroundColor()
                        
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
                FlowLayout(spacing: AppTheme.spacing8) {
                    ForEach(items) { item in
                        KitchenItemChip(item: item)
                    }
                }
            }
        }
        .padding(AppTheme.spacing16)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.adaptiveCard(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

struct KitchenItemChip: View {
    let item: KitchenItem
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    
    private var categoryInfo: (icon: String, color: Color) {
        let category = CategoryClassifier.suggestCategory(for: item.name)
        return (
            CategoryClassifier.categoryIcon(for: category),
            CategoryClassifier.categoryColor(for: category)
        )
    }
    
    var body: some View {
        HStack(spacing: AppTheme.spacing8) {
            Image(systemName: categoryInfo.icon)
                .font(.caption)
                .foregroundColor(categoryInfo.color)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(categoryInfo.color.opacity(0.15))
                )
            
            Text(item.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .adaptiveForegroundColor()
            
            Button(
                action: {
                    withAnimation(.spring(response: 0.3)) {
                        KitchenInventoryManager.shared.removeItem(item)
                        HapticManager.shared.light()
                    }
                },
                label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: AppTheme.fontSize16))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.lowEmphasisOpacity) : .black.opacity(0.3))
                }
            )
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            categoryInfo.color.opacity(0.25),
                            categoryInfo.color.opacity(0.15)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(categoryInfo.color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: categoryInfo.color.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct AddIngredientSheet: View {
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
                    SearchBar(text: $searchText, placeholder: "Search Foods...")
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                    
                    if !searchText.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: AppTheme.spacing8) {
                                ForEach(searchResults, id: \.self) { food in
                                    foodButton(food)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                    } else if let category = selectedCategory {
                        ScrollView {
                            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
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
                                    .adaptiveForegroundColor()
                                    .padding(.horizontal, 20)
                                
                                LazyVStack(spacing: AppTheme.spacing8) {
                                    ForEach(FoodsList.getFoods(forCategory: category), id: \.self) { food in
                                        foodButton(food)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.vertical, 12)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: AppTheme.spacing12) {
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
                    .accessibilityHint("Closes add ingredients screen")
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
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: CategoryClassifier.categoryIcon(for: category))
                    .font(.title3)
                    .foregroundColor(CategoryClassifier.categoryColor(for: category))
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                    Text(category)
                        .font(.headline)
                        .adaptiveForegroundColor()
                    
                    Text("\(FoodsList.getFoods(forCategory: category).count) items")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            .padding(AppTheme.spacing16)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func foodButton(_ food: String) -> some View {
        let isInKitchen = KitchenInventoryManager.shared.hasItem(food)
        let category = FoodsList.getCategoryForFood(food) ?? "Other"
        
        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                KitchenInventoryManager.shared.toggleItem(food)
                HapticManager.shared.light()
            }
        }) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: CategoryClassifier.categoryIcon(for: category))
                    .foregroundColor(CategoryClassifier.categoryColor(for: category))
                    .font(.body)
                
                Text(food)
                    .font(.body)
                    .adaptiveForegroundColor()
                
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
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
