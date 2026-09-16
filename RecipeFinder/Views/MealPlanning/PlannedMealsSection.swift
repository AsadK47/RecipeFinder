import SwiftUI

/// The "Planned Meals" list shown for the selected day. Extracted from
/// `MealPlanningView`; state mutation is delegated through closures.
/// Supports drag-to-reorder: the user long-presses the grab handle (≡) on any
/// card to drag it to a new position within the day.
struct PlannedMealsSection: View {
    @Binding var mealTimes: [MealTime]
    let selectedDateString: String
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let selectedTheme: AppTheme.ThemeType
    let recipeFor: (MealTime) -> RecipeModel?
    let onSelectMealTime: (MealTime) -> Void
    let onRemove: (MealTime) -> Void
    let onAddAnother: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack {
                Text("Planned Meals")
                    .font(.system(size: AppTheme.fontSize20, weight: .bold))
                    .adaptiveForegroundColor()

                Spacer()

                Text(selectedDateString)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark
                        ? .white.opacity(AppTheme.subduedEmphasisOpacity)
                        : .black.opacity(AppTheme.subduedEmphasisOpacity))
            }
            .padding(.horizontal, AppTheme.spacing4)

            // List gives us .onMove for free; scrollDisabled keeps the outer
            // ScrollView in control and auto-sizes the List to its content.
            List {
                ForEach(mealTimes, id: \.self) { mealTime in
                    Button(action: { onSelectMealTime(mealTime) }) {
                        MealTimeCard(
                            mealTime: mealTime,
                            recipe: recipeFor(mealTime),
                            cardStyle: cardStyle,
                            colorScheme: colorScheme,
                            onRemove: { onRemove(mealTime) }
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: AppTheme.spacing12, trailing: 0))
                }
                .onMove { from, to in
                    mealTimes.move(fromOffsets: from, toOffset: to)
                    HapticManager.shared.selection()
                }
            }
            .listStyle(.plain)
            .scrollDisabled(true)
            .environment(\.editMode, .constant(.active))
            // Approximate height: card ~84 pt + 12 pt row spacing, capped at 4 items.
            .frame(height: CGFloat(mealTimes.count) * (AppTheme.buttonHeightLarge + 44))

            Button(action: onAddAnother) {
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))

                    Text("Add Another Meal")
                        .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                        .adaptiveForegroundColor()

                    Spacer()
                }
                .padding(AppTheme.spacing16)
                .background {
                    if cardStyle == .solid {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                            .fill(colorScheme == .dark
                                ? Color.white.opacity(AppTheme.glassSubtleOpacity)
                                : Color.white.opacity(AppTheme.cardDarkOpacity))
                    } else {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                            .fill(.ultraThinMaterial)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                        .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
            }
        }
    }
}
