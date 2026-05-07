import SwiftUI

struct ShoppingQuickAddSheet: View {
    @StateObject private var shoppingManager = ShoppingListManager.shared

    var body: some View {
        QuickAddSheetView(
            isItemAdded: { ingredient in
                shoppingManager.items.contains { $0.name.lowercased() == ingredient.lowercased() }
            },
            onAdd: { ingredient in
                shoppingManager.addItem(name: ingredient)
                HapticManager.shared.success()
            }
        )
    }
}
