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
        .accessibilityHint(night.recipe == nil
                           ? "This recipe is no longer in your library. Use actions to move or remove it."
                           : "Opens the recipe. Use actions to cook or move it.")
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
        Button {
            HapticManager.shared.light()
            onPlan(night.date)
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .strokeBorder(AppTheme.subtleStroke, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    Image(systemName: night.isPast ? "moon.zzz" : "plus")
                        .font(.title2.weight(.semibold))
                        .adaptiveSecondaryForeground()
                }
                // A missed night is history, not a call to action: half height so the nights ahead lead.
                .frame(height: night.isPast ? photoHeight / 2 : photoHeight)
                dayLabel(night)
                Text(night.isPast ? "No dinner planned" : "Plan dinner")
                    .font(.subheadline)
                    .adaptiveSecondaryForeground()
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppTheme.spacing8)
            .frame(maxHeight: .infinity, alignment: .top)
            .appCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(night.isPast)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Self.spokenDay(night)), no dinner planned")
        .accessibilityHint(night.isPast ? "" : "Plans dinner for this night")
        .accessibilityAddTraits(.isButton)
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
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.spacing8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(AppTheme.accentColor))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
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
