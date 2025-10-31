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
        var text = "🛒 Shopping List\n\n"
        
        for group in sortedGroupedItems {
            text += "\(group.key)\n"
            for item in group.value {
                let checkbox = item.isChecked ? "✓" : "○"
                text += "\(checkbox) \(item.name)\n"
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
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Spacer()
                            
                            // Title in center
                            Text("Shopping List")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Right button - Options menu (only if items exist)
                            if !manager.items.isEmpty {
                                Menu {
                                    Button(action: shareShoppingList) {
                                        Label("Share List", systemImage: "square.and.arrow.up")
                                    }
                                    
                                    Divider()
                                    
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
                                    ModernCircleButton(icon: "ellipsis.circle") {}
                                        .allowsHitTesting(false)
                                }
                            } else {
                                // Empty spacer to balance layout
                                Color.clear
                                    .frame(width: 44, height: 44)
                            }
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
                        .animation(.spring(response: 0.3), value: isSearchFocused)
                        
                        // Progress bar below search
                        if !manager.items.isEmpty {
                            VStack(spacing: 6) {
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
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
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
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "cart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 48)
                    
                    Text("Start Your Shopping List")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Add items using the search bar above or tap the + button on any recipe")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 24)
                
                // Always show features card
                VStack(alignment: .leading, spacing: 16) {
                    ShoppingFeatureRow(icon: "sparkles", title: "Smart Categories", description: "Type 'milk' → Dairy, 'chicken' → Meat", appTheme: appTheme)
                    ShoppingFeatureRow(icon: "list.bullet.indent", title: "Auto Grouping", description: "Items group by category automatically", appTheme: appTheme)
                    ShoppingFeatureRow(icon: "hand.tap", title: "Tap to Collapse", description: "Hide completed categories while shopping", appTheme: appTheme)
                    ShoppingFeatureRow(icon: "checkmark.circle", title: "Check Off Items", description: "Tap checkbox or swipe to mark as purchased", appTheme: appTheme)
                    ShoppingFeatureRow(icon: "trash", title: "Delete Items", description: "Swipe left on any item to remove it", appTheme: appTheme)
                    ShoppingFeatureRow(icon: "ellipsis.circle", title: "Bulk Actions", description: "Use menu (⋯) to clear checked or all items", appTheme: appTheme)
                    ShoppingFeatureRow(icon: "square.and.pencil", title: "Edit Quantity", description: "Tap item to change amount or category", appTheme: appTheme)
                }
                .padding(20)
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
            }
            .padding(.bottom, 40)
        }
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
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("❌ ShoppingListView: Empty search text")
            return
        }
        print("🔍 ShoppingListView: Adding item '\(searchText)'")
        withAnimation(.spring(response: 0.3)) {
            manager.addItem(name: searchText)
            searchText = ""
            isSearchFocused = false
            HapticManager.shared.success()
        }
        print("📊 ShoppingListView: Manager now has \(manager.items.count) items")
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
                    .buttonStyle(PlainButtonStyle())
                    
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
                action: onDelete,
                label: {
                    Image(systemName: "trash")
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
                .foregroundColor(AppTheme.accentColor(for: appTheme))
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
                            ShoppingFeatureRow(icon: "sparkles", title: "Smart Categories", description: "Type 'milk' → Dairy, 'chicken' → Meat", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "list.bullet.indent", title: "Auto Grouping", description: "Items group by category automatically", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "hand.tap", title: "Tap to Collapse", description: "Hide completed categories while shopping", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "checkmark.circle", title: "Check Off Items", description: "Tap checkbox or swipe to mark as purchased", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "trash", title: "Delete Items", description: "Swipe left on any item to remove it", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "ellipsis.circle", title: "Bulk Actions", description: "Use menu (⋯) to clear checked or all items", appTheme: appTheme)
                            ShoppingFeatureRow(icon: "square.and.pencil", title: "Edit Quantity", description: "Tap item to change amount or category", appTheme: appTheme)
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
