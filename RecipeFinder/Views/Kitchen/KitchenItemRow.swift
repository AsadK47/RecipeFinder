import SwiftUI

/// A single ingredient row in the kitchen inventory list: quantity steppers plus
/// a menu for changing category or removing the item.
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
