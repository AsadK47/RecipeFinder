import SwiftUI

/// The month calendar grid section of the meal planner. Extracted from
/// `MealPlanningView` to keep that view an orchestrator; all state mutation is
/// delegated back through closures so behavior (including haptics) is unchanged.
struct MonthCalendarView: View {
    let selectedDate: Date
    let days: [Date?]
    let monthYearString: String
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let selectedTheme: AppTheme.ThemeType
    let hasPlannedMeals: (Date) -> Bool
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    let onShowMonthPicker: () -> Void
    let onSelectDay: (Date) -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacing16) {
            HStack {
                Button(action: onPreviousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                        .adaptiveForegroundColor()
                        .frame(width: 40, height: AppTheme.height40)
                        .background(Circle().fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)))
                }
                
                Spacer()
                
                Button(action: onShowMonthPicker) {
                    HStack(spacing: AppTheme.spacing6) {
                        Text(monthYearString)
                            .font(.system(size: AppTheme.fontSize22, weight: .bold))
                            .adaptiveForegroundColor()
                        
                        Image(systemName: "calendar.circle")
                            .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                            .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: onNextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                        .adaptiveForegroundColor()
                        .frame(width: 40, height: AppTheme.height40)
                        .background(Circle().fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(AppTheme.dividerOpacity)))
                }
            }
            .padding(.horizontal, AppTheme.spacing4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.spacing4), count: 7), spacing: AppTheme.spacing8) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: AppTheme.fontSize12, weight: .semibold))
                        .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                        .frame(maxWidth: .infinity)
                }
                
                ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            hasPlannedMeals: hasPlannedMeals(date),
                            cardStyle: cardStyle,
                            colorScheme: colorScheme
                        )
                        .onTapGesture {
                            onSelectDay(date)
                        }
                    } else {
                        Color.clear
                            .frame(height: AppTheme.height50)
                    }
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
