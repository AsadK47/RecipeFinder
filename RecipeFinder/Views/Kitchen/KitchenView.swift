import SwiftUI

private let logger = AppLogger.logger(category: "KitchenView")

struct KitchenView: View {
    @Binding var recipes: [RecipeModel]
    @StateObject private var manager = KitchenInventoryManager.shared
    @State private var searchText = ""
    @State private var showAddIngredientSheet = false
    @State private var showQuickAdd = false
    @State private var cachedCategorizedIngredients: [(category: String, ingredients: [String])] = []
    @State private var collapsedCategories: Set<String> = []
    @State private var quickMatches: [RecipeModel] = []
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

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
    
    var quickMatchRecipes: [RecipeModel] { quickMatches }

    private func normalizedIngredientTerm(_ raw: String) -> String {
        let main = IngredientNameFormatter.extractMainName(raw)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return main
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func ingredientMatches(_ recipeIngredient: String, _ kitchenIngredient: String) -> Bool {
        if recipeIngredient == kitchenIngredient {
            return true
        }

        // Avoid broad wildcard behavior for tiny terms like "b".
        guard recipeIngredient.count >= 3, kitchenIngredient.count >= 3 else {
            return false
        }

        return recipeIngredient.contains(kitchenIngredient) || kitchenIngredient.contains(recipeIngredient)
    }

    private func computeQuickMatches() -> [RecipeModel] {
        guard !manager.items.isEmpty else { return [] }

        let kitchenIngredients = Set(
            manager.items
                .map { normalizedIngredientTerm($0.name) }
                .filter { !$0.isEmpty }
        )

        guard !kitchenIngredients.isEmpty else { return [] }
        
        return recipes.filter { recipe in
            let recipeIngredients = recipe.ingredients
                .map { normalizedIngredientTerm($0.name) }
                .filter { !$0.isEmpty }

            return recipeIngredients.contains { recipeIng in
                kitchenIngredients.contains { kitchenIng in
                    ingredientMatches(recipeIng, kitchenIng)
                }
            }
        }.sorted { recipe1, recipe2 in
            matchCount(recipe: recipe1, kitchenIngredients: kitchenIngredients) >
            matchCount(recipe: recipe2, kitchenIngredients: kitchenIngredients)
        }
    }
    
    private func matchCount(recipe: RecipeModel, kitchenIngredients: Set<String>) -> Int {
        let recipeIngredients = recipe.ingredients
            .map { normalizedIngredientTerm($0.name) }
            .filter { !$0.isEmpty }

        return recipeIngredients.filter { recipeIng in
            kitchenIngredients.contains { kitchenIng in
                ingredientMatches(recipeIng, kitchenIng)
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
                    
                    if manager.items.isEmpty && searchText.isEmpty {
                        ScrollView {
                            emptyPromptView
                                .padding(.vertical, AppTheme.spacing16)
                        }
                    } else if !searchText.isEmpty {
                        ScrollView {
                            searchResultsView
                                .padding(.vertical, AppTheme.spacing16)
                        }
                    } else {
                        kitchenListContent
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
            quickMatches = computeQuickMatches()
        }
        .onChange(of: manager.items) { _, _ in
            quickMatches = computeQuickMatches()
        }
        .onChange(of: recipes) { _, _ in
            quickMatches = computeQuickMatches()
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
                        .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                    
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
                            .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                    }
                    .accessibilityLabel("Kitchen menu")
                    .accessibilityHint("Opens menu to add ingredients or clear kitchen inventory")
                }
            }
            .frame(height: AppTheme.height44)
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.top, AppTheme.spacing16)
            
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
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(AppTheme.adaptiveCard(for: colorScheme))
                    } else {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
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
            .padding(.horizontal, AppTheme.spacing20)
            .padding(.bottom, AppTheme.spacing12)
            .animation(.spring(response: 0.3), value: isSearchFocused)
        }
    }
    
    private var emptyPromptView: some View {
        VStack(spacing: AppTheme.spacing16) {
            Image(systemName: "refrigerator")
                .font(.system(size: AppTheme.fontSize60))
                .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
            
            Text("Your Kitchen is Empty")
                .font(.title2)
                .fontWeight(.bold)
                .adaptiveForegroundColor()
            
            Text("Add ingredients to see matching recipes")
                .font(.subheadline)
                .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.spacing40)
        }
        .padding(.top, AppTheme.spacing40)
        .frame(maxWidth: .infinity)
    }
    
    private var kitchenListContent: some View {
        List {
            if !quickMatchRecipes.isEmpty {
                Section {
                    quickRecipeMatchesView
                        .padding(.vertical, AppTheme.spacing8)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            Section {
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
                            Image(systemName: "plus.circle.fill").font(.caption)
                            Text("Add More").font(.caption).fontWeight(.semibold)
                        }
                        .adaptiveForegroundColor()
                        .padding(.horizontal, AppTheme.spacing12)
                        .padding(.vertical, AppTheme.spacing6)
                        .background(Capsule().fill(AppTheme.accentColor(for: selectedTheme)))
                    }
                }
                .padding(.horizontal, AppTheme.spacing4)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            ForEach(KitchenInventoryManager.shared.groupedItems(), id: \.category) { group in
                Section {
                    if !collapsedCategories.contains(group.category) {
                        ForEach(group.items) { item in
                            KitchenItemRow(item: item)
                                .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                            KitchenInventoryManager.shared.removeItem(item)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red)
                                }
                        }
                    }
                } header: {
                    kitchenCategoryHeader(category: group.category, items: group.items)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .environment(\.defaultMinListHeaderHeight, 0)
        .padding(.top, -6)
    }

    @ViewBuilder
    private func kitchenCategoryHeader(category: String, items: [KitchenItem]) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                if collapsedCategories.contains(category) {
                    collapsedCategories.remove(category)
                } else {
                    collapsedCategories.insert(category)
                }
            }
        }) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: CategoryClassifier.categoryIcon(for: category))
                    .font(.body)
                    .foregroundColor(CategoryClassifier.categoryColor(for: category))
                    .frame(width: AppTheme.iconSize28)
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                Text("(\(items.count))")
                    .font(.footnote)
                    .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.caption)
                    .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                    .rotationEffect(.degrees(collapsedCategories.contains(category) ? 180 : 0))
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(.ultraThinMaterial)
                }
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.top, AppTheme.spacing2)
        }
        .buttonStyle(.plain)
        .textCase(nil)
        .listRowInsets(EdgeInsets())
        .headerProminence(.standard)
    }

    
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Search Results")
                .font(.title3)
                .fontWeight(.bold)
                .adaptiveForegroundColor()
                .padding(.horizontal, AppTheme.spacing20)

            LazyVStack(spacing: AppTheme.spacing8) {
                // Always show a free-text "Add" row first
                let trimmed = searchText.trimmingCharacters(in: .whitespaces)
                let alreadyInKitchen = KitchenInventoryManager.shared.hasItem(trimmed)
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        KitchenInventoryManager.shared.toggleItem(trimmed)
                        HapticManager.shared.light()
                        searchText = ""
                    }
                } label: {
                    HStack(spacing: AppTheme.spacing12) {
                        Image(systemName: alreadyInKitchen ? "checkmark.circle.fill" : "plus.circle.fill")
                            .foregroundStyle(alreadyInKitchen ? .green : AppTheme.accentColor(for: selectedTheme))
                            .font(.title3)
                        Text(alreadyInKitchen ? "\"\(trimmed)\" is in your kitchen" : "Add \"\(trimmed)\"")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.textColor(for: colorScheme))
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.spacing16)
                    .padding(.vertical, AppTheme.spacing14)
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(AppTheme.adaptiveCard(for: colorScheme))
                        } else {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(.ultraThinMaterial)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())

                ForEach(searchResults, id: \.self) { ingredient in
                    kitchenIngredientButton(ingredient)
                }
            }
            .padding(.horizontal, AppTheme.spacing20)
        }
    }
    
    private func kitchenIngredientButton(_ ingredient: String) -> some View {
        let isInKitchen = KitchenInventoryManager.shared.hasItem(ingredient)
        let category = CategoryClassifier.suggestCategory(for: ingredient)
        
        return Button {
            withAnimation(.spring(response: 0.3)) {
                KitchenInventoryManager.shared.toggleItem(ingredient)
                HapticManager.shared.light()
                searchText = ""
                isSearchFocused = false
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
                .padding(.horizontal, AppTheme.spacing16)
                .padding(.vertical, AppTheme.spacing14)
                .background {
                    if cardStyle == .solid {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(AppTheme.adaptiveCard(for: colorScheme))
                    } else {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(.ultraThinMaterial)
                    }
                }
            }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var quickRecipeMatchesView: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing6) {
                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.yellow)
                Text("Recipe Ideas")
                    .font(.title3.bold())
                    .adaptiveForegroundColor()
                Spacer()
                Text(matchCountText)
                    .font(.caption)
                    .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
            }
            .padding(.horizontal, AppTheme.spacing20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacing12) {
                    ForEach(quickMatchRecipes.prefix(10)) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe, onFavoriteToggle: {
                            guard PersistenceController.shared.hasCurrentUserScope() else {
                                logger.debug("⚠️ Skipping recipe refresh from Kitchen quick matches because user scope is unavailable")
                                return
                            }
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
                .padding(.horizontal, AppTheme.spacing20)
            }
        }
    }
    
    private var matchCountText: String {
        let count = quickMatchRecipes.count
        return count == 1 ? "1 match" : "\(count) matches"
    }
    
    private func shareKitchenInventory() {
        var text = "🏠 MY KITCHEN INVENTORY\n"
        text += String(repeating: "━", count: 40) + "\n\n"
        
        for group in KitchenInventoryManager.shared.groupedItems() {
            let icon = CategoryClassifier.categoryIcon(for: group.category)
            text += "\(icon) \(group.category.uppercased())\n"
            text += String(repeating: "─", count: 40) + "\n"
            
            for item in group.items {
                let quantityText = item.quantity == item.quantity.rounded()
                    ? String(Int(item.quantity))
                    : String(format: "%.1f", item.quantity)
                text += "  • \(quantityText) \(item.unit) \(item.name)\n"
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

struct KitchenItemRow: View {
    let item: KitchenItem

    private var allCategoryChoices: [String] {
        let merged = Array(Set(CategoryClassifier.categoryOrder + FoodsList.categories + [item.category]))
        return merged.sorted { lhs, rhs in
            let lhsIndex = CategoryClassifier.categoryOrder.firstIndex(of: lhs)
            let rhsIndex = CategoryClassifier.categoryOrder.firstIndex(of: rhs)
            switch (lhsIndex, rhsIndex) {
            case let (l?, r?): return l < r
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
            }
        }
    }

    private var quantityText: String {
        let value = item.quantity
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }

    var body: some View {
        GlassCard {
            HStack(spacing: AppTheme.spacing12) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                    .lineLimit(1)

                Spacer(minLength: 0)

                HStack(spacing: AppTheme.spacing8) {
                    Button(
                        action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                KitchenInventoryManager.shared.updateQuantity(for: item, delta: -1)
                            }
                        },
                        label: {
                            Image(systemName: "minus")
                                .font(.system(size: AppTheme.fontSize12, weight: .bold))
                                .adaptiveForegroundColor()
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                    )
                    .buttonStyle(.plain)
                    .disabled(item.quantity <= 1)

                    Text(quantityText)
                        .font(.subheadline.monospacedDigit())
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .frame(minWidth: 24)

                    Button(
                        action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                KitchenInventoryManager.shared.updateQuantity(for: item, delta: 1)
                            }
                        },
                        label: {
                            Image(systemName: "plus")
                                .font(.system(size: AppTheme.fontSize12, weight: .bold))
                                .adaptiveForegroundColor()
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(.ultraThinMaterial))
                        }
                    )
                    .buttonStyle(.plain)
                    .disabled(item.quantity >= 99)
                }

                Menu {
                    Menu("Change Category") {
                        ForEach(allCategoryChoices, id: \.self) { category in
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                    KitchenInventoryManager.shared.updateCategory(for: item, category: category)
                                }
                            }) {
                                if category == item.category {
                                    Label(category, systemImage: "checkmark")
                                } else {
                                    Label(category, systemImage: CategoryClassifier.categoryIcon(for: category))
                                }
                            }
                        }
                    }

                    Divider()

                    Button(role: .destructive, action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            KitchenInventoryManager.shared.removeItem(item)
                        }
                    }) {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 18, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing10)
        }
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
                        .padding(.horizontal, AppTheme.spacing20)
                        .padding(.top, AppTheme.spacing16)
                        .padding(.bottom, AppTheme.spacing12)
                    
                    if !searchText.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: AppTheme.spacing8) {
                                ForEach(searchResults, id: \.self) { food in
                                    foodButton(food)
                                }
                            }
                            .padding(.horizontal, AppTheme.spacing20)
                            .padding(.vertical, AppTheme.spacing12)
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
                                    .padding(.horizontal, AppTheme.spacing20)
                                    .padding(.vertical, AppTheme.spacing8)
                                }
                                
                                Text(category)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .adaptiveForegroundColor()
                                    .padding(.horizontal, AppTheme.spacing20)
                                
                                LazyVStack(spacing: AppTheme.spacing8) {
                                    ForEach(FoodsList.getFoods(forCategory: category), id: \.self) { food in
                                        foodButton(food)
                                    }
                                }
                                .padding(.horizontal, AppTheme.spacing20)
                            }
                            .padding(.vertical, AppTheme.spacing12)
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: AppTheme.spacing12) {
                                ForEach(filteredCategories, id: \.self) { category in
                                    categoryButton(category)
                                }
                            }
                            .padding(.horizontal, AppTheme.spacing20)
                            .padding(.vertical, AppTheme.spacing12)
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
                    .frame(width: AppTheme.iconSize40)
                
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
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
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
                let adding = !KitchenInventoryManager.shared.hasItem(food)
                KitchenInventoryManager.shared.toggleItem(food)
                HapticManager.shared.light()
                if adding {
                    dismiss()
                }
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
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing14)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(.ultraThinMaterial)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
