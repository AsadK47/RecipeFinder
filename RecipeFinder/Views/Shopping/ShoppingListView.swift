import SwiftUI
import ConfettiSwiftUI

struct ShoppingListView: View {
    @ObservedObject var manager: ShoppingListManager
    @State private var searchText: String = ""
    @State private var showClearConfirmation = false
    @State private var collapsedCategories: Set<String> = []
    @State private var confettiTrigger = 0
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    
    var sortedGroupedItems: [(category: String, items: [ShoppingListItem])] {
        let grouped = Dictionary(grouping: manager.items) { $0.category }
        return CategoryClassifier.categoryOrder.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            let sortedItems = items.sorted { !$0.isChecked && $1.isChecked }
            return (category, sortedItems)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            // Options menu
                            Menu {
                Button(action: { 
                    withAnimation {
                        if collapsedCategories.count == CategoryClassifier.categoryOrder.count {
                            collapsedCategories.removeAll()
                        } else {
                            collapsedCategories = Set(CategoryClassifier.categoryOrder)
                        }
                    }
                }) {
                    Label(
                        collapsedCategories.count == CategoryClassifier.categoryOrder.count ? "Expand All" : "Collapse All",
                        systemImage: collapsedCategories.count == CategoryClassifier.categoryOrder.count ? "chevron.down.circle" : "chevron.up.circle"
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
                            
                            VStack(spacing: 8) {
                                Text("Shopping List")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if !manager.items.isEmpty {
                                    // Progress indicator integrated with count
                                    HStack(spacing: 8) {
                                        Text("\(manager.checkedCount)/\(manager.items.count)")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(.white.opacity(0.3))
                                                    .frame(height: 4)
                                                
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(.white)
                                                    .frame(
                                                        width: geometry.size.width * (Double(manager.checkedCount) / Double(manager.items.count)),
                                                        height: 4
                                                    )
                                            }
                                        }
                                        .frame(width: 60, height: 4)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Balance spacer for centering
                            Color.clear
                                .frame(width: 48, height: 48)
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
                                    Button(action: { 
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.5))
                                    }
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                            )
                            
                            if isSearchFocused || !searchText.isEmpty {
                                Button(action: {
                                    if !searchText.isEmpty {
                                        addItem()
                                    } else {
                                        searchText = ""
                                        isSearchFocused = false
                                    }
                                }) {
                                    Text(searchText.isEmpty ? "Cancel" : "Add")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 20)
                        .animation(.spring(response: 0.3), value: isSearchFocused)
                        .animation(.spring(response: 0.3), value: searchText.isEmpty)
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
            .onChange(of: manager.checkedCount) { oldValue, newValue in
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
                .headerProminence(.standard)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListHeaderHeight, 0)
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

// MARK: - Shopping List Item Row
struct ShoppingListItemRow: View {
    let item: ShoppingListItem
    let onToggle: () -> Void
    let onQuantityChange: (Int) -> Void
    let onDelete: () -> Void
    let onCategoryChange: (String) -> Void
    let allCategories: [String]
    
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

// MARK: - Edit Item Sheet

