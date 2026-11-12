import SwiftUI

/// Today's "Your cooking": streak weeks, cooks this week, and the next cooking badge with a progress bar.
/// Tapping opens the Cooking sheet (streak explained + every cooking badge). Frosted, no accent fill.
struct TodayProgressCard: View {
    let progress: TodayProgress
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Text("Your cooking")
                .font(.headline)
                .adaptiveForegroundColor()
                .accessibilityAddTraits(.isHeader)

            Button {
                HapticManager.shared.light()
                onOpen()
            } label: {
                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    HStack(spacing: AppTheme.spacing12) {
                        stat(
                            icon: "flame.fill", tint: .orange, value: "\(progress.streakWeeks)",
                            label: "week streak"
                        )
                        Divider().overlay(AppTheme.subtleStroke).frame(height: 36)
                        stat(
                            icon: "fork.knife", tint: .green, value: "\(progress.cooksThisWeek)",
                            label: progress.cooksThisWeek == 1 ? "cook this week" : "cooks this week"
                        )
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    if let next = progress.nextBadge {
                        Divider().overlay(AppTheme.subtleStroke)
                        badgeRow(next)
                    }
                }
                .padding(AppTheme.spacing16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .appCard()
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Shows your streak and cooking badges")
            .accessibilityIdentifier("today.progress")
        }
    }

    private func stat(icon: String, tint: Color, value: String, label: String) -> some View {
        HStack(spacing: AppTheme.spacing8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.title3.weight(.bold))
                    .adaptiveForegroundColor()
                Text(label)
                    .font(.caption)
                    .adaptiveSecondaryForeground()
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func badgeRow(_ next: TodayProgress.NextBadge) -> some View {
        let badge = next.type.badge
        let color = Badge.color(for: badge.color)
        return HStack(spacing: AppTheme.spacing12) {
            IconBadge(systemName: badge.icon, tint: color, diameter: 36, iconSize: AppTheme.fontSize16, style: .tinted)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(next.text)
                    .font(.subheadline.weight(.semibold))
                    .adaptiveForegroundColor()
                    .fixedSize(horizontal: false, vertical: true)
                ProgressView(value: Double(next.current), total: Double(next.target))
                    .tint(color)
                Text("\(next.current) / \(next.target)")
                    .font(.caption2)
                    .adaptiveSecondaryForeground()
            }
        }
    }

    private var accessibilityLabel: String {
        var parts = [
            "\(progress.streakWeeks) week streak",
            "\(progress.cooksThisWeek) \(progress.cooksThisWeek == 1 ? "cook" : "cooks") this week",
        ]
        if let next = progress.nextBadge {
            parts.append("\(next.text), \(next.current) of \(next.target)")
        }
        return parts.joined(separator: ". ")
    }
}

/// "Try something new": one recipe you've never cooked, the same all week. Tapping opens it.
struct TodayTryNewCard: View {
    let recipe: RecipeModel
    let onOpen: (RecipeModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Text("Try something new")
                .font(.headline)
                .adaptiveForegroundColor()
                .accessibilityAddTraits(.isHeader)

            Button { onOpen(recipe) } label: {
                HStack(spacing: AppTheme.spacing12) {
                    RecipeImageView(imageName: recipe.heroImageName, height: 72, recipeName: recipe.name)
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                        Text("This week's pick · not cooked yet")
                            .font(.caption.weight(.semibold))
                            .adaptiveSecondaryForeground()
                            .fixedSize(horizontal: false, vertical: true)
                        Text(recipe.name)
                            .font(.body.weight(.semibold))
                            .adaptiveForegroundColor()
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        if recipe.hasTotalTime {
                            Text(recipe.totalTime)
                                .font(.caption)
                                .adaptiveSecondaryForeground()
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .padding(AppTheme.spacing16)
                .contentShape(Rectangle())
                .appCard()
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("This week's pick, not cooked yet: \(recipe.name)")
            .accessibilityHint("Opens the recipe")
            .accessibilityIdentifier("today.tryNew")
        }
    }
}
