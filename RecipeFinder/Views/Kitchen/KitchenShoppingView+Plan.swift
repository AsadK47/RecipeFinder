import SwiftUI

// Groceries writes itself, slice 1: the "From your plan" card's data and action. The maths is pure and tested
// (`WeekGroceryPlan`); this is the glue to the managers.
extension KitchenShoppingView {
    /// The next seven days from today (`weekShoppingSummary` counts seven days from the given start).
    func refreshPlanNeeds() {
        let now = Date()
        let summary = mealPlanning.weekShoppingSummary(forWeekStarting: now, recipes: recipeStore.recipes)
        planNeeds = WeekGroceryPlan(
            summary: summary,
            kitchenNames: kitchen.items.map(\.name) + kitchen.inventoryItems.map(\.name),
            listItems: shopping.items
        )
        stillGot = StillGotCheck(summary: summary, kitchenItems: kitchen.items,
                                 inventoryNames: kitchen.inventoryItems.map(\.name), now: now)
    }

    func addPlanNeeds() {
        planNeeds.add(to: shopping)
        HapticManager.shared.success()
    }

    /// "Still got the coriander?" — the longest-overdue question, if any.
    @ViewBuilder
    var stillGotCard: some View {
        if let question = stillGot.first(skipping: skippedStillGot) {
            StillGotCard(
                question: question,
                onYes: {
                    question.answerYes(kitchen: kitchen)
                    HapticManager.shared.light()
                },
                // Taking it off At home plays the kitchen's own haptic.
                onNo: { question.answerNo(kitchen: kitchen, shopping: shopping) },
                onLater: { skippedStillGot.insert(question.id) }
            )
        }
    }
}
