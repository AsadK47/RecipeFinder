import SwiftUI

/// Today's one-line day strip: the next meal's day beside the hero (`TodayDayStrip.meals(beside:)` picks which meals).
/// An open meal plans it; a planned or cooked one opens its recipe. Wraps to a column at large text sizes.
struct TodayDayStripCard: View {
    let strip: TodayDayStrip
    /// The meals to show — never empty (Today hides the card instead).
    let meals: [TodayDayStrip.Meal]
    let onPlan: (MealTime) -> Void
    let onOpen: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            if strip.isTomorrow {
                Text("Tomorrow")
                    .font(.caption.weight(.semibold))
                    .adaptiveSecondaryForeground()
                    .accessibilityHidden(true)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppTheme.spacing8) { mealButtons }
                VStack(alignment: .leading, spacing: AppTheme.spacing8) { mealButtons }
            }
        }
        .padding(AppTheme.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today.day")
    }

    private var mealButtons: some View {
        ForEach(meals) { meal in
            Button { tapped(meal) } label: {
                Label(meal.text, systemImage: icon(meal))
                    .font(.subheadline.weight(meal.isNext ? .semibold : .regular))
                    .adaptiveForegroundColor()
                    .lineLimit(1)
                    .padding(.horizontal, AppTheme.spacing10)
                    .padding(.vertical, AppTheme.spacing6)
                    .background(Capsule().fill(meal.isNext ? AppTheme.subtleFill : Color.clear))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(strip.isTomorrow ? "Tomorrow's \(meal.spokenText)" : meal.spokenText)
            .accessibilityHint(hint(meal))
            .accessibilityIdentifier("today.day.\(meal.time.rawValue.lowercased())")
        }
    }

    private func tapped(_ meal: TodayDayStrip.Meal) {
        switch meal.state {
        case .open: onPlan(meal.time)
        case .planned, .done: if let id = meal.recipeID { onOpen(id) }
        }
    }

    private func icon(_ meal: TodayDayStrip.Meal) -> String {
        switch meal.state {
        // The text already ends in ✓.
        case .done, .planned: meal.time.icon
        case .open: "plus.circle"
        }
    }

    private func hint(_ meal: TodayDayStrip.Meal) -> String {
        switch meal.state {
        case .open: "Picks a recipe for \(meal.time.rawValue.lowercased())"
        case .planned, .done: "Opens the recipe"
        }
    }
}
