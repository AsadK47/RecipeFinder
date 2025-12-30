import ConfettiSwiftUI
import SwiftUI

struct ShoppingListView: View {
    @StateObject private var manager = ShoppingListManager.shared
    @State private var searchText: String = ""
    @State private var showClearConfirmation = false
    @State private var showQuickAdd = false
    @State private var collapsedCategories: Set<String> = []
    @State private var confettiTrigger = 0
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    // PERFORMANCE: Cache computed values
    private var sortedGroupedItems: [(key: String, value: [ShoppingListModel])] {
        Dictionary(grouping: manager.items, by: { $0.category })
            .map { (key: $0.key, value: $0.value.sorted { !$0.isChecked && $1.isChecked }) }
            .sorted { first, second in
                guard let firstIndex = CategoryClassifier.categoryOrder.firstIndex(of: first.key),
                      let secondIndex = CategoryClassifier.categoryOrder.firstIndex(of: second.key) else {
                    return first.key < second.key
                }
                return firstIndex < secondIndex
            }
    }
    
    private var searchResults: [String] {
        guard !searchText.isEmpty else { return [] }
        return FoodsList.searchFoods(query: searchText)
    }
    
    private var showingSearchResults: Bool {
        !searchText.isEmpty && isSearchFocused && !searchResults.isEmpty
    }
    
    private var checkedCount: Int {
        manager.items.filter { $0.isChecked }.count
    }
    
    private var totalCount: Int {
        manager.items.count
    }
    
