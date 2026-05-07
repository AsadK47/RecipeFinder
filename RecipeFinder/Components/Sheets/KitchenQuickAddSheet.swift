import SwiftUI

struct KitchenQuickAddSheet: View {
    @StateObject private var kitchenManager = KitchenInventoryManager.shared

    var body: some View {
        QuickAddSheetView(
            isItemAdded: { ingredient in
                kitchenManager.items.contains { $0.name.lowercased() == ingredient.lowercased() }
            },
            onAdd: { ingredient in
                kitchenManager.toggleItem(ingredient)
                HapticManager.shared.success()
            }
        )
    }
}
