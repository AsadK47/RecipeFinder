import SwiftUI

struct ShoppingQuickAddSheet: View {
    @Environment(\.shopping) private var shoppingManager

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
