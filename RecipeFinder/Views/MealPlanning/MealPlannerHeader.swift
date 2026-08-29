import SwiftUI

/// The meal planner's title bar with its overflow menu. Extracted from
/// `MealPlanningView`; menu actions are delegated through closures.
struct MealPlannerHeader: View {
    let onAddMeal: () -> Void
    let onNutritionTips: () -> Void
    let onClearOldPlans: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let spacing = AdaptiveSpacing(geometry: geometry)
            
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                
                Spacer()
                
                Text("Meal Planner")
                    .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                    .adaptiveForegroundColor()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Spacer()
                
                Menu {
                    Button(action: onAddMeal) {
                        Label("Add Meal", systemImage: "plus.circle")
                    }
                    
                    Button(action: onNutritionTips) {
                        Label("Nutrition Tips", systemImage: "heart.text.square")
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
            .frame(height: spacing.touchTarget)
            .padding(.horizontal, spacing.screenEdge)
            .padding(.top, spacing.lg)
            .padding(.bottom, spacing.xl)
        }
        .frame(height: AppTheme.height80)
    }
}
