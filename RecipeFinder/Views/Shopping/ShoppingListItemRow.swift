import SwiftUI

/// Single shopping-list row: checkbox, name/store, quantity steppers, and a store/category/delete menu.
struct ShoppingListItemRow: View {
    /// Matches `ShoppingListManager`'s 999 cap; the row used 99, so + went dead at 200 g.
    static let maxQuantity = 999

    let item: ShoppingListModel
    let isInKitchen: Bool
    let onToggle: () -> Void
    let onQuantityChange: (Int) -> Void
    let onDelete: () -> Void
    let onCategoryChange: (String) -> Void
    let onStoreChange: (String?) -> Void
    let onToggleRecurring: () -> Void
    let allCategories: [String]
    let availableStores: [String] = ["ASDA", "Tesco", "Sainsbury's", "Lidl", "Aldi", "Morrisons", "Waitrose"]
    

    private var defaultCategory: String {
        CategoryClassifier.categorize(item.name)
    }

    private var categoryChoices: [String] {
        [defaultCategory] + allCategories.filter { $0 != defaultCategory }
    }

    private var popularCategories: [String] {
        let baseline = ["Produce", "Dairy & Eggs", "Meat", "Poultry", "Seafood", "Sauces & Condiments"]
        let available = baseline.filter { allCategories.contains($0) && $0 != defaultCategory }

        // Keep compact to reduce menu rendering work and UI jitter.
        if available.count >= 5 {
            return available
        }

        let fallback = allCategories.filter { !available.contains($0) && $0 != defaultCategory }
        return Array((available + fallback).prefix(5))
    }

    private var moreCategories: [String] {
        categoryChoices.dropFirst().filter { !popularCategories.contains($0) }
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: AppTheme.spacing12) {
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
                    .contentShape(Rectangle())
                })
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacing8) {
                        Text(item.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .strikethrough(item.isChecked)
                            .foregroundStyle(item.isChecked ? .gray : AppTheme.adaptiveEmphasis())
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        if item.isRecurring {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.orange)
                                .rotationEffect(.degrees(45))
                        }

                        if isInKitchen {
                            Text("In kitchen")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, AppTheme.spacing6)
                                .padding(.vertical, AppTheme.spacing2)
                                .background(Color.blue.opacity(0.12), in: Capsule())
                                .fixedSize()
                        }
                    }
                    
                    if let store = item.preferredStore {
                        // Scheme-aware secondary colour — teal accent text was unreadable on the frosted card.
                        Text(store)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .adaptiveSecondaryForeground()
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: AppTheme.spacing8) {
                    Button(action: {
                        if item.quantity > 1 {
                            onQuantityChange(item.quantity - 1)
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                            .foregroundStyle(item.quantity > 1 ? (AppTheme.adaptiveEmphasis()) : .gray)
                            .frame(width: AppTheme.iconSize28, height: AppTheme.iconSize28)
                            .appCard(in: Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(item.quantity <= 1)
                    
                    // Show the unit too — "200" alone (for 200 g) read as 200 items.
                    Text(item.unit.isEmpty ? "\(item.quantity)" : "\(item.quantity) \(item.unit)")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .lineLimit(1)
                        .frame(minWidth: AppTheme.iconSize20)
                    
                    Button(action: {
                        if item.quantity < ShoppingListItemRow.maxQuantity {
                            onQuantityChange(item.quantity + 1)
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                            .foregroundStyle(item.quantity < ShoppingListItemRow.maxQuantity ? (AppTheme.adaptiveEmphasis()) : .gray)
                            .frame(width: AppTheme.iconSize28, height: AppTheme.iconSize28)
                            .appCard(in: Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(item.quantity >= ShoppingListItemRow.maxQuantity)
                }
                .opacity(item.isChecked ? 0.5 : 1)
                
                Menu {
                    Menu("Change Store") {
                        Button(action: { onStoreChange(nil) }) {
                            if item.preferredStore == nil {
                                Label("None", systemImage: "checkmark")
                            } else {
                                Text("None")
                            }
                        }
                        ForEach(availableStores, id: \.self) { store in
                            Button(action: { onStoreChange(store) }) {
                                if item.preferredStore == store {
                                    Label(store, systemImage: "checkmark")
                                } else {
                                    Text(store)
                                }
                            }
                        }
                    }
                    Menu("Change Category") {
                        Button(action: { onCategoryChange(defaultCategory) }) {
                            Label("Default (\(defaultCategory))", systemImage: CategoryClassifier.categoryIcon(for: defaultCategory))
                        }

                        Divider()

                        ForEach(popularCategories, id: \.self) { category in
                            Button(action: { onCategoryChange(category) }) {
                                Label(category, systemImage: CategoryClassifier.categoryIcon(for: category))
                            }
                        }

                        if !moreCategories.isEmpty {
                            Menu("More Categories") {
                                ForEach(moreCategories, id: \.self) { category in
                                    Button(action: { onCategoryChange(category) }) {
                                        Label(category, systemImage: CategoryClassifier.categoryIcon(for: category))
                                    }
                                }
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
                        .adaptiveSecondaryForeground()
                        .frame(width: 18, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.vertical, AppTheme.spacing10)
            .appCard(elevated: true)
            .opacity(item.isChecked ? 0.6 : 1)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: onToggleRecurring) {
                Label(
                    item.isRecurring ? "Unpin" : "Pin",
                    systemImage: item.isRecurring ? "pin.slash.fill" : "pin.fill"
                )
            }
            .tint(.orange)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(
                role: .destructive,
                action: onDelete
            ) {
                Label("Delete", systemImage: "trash")
            }
            .tint(AppTheme.error)
        }
    }
}
