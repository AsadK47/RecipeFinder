import SwiftUI

struct KitchenQuickAddSheet: View {
    @Environment(\.kitchen) private var kitchenManager

    var body: some View {
        QuickAddSheetView(
            isItemAdded: { ingredient in
                kitchenManager.items.contains { $0.name.lowercased() == ingredient.lowercased() }
            },
            onAdd: { ingredient in
                kitchenManager.toggleItem(ingredient, category: nil)
                HapticManager.shared.success()
            }
        )
    }
}
