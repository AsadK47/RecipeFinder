import SwiftUI

/// "Planned Meals" list for the selected day; drag the ≡ handle (right of each card, outside the boundary to avoid clipping) to reorder within the day.
struct PlannedMealsSection: View {
    @Binding var mealTimes: [MealTime]
    let selectedDateString: String
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let selectedTheme: AppTheme.ThemeType
    let recipeFor: (MealTime) -> RecipeModel?
    let mealPlanFor: (MealTime) -> MealPlanModel?
    let onSelectMealTime: (MealTime) -> Void
    let onRemove: (MealTime) -> Void
    let onToggleRecurring: (MealTime) -> Void
    let onAddAnother: () -> Void

    @State private var dropTarget: MealTime?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack {
                Text("Planned Meals")
                    .font(.system(size: AppTheme.fontSize20, weight: .bold))
                    .adaptiveForegroundColor()

                Spacer()

                Text(selectedDateString)
                    .font(.subheadline)
                    .foregroundStyle(colorScheme == .dark
                        ? .white.opacity(AppTheme.subduedEmphasisOpacity)
                        : .black.opacity(AppTheme.subduedEmphasisOpacity))
            }
            .padding(.horizontal, AppTheme.spacing4)

            VStack(spacing: AppTheme.spacing12) {
                ForEach(mealTimes, id: \.self) { mealTime in
                    mealRow(for: mealTime)
                }
            }

            addAnotherButton
        }
    }

    @ViewBuilder
    private func mealRow(for mealTime: MealTime) -> some View {
        HStack(spacing: AppTheme.spacing8) {
            Button(action: { onSelectMealTime(mealTime) }) {
                MealTimeCard(
                    mealTime: mealTime,
                    recipe: recipeFor(mealTime),
                    isRecurring: mealPlanFor(mealTime)?.isRecurring ?? false,
                    cardStyle: cardStyle,
                    colorScheme: colorScheme,
                    onRemove: { onRemove(mealTime) }
                )
            }
            .buttonStyle(.plain)
            .contextMenu {
                if recipeFor(mealTime) != nil {
                    let recurring = mealPlanFor(mealTime)?.isRecurring ?? false
                    Button(
                        recurring ? "Stop Repeating" : "Repeat Weekly",
                        systemImage: recurring ? "repeat.1" : "repeat"
                    ) {
                        onToggleRecurring(mealTime)
                    }
                }
            }

            // Only the ≡ handle initiates the drag; tapping the card still changes the recipe.
            Image(systemName: "line.3.horizontal")
                .font(.system(size: AppTheme.fontSize16))
                .foregroundStyle(colorScheme == .dark
                    ? .white.opacity(AppTheme.lowEmphasisOpacity)
                    : .black.opacity(AppTheme.lowEmphasisOpacity))
                .frame(width: 28, height: 52)
                .contentShape(Rectangle())
                .draggable(mealTime.rawValue) {
                    MealTimeCard(
                        mealTime: mealTime,
                        recipe: recipeFor(mealTime),
                        isRecurring: mealPlanFor(mealTime)?.isRecurring ?? false,
                        cardStyle: cardStyle,
                        colorScheme: colorScheme,
                        onRemove: {}
                    )
                    .frame(width: 260)
                }
        }
        .overlay(alignment: .top) {
            if dropTarget == mealTime {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .stroke(AppTheme.accentColor(for: selectedTheme), lineWidth: 2)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: dropTarget)
        // .draggable/.dropDestination manage drag+cancel state, so there's no manual flag to get stuck (the old greyed-out bug).
        .dropDestination(for: String.self) { items, _ in
            guard let raw = items.first, let from = MealTime(rawValue: raw) else { return false }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                mealTimes = MealTimeReorder.moved(mealTimes, moving: from, to: mealTime)
            }
            return true
        } isTargeted: { targeted in
            dropTarget = targeted ? mealTime : (dropTarget == mealTime ? nil : dropTarget)
        }
    }

    private var addAnotherButton: some View {
        Button(action: onAddAnother) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accentColor(for: selectedTheme))

                Text("Add Another Meal")
                    .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                    .adaptiveForegroundColor()

                Spacer()
            }
            .padding(AppTheme.spacing16)
            .appCard()
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [5]))
            )
        }
    }
}

/// Pure reorder for the planner's drag-to-reorder; extracted so it's unit-testable.
enum MealTimeReorder {
    static func moved(_ items: [MealTime], moving from: MealTime, to target: MealTime) -> [MealTime] {
        guard from != target,
              let fromIndex = items.firstIndex(of: from),
              let toIndex = items.firstIndex(of: target) else { return items }
        var result = items
        result.move(fromOffsets: IndexSet(integer: fromIndex),
                    toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        return result
    }
}
