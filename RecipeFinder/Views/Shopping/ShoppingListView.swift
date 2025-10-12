import SwiftUI

struct ShoppingListView: View {
    @StateObject private var manager = ShoppingListManager()
    @State private var newItem: String = ""
    @State private var showClearConfirmation = false
    @State private var collapsedCategories: Set<String> = []
    @State private var suggestedCategory: String = "Other"
    @Environment(\.colorScheme) var colorScheme
    
    let categoryOrder = ["Produce", "Meat & Seafood", "Dairy & Eggs", "Bakery", "Pantry", "Frozen", "Beverages", "Spices & Seasonings", "Other"]
    
    var sortedGroupedItems: [(category: String, items: [ShoppingListItem])] {
        let grouped = Dictionary(grouping: manager.items) { $0.category }
        return categoryOrder.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            let sortedItems = items.sorted { !$0.isChecked && $1.isChecked }
            return (category, sortedItems)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            // Options menu
                            Menu {
                                Button(action: { 
                                    withAnimation {
                                        if collapsedCategories.count == categoryOrder.count {
                                            collapsedCategories.removeAll()
                                        } else {
                                            collapsedCategories = Set(categoryOrder)
                                        }
                                    }
                                }) {
                                    Label(
                                        collapsedCategories.count == categoryOrder.count ? "Expand All" : "Collapse All",
                                        systemImage: collapsedCategories.count == categoryOrder.count ? "chevron.down.circle" : "chevron.up.circle"
                                    )
                                }
                                
                                Divider()
                                
                                Button(role: .destructive, action: { 
                                    showClearConfirmation = true 
                                }) {
                                    Label("Clear Checked Items", systemImage: "checkmark.circle")
                                }
                                Button(role: .destructive, action: { 
                                    showClearConfirmation = true 
                                }) {
                                    Label("Clear All Items", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Text("Shopping List")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if !manager.items.isEmpty {
                                    Text("\(manager.uncheckedCount) of \(manager.items.count) items")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            
                            Spacer()
                            
                            // Category indicator
                            VStack(spacing: 4) {
                                Image(systemName: categoryIcon(for: suggestedCategory))
                                    .font(.title3)
                                    .foregroundColor(.white)
                                Text(suggestedCategory == "Other" ? "Auto" : suggestedCategory)
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(AppTheme.accentColor.opacity(0.3))
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Input section
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                TextField("Add item (e.g., milk, chicken, apples)...", text: $newItem)
                                    .textFieldStyle(.plain)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.ultraThinMaterial)
                                    )
                                    .foregroundColor(.white)
                                    .onChange(of: newItem) { oldValue, newValue in
                                        suggestedCategory = CategoryClassifier.suggestCategory(for: newValue)
                                    }
                                    .onSubmit(addItem)
                                
                                Button(action: addItem) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                        .background(
                                            Circle()
                                                .fill(AppTheme.accentColor)
                                                .frame(width: 32, height: 32)
                                        )
                                }
                                .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
                                .opacity(newItem.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                            }
                            .padding(.horizontal, 20)
                            
                            // Progress bar
                            if !manager.items.isEmpty {
                                VStack(spacing: 4) {
                                    ProgressView(value: Double(manager.checkedCount), total: Double(manager.items.count))
                                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor))
                                    
                                    HStack {
                                        Text("\(manager.checkedCount) completed")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.7))
                                        Spacer()
                                        Text("\(Int((Double(manager.checkedCount) / Double(manager.items.count)) * 100))%")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
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
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Your shopping list is empty")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Items are automatically categorized")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Smart Categories")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text("Type 'milk' → Dairy, 'chicken' → Meat")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "list.bullet.indent")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto Grouping")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text("Items group by category automatically")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "hand.tap")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tap to Collapse")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text("Hide completed categories while shopping")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 30)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var shoppingListContent: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 16, pinnedViews: []) {
                ForEach(sortedGroupedItems, id: \.category) { group in
                    VStack(spacing: 8) {
                        // Category Header - Tappable
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                if collapsedCategories.contains(group.category) {
                                    collapsedCategories.remove(group.category)
                                } else {
                                    collapsedCategories.insert(group.category)
                                }
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: categoryIcon(for: group.category))
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 28)
                                
                                Text(group.category)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("(\(group.items.filter { !$0.isChecked }.count)/\(group.items.count))")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Spacer()
                                
                                Image(systemName: collapsedCategories.contains(group.category) ? "chevron.down" : "chevron.up")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                    .rotationEffect(.degrees(collapsedCategories.contains(group.category) ? 0 : 180))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        // Items in category
                        if !collapsedCategories.contains(group.category) {
                            VStack(spacing: 8) {
                                ForEach(group.items) { item in
                                    if let index = manager.items.firstIndex(where: { $0.id == item.id }) {
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
                                            allCategories: categoryOrder
                                        )
                                    }
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private func addItem() {
        guard !newItem.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(.spring(response: 0.3)) {
            manager.addItem(name: newItem)
            newItem = ""
            suggestedCategory = "Other"
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Produce": return "leaf.fill"
        case "Meat & Seafood": return "fish.fill"
        case "Dairy & Eggs": return "drop.fill"
        case "Bakery": return "birthday.cake.fill"
        case "Pantry": return "cabinet.fill"
        case "Frozen": return "snowflake"
        case "Beverages": return "cup.and.saucer.fill"
        case "Spices & Seasonings": return "sparkles"
        default: return "basket.fill"
        }
    }
}

// MARK: - Shopping List Item Row
struct ShoppingListItemRow: View {
    let item: ShoppingListItem
    let onToggle: () -> Void
    let onQuantityChange: (Int) -> Void
    let onDelete: () -> Void
    let onCategoryChange: (String) -> Void
    let allCategories: [String]
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                Button(action: onToggle) {
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
                }
                
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(item.isChecked)
                    .foregroundColor(item.isChecked ? .gray : .primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Quantity display on the right
                    if item.quantity > 1 {
                        Text("\(item.quantity)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(minWidth: 20)
                    }
                    
                    Stepper("", value: Binding(
                        get: { item.quantity },
                        set: { onQuantityChange($0) }
                    ), in: 1...99)
                    .labelsHidden()
                    .opacity(item.isChecked ? 0.5 : 1)
                    .fixedSize()
                }
            }
            .padding(14)
        }
        .opacity(item.isChecked ? 0.6 : 1)
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
        switch category {
        case "Produce": return "leaf.fill"
        case "Meat & Seafood": return "fish.fill"
        case "Dairy & Eggs": return "drop.fill"
        case "Bakery": return "birthday.cake.fill"
        case "Pantry": return "cabinet.fill"
        case "Frozen": return "snowflake"
        case "Beverages": return "cup.and.saucer.fill"
        case "Spices & Seasonings": return "sparkles"
        default: return "basket.fill"
        }
    }
}
