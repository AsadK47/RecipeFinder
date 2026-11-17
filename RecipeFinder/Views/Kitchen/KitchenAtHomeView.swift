import SwiftUI

/// Groceries' *At home* side: what's in the kitchen, by category. It powers Today's
/// "Fits your kitchen" and use-it-up, so it sits one tap from the shopping list rather than behind a menu.
struct KitchenAtHomeView: View {
    @Binding var collapsed: Set<String>
    let onAddIngredient: () -> Void

    @Environment(\.kitchen) private var manager

    var body: some View {
        // Items with a use-by date live apart from the plain list; they still count, or Today's "Use it up" link
        // would land on "Your kitchen is empty" above the very items it's about.
        if manager.items.isEmpty && manager.inventoryItems.isEmpty {
            ScrollView {
                EmptyStateView(
                    icon: "refrigerator",
                    title: "Your kitchen is empty",
                    message: "Add what you have at home to find recipes that fit it.",
                    actionTitle: "Add Ingredient",
                    onAction: onAddIngredient
                )
            }
            .accessibilityIdentifier("groceries.atHome")
        } else {
            List {
                KitchenSectionsView(collapsedCategories: $collapsed, onAddMore: onAddIngredient)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .environment(\.defaultMinListHeaderHeight, 0)
            .accessibilityIdentifier("groceries.atHome")
        }
    }
}
