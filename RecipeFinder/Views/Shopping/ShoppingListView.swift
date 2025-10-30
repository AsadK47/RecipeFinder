import ConfettiSwiftUI
import SwiftUI

struct ShoppingListView: View {
    @ObservedObject var manager: ShoppingListManager
    @State private var searchText: String = ""
    @State private var showClearConfirmation = false
    @State private var collapsedCategories: Set<String> = []
    @State private var confettiTrigger = 0
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    private var sortedGroupedItems: [(key: String, value: [ShoppingListItem])] {
        manager.groupedItems.map { (key: $0.category, value: $0.items) }
    }
    
    private func shareShoppingList() {
        var text = "🛒 MY SHOPPING LIST\n"
        text += String(repeating: "━", count: 40) + "\n\n"
        
        for group in sortedGroupedItems {
            let icon = CategoryClassifier.categoryIcon(for: group.key)
            text += "\(icon) \(group.key.uppercased())\n"
            text += String(repeating: "─", count: 40) + "\n"
            
            for item in group.value {
                let checkbox = item.isChecked ? "☑" : "☐"
                text += "  \(checkbox) \(item.name)\n"
            }
            text += "\n"
        }
        
        text += String(repeating: "━", count: 40) + "\n"
        text += "Created with RecipeFinder\n"
        
        let activityController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        // Use proper window scene access (iOS 15+)
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        
        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
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
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            HStack {
                                Spacer()
                                
                                if !manager.items.isEmpty {
                                    HStack(spacing: 12) {
                                        // Share button
                                        Button(action: shareShoppingList) {
                                            Image(systemName: "square.and.arrow.up")
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
                                        
                                        // Options menu
                                        Menu {
                                            Button(
                                                action: { 
                                                    withAnimation {
                                                        if collapsedCategories.count == CategoryClassifier.categoryOrder.count {
                                                            collapsedCategories.removeAll()
                                                        } else {
                                                            collapsedCategories = Set(CategoryClassifier.categoryOrder)
                                                        }
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
                            }
                            
                            Text("Shopping List")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        
                        // Search bar with cancel option
                        HStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.6))
                                    .font(.body)
                                
                                TextField("Add item (e.g., milk, chicken, apples)...", text: $searchText)
                                    .focused($isSearchFocused)
                                    .autocorrectionDisabled()
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .onSubmit(addItem)
                                
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
                                        .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.regularMaterial)
                                }
                            }
                            
                            if isSearchFocused || !searchText.isEmpty {
                                Button(
                                    action: {
                                        if !searchText.isEmpty {
                                            addItem()
                                        } else {
                                            searchText = ""
                                            isSearchFocused = false
                                        }
                                    },
                                    label: {
                                        Text(searchText.isEmpty ? "Cancel" : "Add")
                                            .foregroundColor(.white)
                                            .fontWeight(.semibold)
                                    }
                                )
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 20)
                        .animation(.spring(response: 0.3), value: isSearchFocused)
                        .animation(.spring(response: 0.3), value: searchText.isEmpty)
                        
                        // Progress bar below search
                        if !manager.items.isEmpty {
                            VStack(spacing: 8) {
                                ProgressView(value: Double(manager.checkedCount), total: Double(manager.items.count))
                                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
                                    .frame(height: 8)
                                
                                HStack {
                                    Text("\(manager.checkedCount)/\(manager.items.count) completed")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Content
                    if manager.items.isEmpty {
                        emptyStateView
                    } else {
                        shoppingListContent
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
            .onChange(of: manager.checkedCount) { _, newValue in
                // Trigger confetti when all items are checked (but only if there are items)
                if !manager.items.isEmpty && newValue == manager.items.count {
                    HapticManager.shared.success()
                    confettiTrigger += 1
                }
            }
            .confirmationDialog("Clear Items", isPresented: $showClearConfirmation) {
                if manager.checkedCount > 0 {
                    Button("Clear Checked Items (\(manager.checkedCount))", role: .destructive) {
                        withAnimation {
                            manager.clearCheckedItems()
                        }
                    }
                }
                Button("Clear All Items (\(manager.items.count))", role: .destructive) {
                    withAnimation {
                        manager.clearAllItems()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Choose which items to remove from your shopping list")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cart")
                .font(.system(size: 65))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.3))
                .padding(.top, 16)
            
            Text("Your shopping list is empty")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text("Items are automatically categorized")
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                .padding(.bottom, 6)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.title3)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Smart Categories")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text("Type 'milk' → Dairy, 'chicken' → Meat")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                    }
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "list.bullet.indent")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.title3)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Auto Grouping")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text("Items group by category automatically")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                    }
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "hand.tap")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.title3)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Tap to Collapse")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text("Hide completed categories while shopping")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                    }
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.title3)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Check Off Items")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text("Tap checkbox or swipe to mark as purchased")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                    }
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.title3)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Delete Items")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text("Swipe left on any item to remove it")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                    }
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.title3)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Bulk Actions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text("Use menu (⋯) to clear checked or all items")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                    }
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.title3)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Edit Quantity")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        Text("Tap item to change amount or category")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                            .lineSpacing(2)
                    }
                    Spacer()
                }
            }
            .padding(16)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.regularMaterial)
                }
            }
            .padding(.horizontal, 30)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var shoppingListContent: some View {
        listView
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .environment(\.defaultMinListHeaderHeight, 0)
    }
    
    private var listView: some View {
        List {
            ForEach(sortedGroupedItems, id: \.key) { group in
                categorySection(for: group.key, items: group.value)
            }
        }
    }
    
    @ViewBuilder
    private func categorySection(for category: String, items: [ShoppingListItem]) -> some View {
        Section {
            if !collapsedCategories.contains(category) {
                categoryItems(for: items)
            }
        } header: {
            categorySectionHeader(category: category, items: items)
        }
    }
    
    @ViewBuilder
    private func categoryItems(for items: [ShoppingListItem]) -> some View {
        ForEach(items) { item in
            if let index = manager.items.firstIndex(where: { $0.id == item.id }) {
                itemRow(for: item, at: index)
            }
        }
    }
    
    @ViewBuilder
    private func itemRow(for item: ShoppingListItem, at index: Int) -> some View {
        ShoppingListItemRow(
            item: item,
            onToggle: { 
                withAnimation(.spring(response: 0.3)) {
                    manager.toggleItem(at: index)
                }
            },
            onQuantityChange: { newQuantity in
                manager.updateQuantity(at: index, quantity: newQuantity)
            },
            onDelete: { 
                withAnimation(.spring(response: 0.3)) {
                    manager.deleteItem(at: index)
                }
            },
            onCategoryChange: { newCategory in
                withAnimation(.spring(response: 0.3)) {
                    manager.updateCategory(at: index, category: newCategory)
                }
            },
            allCategories: CategoryClassifier.categoryOrder
        )
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
    
    @ViewBuilder
    private func categorySectionHeader(category: String, items: [ShoppingListItem]) -> some View {
        Button(
            action: {
                withAnimation(.spring(response: 0.3)) {
                    if collapsedCategories.contains(category) {
                        collapsedCategories.remove(category)
                    } else {
                        collapsedCategories.insert(category)
                    }
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
                            .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
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
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(.spring(response: 0.3)) {
            manager.addItem(name: searchText)
            searchText = ""
        }
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
    let item: ShoppingListItem
    let onToggle: () -> Void
    let onQuantityChange: (Int) -> Void
    let onDelete: () -> Void
    let onCategoryChange: (String) -> Void
    let allCategories: [String]
    
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
                    
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(item.isChecked)
                        .foregroundColor(item.isChecked ? .gray: (colorScheme == .dark ? .white: .black))
                    
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
                        .disabled(item.quantity >= 99)
                    }
                    .opacity(item.isChecked ? 0.5 : 1)
                }
                .padding(14)
            }
            .opacity(item.isChecked ? 0.6 : 1)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(
                action: onToggle,
                label: {
                    Label(item.isChecked ? "Uncheck" : "Check", systemImage: item.isChecked ? "xmark.circle" : "checkmark.circle")
                }
            )
            .tint(item.isChecked ? .orange : .green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(
                role: .destructive,
                action: onDelete,
                label: {
                    Label("Delete", systemImage: "trash")
                }
            )
        }
        .contextMenu {
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
