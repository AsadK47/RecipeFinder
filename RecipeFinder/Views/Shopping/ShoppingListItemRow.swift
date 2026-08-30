import SwiftUI

/// A single shopping list item row: a checkbox, name/store, quantity steppers,
/// and a menu for store/category changes and deletion.
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

    private var defaultCategory: String {
        CategoryClassifier.categorize(item.name)
    }

    private var categoryChoices: [String] {
        [defaultCategory] + allCategories.filter { $0 != defaultCategory }
    }

    private var popularCategories: [String] {
        let baseline = ["Produce", "Dairy & Eggs", "Meat", "Poultry", "Seafood", "Sauces & Condiments"]
        let available = baseline.filter { allCategories.contains($0) && $0 != defaultCategory }

        // Keep the list compact to reduce menu rendering work and UI jitter.
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
            GlassCard {
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
                    
                    HStack(spacing: AppTheme.spacing8) {
                        Button(action: {
                            if item.quantity > 1 {
                                onQuantityChange(item.quantity - 1)
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                                .foregroundColor(item.quantity > 1 ? (AppTheme.adaptiveEmphasis(for: colorScheme)) : .gray)
                                .frame(width: AppTheme.iconSize28, height: AppTheme.iconSize28)
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
                            .font(.callout)
                            .fontWeight(.semibold)
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
                                .frame(width: AppTheme.iconSize28, height: AppTheme.iconSize28)
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
                            .foregroundStyle(.secondary)
                            .frame(width: 18, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppTheme.spacing12)
                .padding(.vertical, AppTheme.spacing10)
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
}
