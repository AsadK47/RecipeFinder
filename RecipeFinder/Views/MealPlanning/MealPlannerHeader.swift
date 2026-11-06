import SwiftUI

/// The meal planner's title bar with overflow menu; menu actions delegated via closures.
struct MealPlannerHeader: View {
    let onAddMeal: () -> Void
    let onClearOldPlans: () -> Void

    var body: some View {
        ScreenTitleHeader("Meal Planner") {
            CircleMenuButton(accessibilityLabel: "More options") {
                Button(action: onAddMeal) {
                    Label("Add Meal", systemImage: "plus.circle")
                }

                Divider()

                Button(role: .destructive, action: onClearOldPlans) {
                    Label("Clear Old Plans", systemImage: "trash")
                }
            }
        }
    }
}