    private func shareShoppingList() {
        var text = "🛒 Shopping List\n\n"
        
        for group in sortedGroupedItems {
            text += "\(group.key)\n"
            for item in group.value {
                let checkbox = item.isChecked ? "✓" : "○"
                let qty = item.quantity > 1 ? "(\(item.quantity)) " : ""
                text += "\(checkbox) \(qty)\(item.name)\n"
            }
            text += "\n"
        }
        
        // Use proper window scene access
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
        
        // Configure for iPad
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = topController.view
            popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        topController.present(activityController, animated: true)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    header
                    
                    // Progress bar
                    if !manager.items.isEmpty && !showingSearchResults {
                        VStack(spacing: 6) {
                            ProgressView(value: Double(checkedCount), total: Double(totalCount))
                                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor(for: selectedTheme)))
                                .frame(height: 8)
                                .accessibilityLabel("Shopping progress")
                                .accessibilityValue("\(checkedCount) of \(totalCount) items checked")
                            
                            HStack {
                                Text("\(checkedCount)/\(totalCount) completed")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .accessibilityHidden(true)
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                    
                    // Content
                    if showingSearchResults {
                        searchResultsView
                    } else {
                        if manager.items.isEmpty {
                            emptyStateView
                        } else {
                            shoppingListContent
                        }
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button {
                            isSearchFocused = false
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .confettiCannon(
                trigger: $confettiTrigger,
                num: 50,
                radius: 500.0
            )
            .onChange(of: checkedCount) { _, newValue in
                // Trigger confetti when all items are checked
                if !manager.items.isEmpty && newValue == totalCount {
                    HapticManager.shared.success()
                    confettiTrigger += 1
                }
            }
            .confirmationDialog("Clear Items", isPresented: $showClearConfirmation) {
                if checkedCount > 0 {
                    Button("Clear Checked Items (\(checkedCount))", role: .destructive) {
                        manager.clearCheckedItems()
                    }
                }
                Button("Clear All Items (\(totalCount))", role: .destructive) {
                    manager.clearAllItems()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose which items to remove from your shopping list")
            }
            .sheet(isPresented: $showQuickAdd) {
                ShoppingQuickAddSheet()
            }
        }
    }
    
    private var searchResultsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Suggested Ingredients")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                if searchResults.isEmpty {
                    Text("No ingredients found")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(searchResults, id: \.self) { ingredient in
                            ingredientButton(ingredient)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Empty space to balance menu button
                    Color.clear
                        .frame(width: 44, height: 44)
                    
                    Spacer()
                    
                    Text("Shopping List")
                        .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Spacer()
                    
                    // Menu button
                    Menu {
                        Button(action: {
                            HapticManager.shared.light()
                            showQuickAdd = true
                        }) {
                            Label("Quick Add", systemImage: "plus.circle")
                        }
                        
                        Button(action: {
                            HapticManager.shared.light()
                            shareShoppingList()
                        }) {
                            Label("Share List", systemImage: "square.and.arrow.up")
                        }
                        
                        if !manager.items.isEmpty {
                            Divider()
                            
                            Button(
                                action: {
                                    if collapsedCategories.count == CategoryClassifier.categoryOrder.count {
                                        collapsedCategories.removeAll()
                                    } else {
                                        collapsedCategories = Set(CategoryClassifier.categoryOrder)
                                    }
                                },
                                label: {
                                    Label(
                                        collapsedCategories.count == CategoryClassifier.categoryOrder.count ? "Expand All" : "Collapse All",
                                        systemImage: collapsedCategories.count == CategoryClassifier.categoryOrder.count ? "chevron.down.circle" : "chevron.up.circle"
                                    )
                                }
                            )
                            
                            Divider()
                            
                            Button(
                                role: .destructive,
                                action: { 
                                    showClearConfirmation = true 
                                },
                                label: {
                                    Label("Clear Items", systemImage: "trash")
                                }
                            )
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Shopping list menu")
                    .accessibilityHint("Opens menu with options to add items, share list, or manage categories")
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
                    
                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text("Add item...")
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                        }
                        TextField("", text: $searchText)
                            .focused($isSearchFocused)
                            .autocorrectionDisabled()
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .onSubmit(addItem)
                    }
                    
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
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "cart.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(Color(colorScheme == .dark ? .white : .black).opacity(0.4))
                
                Text("Start Your Shopping List")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text("Add items to begin shopping")
                    .font(.subheadline)
                    .foregroundColor(Color(colorScheme == .dark ? .white : .black).opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.top, 40)
        }
    }
    
    private var shoppingListContent: some View {
        List {
            ForEach(sortedGroupedItems, id: \.key) { group in
                categorySection(for: group.key, items: group.value)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .environment(\.defaultMinListHeaderHeight, 0)
    }
    
    @ViewBuilder
    private func categorySection(for category: String, items: [ShoppingListModel]) -> some View {
        Section {
            if !collapsedCategories.contains(category) {
                // PERFORMANCE: Use items directly instead of searching
                ForEach(items) { item in
                    ShoppingListItemRow(
                        item: item,
                        onToggle: {
                            if let index = manager.items.firstIndex(where: { $0.id == item.id }) {
                                manager.toggleItem(at: index)
                            }
                        },
                        onQuantityChange: { newQuantity in
                            if let index = manager.items.firstIndex(where: { $0.id == item.id }) {
                                manager.updateQuantity(at: index, quantity: newQuantity)
                            }
                        },
                        onDelete: {
                            if let index = manager.items.firstIndex(where: { $0.id == item.id }) {
                                manager.deleteItem(at: index)
                            }
                        },
                        onCategoryChange: { newCategory in
                            if let index = manager.items.firstIndex(where: { $0.id == item.id }) {
                                manager.updateCategory(at: index, category: newCategory)
                            }
                        },
                        onStoreChange: { newStore in
                            if let index = manager.items.firstIndex(where: { $0.id == item.id }) {
                                manager.updateStore(at: index, store: newStore)
                            }
                        },
                        allCategories: CategoryClassifier.categoryOrder
                    )
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
        } header: {
            categorySectionHeader(category: category, items: items)
        }
    }
    
    @ViewBuilder
    private func categorySectionHeader(category: String, items: [ShoppingListModel]) -> some View {
        Button(
            action: {
                if collapsedCategories.contains(category) {
                    collapsedCategories.remove(category)
                } else {
                    collapsedCategories.insert(category)
                }
            },
            label: {
                HStack(spacing: 12) {
                    Image(systemName: categoryIcon(for: category))
                        .font(.title3)
                        .foregroundColor(categoryColor(for: category))
                        .frame(width: 28)
                    
                    Text(category)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text("(\(items.filter { !$0.isChecked }.count)/\(items.count))")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.4))
                    
                    Spacer()
                    
                    Image(systemName: collapsedCategories.contains(category) ? "chevron.down" : "chevron.up")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.4))
                        .rotationEffect(.degrees(collapsedCategories.contains(category) ? 0 : 180))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    if cardStyle == .solid {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        )
        .buttonStyle(.plain)
        .textCase(nil)
        .listRowInsets(EdgeInsets())
        .headerProminence(.standard)
    }
    
    private func addItem() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            debugLog("❌ ShoppingListView: Empty search text")
            return
        }
        debugLog("🔍 ShoppingListView: Adding item '\(searchText)'")
        manager.addItem(name: searchText)
        searchText = ""
        isSearchFocused = false
        HapticManager.shared.success()
        debugLog("📊 ShoppingListView: Manager now has \(manager.items.count) items")
    }
    
    private func addItemFromSearch(_ ingredient: String) {
        debugLog("🔍 ShoppingListView: Adding item from search '\(ingredient)'")
        manager.addItem(name: ingredient)
        // Reset state to allow continuous adding
        searchText = ""
        // Keep focus so user can continue typing
        isSearchFocused = true
        HapticManager.shared.success()
        debugLog("📊 ShoppingListView: Manager now has \(manager.items.count) items")
    }
    
    private func ingredientButton(_ ingredient: String) -> some View {
        let category = CategoryClassifier.suggestCategory(for: ingredient)
        let isInList = manager.items.contains { $0.name.lowercased() == ingredient.lowercased() }
        
        return Button(
            action: {
                addItemFromSearch(ingredient)
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
                    
                    Image(systemName: isInList ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundStyle(isInList ? .green : AppTheme.accentColor(for: selectedTheme))
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
        )
        .buttonStyle(PlainButtonStyle())
        .disabled(isInList)
    }
    
    private func categoryIcon(for category: String) -> String {
        CategoryClassifier.categoryIcon(for: category)
    }
    
    private func categoryColor(for category: String) -> Color {
        CategoryClassifier.categoryColor(for: category)
    }
}

// Shopping List Item Row
struct ShoppingListItemRow: View {
    let item: ShoppingListModel
    let onToggle: () -> Void
    let onQuantityChange: (Int) -> Void
    let onDelete: () -> Void
    let onCategoryChange: (String) -> Void
    let onStoreChange: (String?) -> Void
    let allCategories: [String]
    let availableStores: [String] = ["ASDA", "Tesco", "Sainsbury's", "Lidl", "Aldi", "Morrisons", "Waitrose"]
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        ZStack {
            GlassCard {
                HStack(spacing: 16) {
                    Button(action: onToggle, label: {
                        ZStack {
                            Circle()
                                .strokeBorder(
                                    item.isChecked ? AppTheme.accentColor : Color.gray,
                                    lineWidth: 2
                                )
                                .frame(width: 28, height: 28)
                            
                            if item.isChecked {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Circle().fill(AppTheme.accentColor))
                            }
                        }
                    })
                    .buttonStyle(PlainButtonStyle())
                    
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(item.isChecked)
                        .foregroundColor(item.isChecked ? .gray: (colorScheme == .dark ? .white: .black))
                    
                    // Store badge
                    if let store = item.preferredStore {
                        Text(store)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(AppTheme.accentColor.opacity(0.8))
                            )
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Decrement button
                        Button(action: {
                            if item.quantity > 1 {
                                onQuantityChange(item.quantity - 1)
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(item.quantity > 1 ? (colorScheme == .dark ? .white : .black) : .gray)
                                .frame(width: 32, height: 32)
                                .background {
                                    if cardStyle == .solid {
                                        Circle()
                                            .fill(colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.95))
                                    } else {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    }
                                }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(item.quantity <= 1)
                        
                        // Quantity display
                        Text("\(item.quantity)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .frame(minWidth: 20)
                        
                        // Increment button
                        Button(action: {
                            if item.quantity < 99 {
                                onQuantityChange(item.quantity + 1)
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(item.quantity < 99 ? (colorScheme == .dark ? .white : .black) : .gray)
                                .frame(width: 32, height: 32)
                                .background {
                                    if cardStyle == .solid {
                                        Circle()
                                            .fill(colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.95))
                                    } else {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    }
                                }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(item.quantity >= 99)
                    }
                    .opacity(item.isChecked ? 0.5 : 1)
                }
                .padding(14)
            }
            .opacity(item.isChecked ? 0.6 : 1)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(
                role: .destructive,
                action: onDelete
            ) {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .contextMenu {
            Menu("Change Store") {
                Button(action: {
                    onStoreChange(nil)
                }) {
                    Label("None", systemImage: item.preferredStore == nil ? "checkmark" : "")
                }
                
                ForEach(availableStores, id: \.self) { store in
                    Button(action: {
                        onStoreChange(store)
                    }) {
                        Label(store, systemImage: item.preferredStore == store ? "checkmark" : "")
                    }
                }
            }
            
            Menu("Change Category") {
                ForEach(allCategories, id: \.self) { category in
                    Button(action: {
                        onCategoryChange(category)
                    }) {
                        Label(category, systemImage: categoryIcon(for: category))
                    }
                }
            }
            
            Divider()
            
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        CategoryClassifier.categoryIcon(for: category)
    }
}

// Edit Item Sheet

// MARK: - Feature Row Component
struct ShoppingFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let appTheme: AppTheme.ThemeType
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .font(.body)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Text(description)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
            }
            Spacer()
        }
    }
}

// MARK: - Help Sheet View
struct HelpSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Beautiful gradient background
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Hero section with seamless header
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Shopping List Features")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Learn how to make the most of your shopping list with these powerful features.")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.85))
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                        .padding(.bottom, 32)
                        
                        // Feature cards with beautiful styling
                        VStack(alignment: .leading, spacing: 16) {
                            ShoppingFeatureRow(icon: "sparkles", title: "Smart Categories", description: "Items are automatically sorted into categories", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "chevron.up.chevron.down", title: "Collapse Categories", description: "Tap category headers to show or hide items", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "checkmark.circle", title: "Check Off Items", description: "Tap checkbox to mark items as purchased", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "storefront", title: "Tag by Store", description: "Long-press items to set preferred supermarket", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "plus.circle", title: "Quick Add", description: "Use menu (≡) to quickly add items", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "square.and.pencil", title: "Adjust Quantity", description: "Use +/- buttons to change item amounts", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "trash", title: "Delete Items", description: "Swipe left on any item to remove it", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "square.and.arrow.up", title: "Share List", description: "Export your list via menu (≡)", appTheme: appTheme)
                        }
                        .padding(24)
                        .background {
                            if cardStyle == .solid {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? Color(white: 0.15).opacity(0.6) : Color.white.opacity(0.85))
                            } else {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial.opacity(0.85))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
                .ignoresSafeArea(edges: .top)
                
                // Floating Done button
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                        )
                                )
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 12)
                    }
                    Spacer()
                }
            }
        }
    }
}
