import SwiftUI

/// Empty state for the meal planner's selected-day detail; add-meal action delegated via closure.
struct SelectedDayEmptyStateView: View {
    let selectedDateString: String
    let shortDateString: String
    let onAddMeal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
            HStack {
                Text("Meals for")
                    .font(.system(size: AppTheme.fontSize20, weight: .bold))
                    .adaptiveForegroundColor()
                
                Spacer()
                
                Text(selectedDateString)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.adaptive(light: Color.black.opacity(AppTheme.subduedEmphasisOpacity), dark: Color.white.opacity(AppTheme.subduedEmphasisOpacity)))
            }
            .padding(.horizontal, AppTheme.spacing4)
            
            VStack(spacing: AppTheme.spacing16) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: AppTheme.fontSize60))
                    .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
                
                Text("No Meals Planned for This Day")
                    .font(.title2)
                    .fontWeight(.bold)
                    .adaptiveForegroundColor()
                
                Text("Tap below to add meals for \(shortDateString)")
                    .font(.subheadline)
                    .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                    .multilineTextAlignment(.center)
                
                PrimaryButton("Add Meal", systemImage: "plus.circle.fill", action: onAddMeal)
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.spacing40)
            .appCard()
        }
    }
}

/// Shown when the selected day is in the past and has no plans.
struct MealPlanEmptyStateView: View {
    let onPlanMeal: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacing16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: AppTheme.fontSize60))
                .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
            
            Text("No Meals Planned Yet")
                .font(.title2)
                .fontWeight(.bold)
                .adaptiveForegroundColor()
            
            Text("Tap on a date to start planning your meals")
                .font(.subheadline)
                .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                .multilineTextAlignment(.center)
            
            PrimaryButton("Plan a Meal", systemImage: "plus.circle.fill", action: onPlanMeal)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacing48)
    }
}
