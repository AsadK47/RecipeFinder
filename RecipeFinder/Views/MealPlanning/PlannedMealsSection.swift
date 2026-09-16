import SwiftUI

/// The "Planned Meals" list shown for the selected day.
/// Drag-to-reorder: drag the ≡ handle (to the right of each card) to reorder within the day.
/// The handle lives outside the card boundary so it renders cleanly without clipping.
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

    @State private var dragging: MealTime?

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
                    cardStyle: cardStyle,
                    colorScheme: colorScheme,
                    onRemove: { onRemove(mealTime) }
                )
            }
            .buttonStyle(.plain)

            // ≡ grip handle lives outside the card so it never clips against the card boundary.
            // Only this handle initiates the drag — tapping the card still changes the recipe.
            Image(systemName: "line.3.horizontal")
                .font(.system(size: AppTheme.fontSize16))
                .foregroundColor(colorScheme == .dark
                    ? .white.opacity(AppTheme.lowEmphasisOpacity)
                    : .black.opacity(AppTheme.lowEmphasisOpacity))
                .frame(width: 28, height: 52)
                .contentShape(Rectangle())
                .onDrag {
                    dragging = mealTime
                    return NSItemProvider(object: mealTime.rawValue as NSString)
                }
        }
        .opacity(dragging == mealTime ? 0.4 : 1)
        .animation(.easeInOut(duration: 0.2), value: dragging)
        .onDrop(
            of: [.text],
            delegate: MealTimeDropDelegate(item: mealTime, items: $mealTimes, dragging: $dragging)
        )
    }

    private var addAnotherButton: some View {
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

private struct MealTimeDropDelegate: DropDelegate {
    let item: MealTime
    @Binding var items: [MealTime]
    @Binding var dragging: MealTime?

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let current = dragging, current != item else { return }
        guard let from = items.firstIndex(of: current),
              let to = items.firstIndex(of: item) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
