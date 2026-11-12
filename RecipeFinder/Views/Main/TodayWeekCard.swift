import SwiftUI

/// Today's "This week": seven day cells (a filled dot = something planned, a ring = nothing yet) and, when tomorrow
/// has no dinner, a "Plan tomorrow" row with a one-tap pick. Tapping an empty day plans its dinner; a planned day opens
/// the Plan tab. Lesser actions stay frosted so "Cook this" on the Tonight card keeps the one accent.
struct TodayWeekCard: View {
    let week: TodayWeek
    /// Opens the recipe picker for that day's dinner.
    let onPlanDay: (Date) -> Void
    /// Plans `recipe` for tomorrow's dinner.
    let onPlanTomorrow: (RecipeModel) -> Void
    let onOpenPlan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Text("This week")
                .font(.headline)
                .adaptiveForegroundColor()
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                HStack(spacing: 0) {
                    ForEach(Array(week.days.enumerated()), id: \.element.id) { index, day in
                        dayCell(day, index: index)
                    }
                }
                if let pick = week.planTomorrow, let tomorrow = week.days.dropFirst().first {
                    Divider().overlay(AppTheme.subtleStroke)
                    planTomorrowRow(pick, tomorrow: tomorrow.date)
                }
            }
            .padding(AppTheme.spacing16)
            .appCard()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today.week")
    }

    private func dayCell(_ day: TodayWeek.Day, index: Int) -> some View {
        Button {
            HapticManager.shared.light()
            if day.isPlanned { onOpenPlan() } else { onPlanDay(day.date) }
        } label: {
            VStack(spacing: AppTheme.spacing4) {
                Text(day.date.formatted(.dateTime.weekday(.narrow)))
                    .font(.caption2.weight(.medium))
                    .adaptiveSecondaryForeground()
                Text(day.date.formatted(.dateTime.day()))
                    .font(.subheadline.weight(day.isToday ? .bold : .regular))
                    .adaptiveForegroundColor()
                    .frame(width: 32, height: 32)
                    .overlay {
                        if day.isToday { Circle().stroke(AppTheme.accentColor, lineWidth: 1.5) }
                    }
                Group {
                    if day.isPlanned {
                        Circle().fill(Color.primary)
                    } else {
                        Circle().stroke(AppTheme.subtleStroke, lineWidth: 1)
                    }
                }
                .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(day))
        .accessibilityHint(day.isPlanned ? "Opens your plan" : "Plans dinner for this day")
        .accessibilityIdentifier("today.week.day.\(index)")
    }

    private func accessibilityLabel(_ day: TodayWeek.Day) -> String {
        let name = day.isToday ? "Today" : day.date.formatted(.dateTime.weekday(.wide).day())
        if let dinner = day.dinnerName { return "\(name), dinner: \(dinner)" }
        if day.isPlanned { return "\(name), \(day.mealTimes.map { $0.rawValue.lowercased() }.joined(separator: ", ")) planned" }
        return "\(name), nothing planned"
    }

    private func planTomorrowRow(_ pick: RecipeModel, tomorrow: Date) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppTheme.spacing12) {
                pickLabel(pick)
                Spacer(minLength: 0)
                planButtons(pick, tomorrow: tomorrow)
            }
            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                pickLabel(pick)
                HStack(spacing: AppTheme.spacing8) { planButtons(pick, tomorrow: tomorrow) }
            }
        }
    }

    private func pickLabel(_ pick: RecipeModel) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing2) {
            Text("Plan tomorrow")
                .font(.caption.weight(.semibold))
                .adaptiveSecondaryForeground()
            Text(pick.name)
                .font(.body.weight(.semibold))
                .adaptiveForegroundColor()
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Plan tomorrow: \(pick.name)")
        .accessibilityIdentifier("today.planTomorrow")
    }

    @ViewBuilder
    private func planButtons(_ pick: RecipeModel, tomorrow: Date) -> some View {
        PrimaryButton("Plan it", systemImage: "plus", size: .compact, variant: .secondary) {
            onPlanTomorrow(pick)
        }
        .accessibilityLabel("Plan \(pick.name) for tomorrow")
        .accessibilityIdentifier("today.planTomorrow.add")
        PrimaryButton("Choose", size: .compact, variant: .secondary) {
            onPlanDay(tomorrow)
        }
        .accessibilityLabel("Choose tomorrow's dinner")
        .accessibilityIdentifier("today.planTomorrow.choose")
    }
}
