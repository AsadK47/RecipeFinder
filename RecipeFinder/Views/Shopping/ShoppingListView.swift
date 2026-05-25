import ConfettiSwiftUI
import SwiftUI

private let logger = AppLogger.logger(category: "ShoppingList")

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
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty && isSearchFocused
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    header
                    
                    if !manager.items.isEmpty && !showingSearchResults {
                        VStack(spacing: AppTheme.spacing6) {
                            ProgressView(value: Double(checkedCount), total: Double(totalCount))
                                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor(for: selectedTheme)))
                                .frame(height: AppTheme.height8)
                                .accessibilityLabel("Shopping progress")
                                .accessibilityValue("\(checkedCount) of \(totalCount) items checked")
                            
                            HStack {
                                Text("\(checkedCount)/\(totalCount) completed")
                                    .font(.caption)
                                    .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                                    .accessibilityHidden(true)
                                Spacer()
                            }
                        }
                        .padding(.horizontal, AppTheme.spacing20)
                        .padding(.bottom, AppTheme.spacing8)
                    }
                    
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
                num: AppTheme.confettiCount,
                radius: AppTheme.confettiRadius
            )
            .onChange(of: checkedCount) { _, newValue in
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
            VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                Text("Suggested Ingredients")
                    .font(.title3)
                    .fontWeight(.bold)
                    .adaptiveForegroundColor()
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.top, AppTheme.spacing20)
                
                LazyVStack(spacing: AppTheme.spacing8) {
                    let trimmed = searchText.trimmingCharacters(in: .whitespaces)
                    if !searchResults.contains(where: { $0.lowercased() == trimmed.lowercased() }) {
                        Button(action: { addItemFromSearch(trimmed) }) {
                            HStack(spacing: AppTheme.spacing12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(AppTheme.accentColor)
                                Text("Add \"\(trimmed)\"")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .adaptiveForegroundColor()
                                Spacer()
                            }
                            .padding(.vertical, AppTheme.spacing12)
                        }
                        .buttonStyle(.plain)
                        
                        if !searchResults.isEmpty {
                            Divider()
                        }
                    }
                    
                    ForEach(searchResults, id: \.self) { ingredient in
                        ingredientButton(ingredient)
                    }
                }
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.bottom, AppTheme.spacing20)
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: AppTheme.spacing12) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Color.clear
                        .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                    
                    Spacer()
                    
                    Text("Shopping List")
                        .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                        .adaptiveForegroundColor()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Spacer()
                    
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
                            .font(.system(size: AppTheme.fontSize20))
                            .adaptiveForegroundColor()
                            .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                    }
                    .accessibilityLabel("Shopping list menu")
                    .accessibilityHint("Opens menu with options to add items, share list, or manage categories")
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
                            Text("Add item...")
                                .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                        }
                        TextField("", text: $searchText)
                            .focused($isSearchFocused)
                            .autocorrectionDisabled()
                            .adaptiveForegroundColor()
                            .onSubmit(addItem)
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
    
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing16) {
                Image(systemName: "cart.circle.fill")
                    .font(.system(size: AppTheme.fontSize60))
                    .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
                
                Text("Start Your Shopping List")
                    .font(.title2)
                    .fontWeight(.bold)
                    .adaptiveForegroundColor()
                
                Text("Add items to begin shopping")
                    .font(.subheadline)
                    .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.spacing32)
            }
            .padding(.top, AppTheme.spacing40)
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
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: categoryIcon(for: category))
                        .font(.title3)
                        .foregroundColor(categoryColor(for: category))
                        .frame(width: AppTheme.iconSize28)
                    
                    Text(category)
                        .font(.title3)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()
                    
                    Text("(\(items.filter { !$0.isChecked }.count)/\(items.count))")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                    
                    Spacer()
                    
                    Image(systemName: collapsedCategories.contains(category) ? "chevron.down" : "chevron.up")
                        .font(.caption)
                        .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                        .rotationEffect(.degrees(collapsedCategories.contains(category) ? 0 : 180))
                }
                .padding(.horizontal, AppTheme.spacing16)
                .padding(.vertical, AppTheme.spacing12)
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
                .padding(.top, AppTheme.spacing8)
            }
        )
        .buttonStyle(.plain)
        .textCase(nil)
        .listRowInsets(EdgeInsets())
        .headerProminence(.standard)
    }
    
    private func addItem() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            logger.error("❌ ShoppingListView: Empty search text")
            return
        }
        logger.debug("🔍 ShoppingListView: Adding item '\(searchText)'")
        manager.addItem(name: searchText)
        searchText = ""
        isSearchFocused = false
        HapticManager.shared.success()
        logger.debug("📊 ShoppingListView: Manager now has \(manager.items.count) items")
    }
    
    private func addItemFromSearch(_ ingredient: String) {
        logger.debug("🔍 ShoppingListView: Adding item from search '\(ingredient)'")
        manager.addItem(name: ingredient)
        searchText = ""
        isSearchFocused = true
        HapticManager.shared.success()
        logger.debug("📊 ShoppingListView: Manager now has \(manager.items.count) items")
    }
    
    private func ingredientButton(_ ingredient: String) -> some View {
        let category = CategoryClassifier.suggestCategory(for: ingredient)
        let isInList = manager.items.contains { $0.name.lowercased() == ingredient.lowercased() }
        
        return Button(
            action: {
                addItemFromSearch(ingredient)
            },
            label: {
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: CategoryClassifier.categoryIcon(for: category))
                        .foregroundStyle(CategoryClassifier.categoryColor(for: category))
                        .font(.body)
                    
                    Text(ingredient)
                        .font(.body)
                        .foregroundStyle(AppTheme.textColor(for: colorScheme))
                    
                    Spacer()
                    
                    Image(systemName: isInList ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundStyle(isInList ? .green : AppTheme.accentColor(for: selectedTheme))
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
                HStack(spacing: AppTheme.spacing16) {
                    Button(action: onToggle, label: {
                        ZStack {
                            Circle()
                                .strokeBorder(
                                    item.isChecked ? AppTheme.accentColor : Color.gray,
                                    lineWidth: 2
                                )
                                .frame(width: 28, height: AppTheme.height28)
                            
                            if item.isChecked {
                                Image(systemName: "checkmark")
                                    .font(.system(size: AppTheme.fontSize14, weight: .bold))
                                    .adaptiveForegroundColor()
                                    .frame(width: 28, height: AppTheme.height28)
                                    .background(Circle().fill(AppTheme.accentColor))
                            }
                        }
                    })
                    .buttonStyle(PlainButtonStyle())
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                        Text(item.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .strikethrough(item.isChecked)
                            .foregroundColor(item.isChecked ? .gray : AppTheme.adaptiveEmphasis(for: colorScheme))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        if let store = item.preferredStore {
                            Text(store)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.accentColor)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: AppTheme.spacing12) {
                        Button(action: {
                            if item.quantity > 1 {
                                onQuantityChange(item.quantity - 1)
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                                .foregroundColor(item.quantity > 1 ? (AppTheme.adaptiveEmphasis(for: colorScheme)) : .gray)
                                .frame(width: AppTheme.iconSize32, height: 32)
                                .background {
                                    if cardStyle == .solid {
                                        Circle()
                                            .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkMediumOpacity) : Color(white: 0.95))
                                    } else {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    }
                                }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(item.quantity <= 1)
                        
                        Text("\(item.quantity)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .adaptiveForegroundColor()
                            .frame(minWidth: AppTheme.iconSize20)
                        
                        Button(action: {
                            if item.quantity < 99 {
                                onQuantityChange(item.quantity + 1)
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                                .foregroundColor(item.quantity < 99 ? (AppTheme.adaptiveEmphasis(for: colorScheme)) : .gray)
                                .frame(width: AppTheme.iconSize32, height: 32)
                                .background {
                                    if cardStyle == .solid {
                                        Circle()
                                            .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkMediumOpacity) : Color(white: 0.95))
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
                    
                    Menu {
                        Menu("Change Store") {
                            Button(action: { onStoreChange(nil) }) {
                                Label("None", systemImage: item.preferredStore == nil ? "checkmark" : "")
                            }
                            ForEach(availableStores, id: \.self) { store in
                                Button(action: { onStoreChange(store) }) {
                                    Label(store, systemImage: item.preferredStore == store ? "checkmark" : "")
                                }
                            }
                        }
                        Menu("Change Category") {
                            ForEach(allCategories, id: \.self) { category in
                                Button(action: { onCategoryChange(category) }) {
                                    Label(category, systemImage: categoryIcon(for: category))
                                }
                            }
                        }
                        Divider()
                        Button(role: .destructive, action: onDelete) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 20, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(AppTheme.spacing16)
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
    }
    
    private func categoryIcon(for category: String) -> String {
        CategoryClassifier.categoryIcon(for: category)
    }
}

struct ShoppingFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let appTheme: AppTheme.ThemeType
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            Image(systemName: icon)
                .adaptiveForegroundColor()
                .font(.body)
                .frame(width: AppTheme.iconSize24)
            VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .adaptiveForegroundColor()
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
            }
            Spacer()
        }
    }
}

struct HelpSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            Text("Shopping List Features")
                                .font(.system(size: AppTheme.fontSize34, weight: .bold))
                                .adaptiveForegroundColor()
                            
                            Text("Learn how to make the most of your shopping list with these powerful features.")
                                .font(.system(size: AppTheme.fontSize17))
                                .adaptiveForegroundColor(opacity: AppTheme.nearSolidOpacity)
                                .lineSpacing(AppTheme.lineSpacingNormal)
                        }
                        .padding(.horizontal, AppTheme.spacing24)
                        .padding(.top, AppTheme.spacing60)
                        .padding(.bottom, AppTheme.spacing32)
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                            ShoppingFeatureRow(icon: "sparkles", title: "Smart Categories", description: "Items are automatically sorted into categories", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "chevron.up.chevron.down", title: "Collapse Categories", description: "Tap category headers to show or hide items", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "checkmark.circle", title: "Check Off Items", description: "Tap checkbox to mark items as purchased", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "storefront", title: "Tag by Store", description: "Long-press items to set preferred supermarket", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "plus.circle", title: "Quick Add", description: "Use menu (≡) to quickly add items", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "square.and.pencil", title: "Adjust Quantity", description: "Use +/- buttons to change item amounts", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "trash", title: "Delete Items", description: "Swipe left on any item to remove it", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "square.and.arrow.up", title: "Share List", description: "Export your list via menu (≡)", appTheme: appTheme)
                        }
                        .padding(AppTheme.spacing32)
                        .background {
                            if cardStyle == .solid {
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                                    .fill(AppTheme.adaptiveCardMedium(for: colorScheme).opacity(0.7))
                            } else {
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                                    .fill(.ultraThinMaterial.opacity(AppTheme.nearSolidOpacity))
                            }
                        }
                        .padding(.horizontal, AppTheme.spacing20)
                        .padding(.bottom, AppTheme.spacing40)
                    }
                }
                .ignoresSafeArea(edges: .top)
                
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.system(size: AppTheme.fontSize17, weight: .semibold))
                                .adaptiveForegroundColor()
                                .padding(.horizontal, AppTheme.spacing20)
                                .padding(.vertical, AppTheme.spacing8)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(AppTheme.cardDarkOpacity))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(AppTheme.overlayLightOpacity), lineWidth: 0.5)
                                        )
                                )
                        }
                        .padding(.trailing, AppTheme.spacing20)
                        .padding(.top, AppTheme.spacing12)
                    }
                    Spacer()
                }
            }
        }
    }
}
