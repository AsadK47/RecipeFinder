import SwiftUI

/// Plan's week as seven dinner photos. Tap a planned night to open its recipe; hold it to cook it, move it to another
/// night (swapping with that night's dinner) or take it off. Tap an empty night from tonight on to plan its dinner.
struct WeekDinnersView: View {
    let nights: [WeekDinners.Night]
    /// Opens the recipe page (owner 2026-11-20: a tap is not a decision to cook now).
    let onOpen: (RecipeModel) -> Void
    let onCook: (RecipeModel) -> Void
    let onPlan: (Date) -> Void
    let onMove: (MealPlanModel, Date) -> Void
    let onRemove: (MealPlanModel) -> Void

    @ScaledMetric(relativeTo: .body) private var photoHeight: CGFloat = 96

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("This week's dinners")
                .font(.system(size: AppTheme.fontSize20, weight: .bold))
                .adaptiveForegroundColor()
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, AppTheme.spacing4)

            // Not lazy: seven tiles, and every night should be in the tree for VoiceOver and UI tests.
            Grid(horizontalSpacing: AppTheme.spacing12, verticalSpacing: AppTheme.spacing12) {
                ForEach(Array(stride(from: 0, to: nights.count, by: 2)), id: \.self) { start in
                    GridRow {
                        cell(start)
                        if start + 1 < nights.count { cell(start + 1) } else { Color.clear }
                    }
                }
            }
        }
    }

    private func cell(_ index: Int) -> some View {
        tile(nights[index])
            // A past night is dimmed whole (owner 2026-11-20); it holds a dinner only if it was cooked.
            .opacity(nights[index].isPast ? 0.55 : 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("plan.dinner.\(index)")
    }

    @ViewBuilder
    private func tile(_ night: WeekDinners.Night) -> some View {
        if let plan = night.plan {
            plannedTile(night, plan: plan)
        } else {
            emptyTile(night)
        }
    }

    private func plannedTile(_ night: WeekDinners.Night, plan: MealPlanModel) -> some View {
        Button {
            guard let recipe = night.recipe else { return }
            HapticManager.shared.light()
            onOpen(recipe)
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                photo(night, plan: plan)
                dayLabel(night)
                Text(plan.recipeName)
                    .font(.subheadline.weight(.semibold))
                    .adaptiveForegroundColor()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppTheme.spacing8)
            .frame(maxHeight: .infinity, alignment: .top)
            .appCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu { moveMenu(night, plan: plan) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Self.spokenDay(night)), dinner: \(plan.recipeName)")
        .accessibilityHint(Self.dinnerHint(night, in: nights))
        .accessibilityAddTraits(night.recipe == nil ? [] : .isButton)
        .accessibilityActions { moveMenu(night, plan: plan) }
    }

    @ViewBuilder
    private func photo(_ night: WeekDinners.Night, plan: MealPlanModel) -> some View {
        Group {
            if let recipe = night.recipe {
                RecipeImageView(recipe: recipe, imageName: recipe.heroImageName, height: photoHeight)
            } else {
                RecipeImageView(imageName: nil, height: photoHeight, recipeName: plan.recipeName)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: photoHeight)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
    }

    @ViewBuilder
    private func moveMenu(_ night: WeekDinners.Night, plan: MealPlanModel) -> some View {
        if let recipe = night.recipe {
            Button { onCook(recipe) } label: { Label("Cook", systemImage: "frying.pan") }
        }
        ForEach(WeekDinners.moveTargets(from: night, in: nights)) { target in
            Button { onMove(plan, target.date) } label: {
                Label(Self.moveTitle(to: target), systemImage: target.plan == nil ? "arrow.right" : "arrow.left.arrow.right")
            }
        }
        if plan.isRecurring {
            // Moving one copy of a weekly dinner would be refilled from the series (see WeekDinners); taking it off
            // stops the series (MealPlanningManager), so that's allowed.
            Text("Repeats every \(plan.date.formatted(.dateTime.weekday(.wide)))")
            Button(role: .destructive) { onRemove(plan) } label: {
                Label("Take off and stop repeating", systemImage: "trash")
            }
        } else {
            Button(role: .destructive) { onRemove(plan) } label: { Label("Take off the plan", systemImage: "trash") }
        }
    }

    private func emptyTile(_ night: WeekDinners.Night) -> some View {
        WeekDinnerEmptyTile(night: night, spokenDay: Self.spokenDay(night), dayLabel: dayLabel(night), onPlan: onPlan)
    }

    private func dayLabel(_ night: WeekDinners.Night) -> some View {
        HStack(spacing: AppTheme.spacing4) {
            Text(night.date.formatted(.dateTime.weekday(.abbreviated).day()))
                .font(.caption.weight(.semibold))
                .adaptiveSecondaryForeground()
            if night.isPast, night.plan != nil {
                // Plan shows a past night's dinner only once cooked (MealPlanModel.isShown).
                Label("Cooked", systemImage: "checkmark.circle.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.accentColor)
                    .labelStyle(.titleAndIcon)
            }
            if night.isToday {
                Text("Tonight")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppTheme.onAccent)
                    .padding(.horizontal, AppTheme.spacing8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(AppTheme.accentColor))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    /// VoiceOver hint naming every action the hold menu (`moveMenu`) offers for this night, so it can't promise a
    /// move `WeekDinners.moveTargets` withholds (past nights, repeating dinners, no other night ahead).
    nonisolated static func dinnerHint(_ night: WeekDinners.Night, in nights: [WeekDinners.Night]) -> String {
        var actions: [String] = []
        if night.recipe != nil { actions.append(night.isPast ? "cook it again" : "cook it") }
        if !WeekDinners.moveTargets(from: night, in: nights).isEmpty { actions.append("move it") }
        actions.append(night.plan?.isRecurring == true ? "take it off and stop it repeating" : "take it off the plan")
        let opens = night.recipe == nil ? "This recipe is no longer in your library." : "Opens the recipe."
        // Joined by hand, not ListFormatStyle: the hint is British English whatever the device region (no Oxford comma).
        let list = actions.count > 1
            ? actions.dropLast().joined(separator: ", ") + " or " + (actions.last ?? "")
            : actions.joined()
        return "\(opens) Use actions to \(list)."
    }

    private static func spokenDay(_ night: WeekDinners.Night) -> String {
        night.isToday ? "Tonight" : night.date.formatted(.dateTime.weekday(.wide).day())
    }

    private static func moveTitle(to target: WeekDinners.Night) -> String {
        let day = target.isToday ? "tonight" : target.date.formatted(.dateTime.weekday(.wide))
        guard let other = target.plan else { return "Move to \(day)" }
        return "Swap with \(day) (\(other.recipeName))"
    }
}
