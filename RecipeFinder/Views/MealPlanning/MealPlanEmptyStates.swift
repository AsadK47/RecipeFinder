import SwiftUI

/// Empty-state views for the meal planner's selected-day detail area. Extracted
/// from `MealPlanningView`; the add-meal action is delegated through a closure.
struct SelectedDayEmptyStateView: View {
    let selectedDateString: String
    let shortDateString: String
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
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
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(AppTheme.subduedEmphasisOpacity) : .black.opacity(AppTheme.subduedEmphasisOpacity))
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
                
                Button(action: onAddMeal) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Meal")
                            .fontWeight(.semibold)
                    }
                    .adaptiveForegroundColor()
                    .padding(.horizontal, AppTheme.spacing24)
                    .padding(.vertical, AppTheme.spacing14)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.overlayLightOpacity) : Color.black.opacity(0.15))
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(AppTheme.spacing40)
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                        .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.glassSubtleOpacity) : Color.white.opacity(AppTheme.cardDarkOpacity))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                        .fill(.ultraThinMaterial)
                }
            }
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
            
            Button(action: onPlanMeal) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Plan a Meal")
                        .fontWeight(.semibold)
                }
                .adaptiveForegroundColor()
                .padding(.horizontal, AppTheme.spacing24)
                .padding(.vertical, AppTheme.spacing14)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(AppTheme.overlayLightOpacity))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacing48)
    }
}
