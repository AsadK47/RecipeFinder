import SwiftUI

/// The weekly plan section of the meal planner. Extracted from `MealPlanningView`;
/// state mutation is delegated through closures so behavior is unchanged.
struct WeeklyPlanView: View {
    let days: [Date]
    let weekRangeString: String
    let weekHasPlannedMeals: Bool
    let weekShoppingFeedback: String?
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let selectedTheme: AppTheme.ThemeType
    let onPreviousWeek: () -> Void
    let onNextWeek: () -> Void
    let onAddMeal: (Date) -> Void
    let onAddWeekToShoppingList: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacing16) {
            HStack {
                Button(action: onPreviousWeek) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                        .adaptiveForegroundColor()
                        .frame(width: 40, height: AppTheme.height40)
                        .background(Circle().fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)))
                }
                
                Spacer()
                
                Text(weekRangeString)
                    .font(.system(size: AppTheme.fontSize18, weight: .bold))
                    .adaptiveForegroundColor()
                
                Spacer()
                
                Button(action: onNextWeek) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                        .adaptiveForegroundColor()
                        .frame(width: 40, height: AppTheme.height40)
                        .background(Circle().fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)))
                }
            }
            .padding(.horizontal, AppTheme.spacing4)
            
            VStack(spacing: AppTheme.spacing12) {
                ForEach(days, id: \.self) { date in
                    WeekDayRow(
                        date: date,
                        isToday: Calendar.current.isDateInToday(date),
                        cardStyle: cardStyle,
                        colorScheme: colorScheme,
                        onAddMeal: {
                            onAddMeal(date)
                        }
                    )
                }
            }

            if weekHasPlannedMeals {
                Button(action: onAddWeekToShoppingList) {
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "cart.badge.plus")
                        Text("Add Week to Shopping List")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .adaptiveForegroundColor()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacing12)
                    .background(AppTheme.accentColor(for: selectedTheme))
                    .cornerRadius(AppTheme.cornerRadius12)
                }
                .buttonStyle(PlainButtonStyle())

                if let weekShoppingFeedback {
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(weekShoppingFeedback)
                            .font(.caption)
                            .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(AppTheme.spacing24)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                    .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.glassSubtleOpacity) : Color.white.opacity(AppTheme.cardDarkOpacity))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}
