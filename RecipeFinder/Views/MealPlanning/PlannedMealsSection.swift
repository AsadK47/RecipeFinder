import SwiftUI

/// "Planned Meals" list for the selected day; drag the ≡ handle (right of each card, outside the boundary to avoid clipping) to reorder within the day.
struct PlannedMealsSection: View {
    @Binding var mealTimes: [MealTime]
    let selectedDateString: String
    let recipeFor: (MealTime) -> RecipeModel?
    let mealPlanFor: (MealTime) -> MealPlanModel?
    let onSelectMealTime: (MealTime) -> Void
    let onRemove: (MealTime) -> Void
    let onToggleRecurring: (MealTime) -> Void
    let onEditReminder: (MealTime) -> Void
    let onRemoveReminder: (MealTime) -> Void
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
                    .foregroundStyle(AppTheme.textColor(opacity: AppTheme.subduedEmphasisOpacity))
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

    private func hasReminder(_ mealTime: MealTime) -> Bool {
        mealPlanFor(mealTime)?.reminderTime != nil
    }

    @ViewBuilder
    private func mealRow(for mealTime: MealTime) -> some View {
        HStack(spacing: AppTheme.spacing8) {
            Button(action: { onSelectMealTime(mealTime) }) {
                MealTimeCard(
                    mealTime: mealTime,
                    recipe: recipeFor(mealTime),
                    plannedName: mealPlanFor(mealTime)?.recipeName,
                    isRecurring: mealPlanFor(mealTime)?.isRecurring ?? false
                )
            }
            .buttonStyle(.plain)
            // On the card only: the ≡ handle beside it keeps its drag for reordering.
            .modifier(SwipeToRemove(isEnabled: mealPlanFor(mealTime) != nil) { onRemove(mealTime) })
            .contextMenu {
                // Every planned meal, even one whose recipe is gone, can stop repeating and have its reminder changed.
                if mealPlanFor(mealTime) != nil {
                    let recurring = mealPlanFor(mealTime)?.isRecurring ?? false
                    Button(
                        recurring ? "Stop Repeating" : "Repeat Weekly",
                        systemImage: recurring ? "repeat.1" : "repeat"
                    ) {
                        onToggleRecurring(mealTime)
                    }

                    if hasReminder(mealTime) {
                        Button("Edit Reminder", systemImage: "bell") { onEditReminder(mealTime) }
                        Button("Remove Reminder", systemImage: "bell.slash", role: .destructive) {
                            onRemoveReminder(mealTime)
                        }
                    } else {
                        Button("Remind Me…", systemImage: "bell") { onEditReminder(mealTime) }
                    }
                }
            }

            // Beside the card, not inside its button: a tap on the bin must never also open the recipe picker.
            if mealPlanFor(mealTime) != nil {
                Button { onRemove(mealTime) } label: {
                    Image(systemName: "trash")
                        .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                        .foregroundStyle(AppTheme.error.opacity(0.7))
                        .frame(width: 32, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Take \(mealTime.rawValue.lowercased()) off the plan")
                .accessibilityIdentifier("plan.meal.\(mealTime.rawValue).remove")
            }

            if hasReminder(mealTime) {
                Image(systemName: "bell.fill")
                    .font(.system(size: AppTheme.fontSize12))
                    .foregroundStyle(AppTheme.accentColor)
                    .accessibilityLabel("Reminder set")
            }

            // Only the ≡ handle initiates the drag; tapping the card still changes the recipe.
            Image(systemName: "line.3.horizontal")
                .font(.system(size: AppTheme.fontSize16))
                .foregroundStyle(AppTheme.textColor(opacity: AppTheme.lowEmphasisOpacity))
                .frame(width: 28, height: 52)
                .contentShape(Rectangle())
                .draggable(mealTime.rawValue) {
                    MealTimeCard(
                        mealTime: mealTime,
                        recipe: recipeFor(mealTime),
                        plannedName: mealPlanFor(mealTime)?.recipeName,
                        isRecurring: mealPlanFor(mealTime)?.isRecurring ?? false
                    )
                    .frame(width: 260)
                }
        }
        .overlay(alignment: .top) {
            if dropTarget == mealTime {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .stroke(AppTheme.accentColor, lineWidth: 2)
            }
        }
        .accessibilityIdentifier("plan.meal.\(mealTime.rawValue)")
        .animation(.easeInOut(duration: 0.2), value: dropTarget)
        // .draggable/.dropDestination manage drag+cancel state, so there's no manual flag to get stuck (the old greyed-out bug).
        .dropDestination(for: String.self) { items, _ in
            guard let raw = items.first, let from = MealTime(rawValue: raw) else { return false }
            withAnimation(.appSpring) {
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
                    .foregroundStyle(AppTheme.accentColor)

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

/// Swipe a planned meal left to take it off (owner 2026-11-20). The day list isn't a `List` (drag-to-reorder handle,
/// frosted cards), so `swipeActions` isn't available: a horizontal drag slides the row, past `threshold` it's removed.
/// Simultaneous, and only horizontal drags move the row, so the page still scrolls. The trash button stays for VoiceOver.
private struct SwipeToRemove: ViewModifier {
    let isEnabled: Bool
    let onRemove: () -> Void

    /// Resets by itself when the drag ends or is cancelled (e.g. the reorder handle takes over), so a row can't stick
    /// half-open.
    @GestureState private var offset: CGFloat = 0
    private let threshold: CGFloat = 120

    private static func isHorizontal(_ translation: CGSize) -> Bool {
        abs(translation.width) > abs(translation.height) * 1.5
    }

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .animation(.appGentle, value: offset)
            .background(alignment: .trailing) {
                if offset < 0 {
                    Label("Remove", systemImage: "trash")
                        .labelStyle(.iconOnly)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: max(-offset, 0), alignment: .center)
                        .frame(maxHeight: .infinity)
                        .background(RoundedRectangle(cornerRadius: AppTheme.cornerRadius16).fill(AppTheme.destructiveFill))
                        .opacity(min(-offset / threshold, 1))
                        .accessibilityHidden(true)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .updating($offset) { value, state, _ in
                        guard isEnabled, Self.isHorizontal(value.translation) else { return }
                        state = min(0, value.translation.width)
                    }
                    .onEnded { value in
                        guard isEnabled, value.translation.width < -threshold, Self.isHorizontal(value.translation)
                        else { return }
                        HapticManager.shared.medium()
                        onRemove()
                    }
            )
    }
}
