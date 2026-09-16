import SwiftUI

/// Compact 7-day week strip that replaces the full-month calendar grid.
/// Tapping a day selects it; the parent shows that day's planned meals below.
/// Prev/next arrow buttons advance by one week.
struct WeekStripView: View {
    let week: [Date]
    let selectedDate: Date
    let monthYearString: String
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let selectedTheme: AppTheme.ThemeType
    /// Returns the planned meal times for a given date, used to draw indicator dots.
    let mealTimesFor: (Date) -> [MealTime]
    let onSelectDate: (Date) -> Void
    let onPreviousWeek: () -> Void
    let onNextWeek: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacing16) {
            weekHeader
            dayStrip
        }
        .padding(AppTheme.spacing20)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(AppTheme.glassSubtleOpacity)
                        : Color.white.opacity(AppTheme.cardDarkOpacity))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius20)
                    .fill(.ultraThinMaterial)
            }
        }
    }

    private var weekHeader: some View {
        HStack {
            Button(action: onPreviousWeek) {
                Image(systemName: "chevron.left")
                    .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                    .adaptiveForegroundColor()
                    .frame(width: AppTheme.height40, height: AppTheme.height40)
                    .background(Circle().fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.1)
                            : Color.black.opacity(AppTheme.dividerOpacity)
                    ))
            }

            Spacer()

            Text(monthYearString)
                .font(.system(size: AppTheme.fontSize18, weight: .bold))
                .adaptiveForegroundColor()

            Spacer()

            Button(action: onNextWeek) {
                Image(systemName: "chevron.right")
                    .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                    .adaptiveForegroundColor()
                    .frame(width: AppTheme.height40, height: AppTheme.height40)
                    .background(Circle().fill(
                        colorScheme == .dark
                            ? Color.white.opacity(0.1)
                            : Color.black.opacity(AppTheme.dividerOpacity)
                    ))
            }
        }
    }

    private var dayStrip: some View {
        HStack(spacing: 0) {
            ForEach(week, id: \.self) { date in
                WeekDayCell(
                    date: date,
                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                    isToday: Calendar.current.isDateInToday(date),
                    mealTimes: mealTimesFor(date),
                    selectedTheme: selectedTheme,
                    colorScheme: colorScheme,
                    onTap: { onSelectDate(date) }
                )
            }
        }
    }
}

private struct WeekDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let mealTimes: [MealTime]
    let selectedTheme: AppTheme.ThemeType
    let colorScheme: ColorScheme
    let onTap: () -> Void

    private var dayLetter: String {
        let weekday = Calendar.current.component(.weekday, from: date)
        return ["S", "M", "T", "W", "T", "F", "S"][weekday - 1]
    }

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    private func dotColor(for mealTime: MealTime) -> Color {
        switch mealTime {
        case .breakfast: return .orange
        case .lunch:     return Color(red: 0.95, green: 0.77, blue: 0.06)
        case .dinner:    return .indigo
        case .snack:     return .purple
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppTheme.spacing4) {
                Text(dayLetter)
                    .font(.system(size: AppTheme.fontSize11, weight: .medium))
                    .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))

                ZStack {
                    if isSelected {
                        Circle()
                            .fill(AppTheme.accentColor(for: selectedTheme))
                    } else if isToday {
                        Circle()
                            .stroke(AppTheme.accentColor(for: selectedTheme), lineWidth: 1.5)
                    }
                    Text(dayNumber)
                        .font(.system(size: AppTheme.fontSize14, weight: isSelected || isToday ? .bold : .regular))
                        .foregroundColor(
                            isSelected ? .white
                            : isToday ? AppTheme.accentColor(for: selectedTheme)
                            : AppTheme.adaptiveEmphasis(for: colorScheme)
                        )
                }
                .frame(width: 32, height: 32)

                // One dot per planned meal time, up to 4
                HStack(spacing: 2) {
                    ForEach(Array(mealTimes.prefix(3).enumerated()), id: \.offset) { _, mt in
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.9) : dotColor(for: mt))
                            .frame(width: 4, height: 4)
                    }
                    if mealTimes.count > 3 {
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.9) : Color.secondary)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
