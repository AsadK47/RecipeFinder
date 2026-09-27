import SwiftUI

/// The meal planner's title bar with overflow menu; menu actions delegated via closures.
struct MealPlannerHeader: View {
    let onAddMeal: () -> Void
    let onClearOldPlans: () -> Void

    var body: some View {
        ScreenTitleHeader("Meal Planner") {
            Menu {
                Button(action: onAddMeal) {
                    Label("Add Meal", systemImage: "plus.circle")
                }

                Divider()

                Button(role: .destructive, action: onClearOldPlans) {
                    Label("Clear Old Plans", systemImage: "trash")
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: AppTheme.fontSize20))
                    .adaptiveForegroundColor()
                    .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
            }
        }
    }
}
