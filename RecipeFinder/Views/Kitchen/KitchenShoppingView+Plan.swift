import SwiftUI

// Groceries writes itself, slice 1: the "From your plan" card's data and action. The maths is pure and tested
// (`WeekGroceryPlan`); this is the glue to the managers.
extension KitchenShoppingView {
    /// The next seven days from today (`weekShoppingSummary` counts seven days from the given start).
    func refreshPlanNeeds() {
        planNeeds = WeekGroceryPlan(
            summary: mealPlanning.weekShoppingSummary(forWeekStarting: Date(), recipes: recipeStore.recipes),
            kitchenNames: kitchen.items.map(\.name) + kitchen.inventoryItems.map(\.name),
            listItems: shopping.items
        )
    }

    func addPlanNeeds() {
        planNeeds.add(to: shopping)
        HapticManager.shared.success()
    }
}
