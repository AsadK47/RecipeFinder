import SwiftUI

struct ShoppingListView: View {
    @ObservedObject var manager: ShoppingListManager
    @State private var newItem: String = ""
    @State private var showClearConfirmation = false
    @State private var collapsedCategories: Set<String> = []
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
                                    Label("Clear Items", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
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
                            
                            // Balance spacer for centering
                            Color.clear
                                .frame(width: 48, height: 48)
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
                                            .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                                    )
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
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
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                                        Spacer()
                                        Text("\(Int((Double(manager.checkedCount) / Double(manager.items.count)) * 100))%")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.7))
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
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.3))
            
            Text("Your shopping list is empty")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text("Items are automatically categorized")
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.title3)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
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
                    VStack(alignment: .leading, spacing: 2) {
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
                    VStack(alignment: .leading, spacing: 2) {
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
        List {
            ForEach(sortedGroupedItems, id: \.category) { group in
                Section {
                    // Items in category
                    if !collapsedCategories.contains(group.category) {
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
                                    onNameChange: { newName in
                                        manager.updateName(at: index, name: newName)
                                    },
                                    onCategoryChange: { newCategory in
                                        withAnimation(.spring(response: 0.3)) {
                                            manager.updateCategory(at: index, category: newCategory)
                                        }
                                    },
                                    allCategories: categoryOrder
                                )
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                } header: {
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
                                .foregroundColor(categoryColor(for: group.category))
                                .frame(width: 28)
                            
                            Text(group.category)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("(\(group.items.filter { !$0.isChecked }.count)/\(group.items.count))")
                                .font(.subheadline)
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.4))
                            
                            Spacer()
                            
                            Image(systemName: collapsedCategories.contains(group.category) ? "chevron.down" : "chevron.up")
                                .font(.caption)
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.4))
                                .rotationEffect(.degrees(collapsedCategories.contains(group.category) ? 0 : 180))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .buttonStyle(.plain)
                    .textCase(nil)
                    .listRowInsets(EdgeInsets())
                }
                .headerProminence(.increased)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListHeaderHeight, 0)
    }
    
    private func addItem() {
        guard !newItem.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(.spring(response: 0.3)) {
            manager.addItem(name: newItem)
            newItem = ""
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
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Produce": return .green
        case "Meat & Seafood": return .red
        case "Dairy & Eggs": return .blue
        case "Bakery": return .orange
        case "Pantry": return .brown
        case "Frozen": return .cyan
        case "Beverages": return .purple
        case "Spices & Seasonings": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Shopping List Item Row
struct ShoppingListItemRow: View {
    let item: ShoppingListItem
    let onToggle: () -> Void
    let onQuantityChange: (Int) -> Void
    let onDelete: () -> Void
    let onNameChange: (String) -> Void
    let onCategoryChange: (String) -> Void
    let allCategories: [String]
    
    @State private var showEditSheet = false
    @State private var editedName = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
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
                        .foregroundColor(item.isChecked ? .gray : (colorScheme == .dark ? .white : .black))
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Quantity display on the right
                        if item.quantity > 1 {
                            Text("\(item.quantity)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
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
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                editedName = item.name
                showEditSheet = true
            } label: {
                Image(systemName: "pencil")
            }
            .tint(.blue)
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
        .sheet(isPresented: $showEditSheet) {
            EditItemSheet(
                itemName: editedName,
                onSave: { newName in
                    if !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onNameChange(newName)
                    }
                }
            )
            .presentationDetents([.height(250)])
            .presentationDragIndicator(.visible)
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

// MARK: - Edit Item Sheet
struct EditItemSheet: View {
    @State var itemName: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Item")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                TextField("Item name", text: $itemName)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                    .padding(.horizontal)
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(itemName)
                        dismiss()
                    }
                    .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
