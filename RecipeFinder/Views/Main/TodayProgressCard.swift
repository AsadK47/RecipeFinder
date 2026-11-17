import SwiftUI

/// Today's "Your cooking": streak weeks and cooks this week (tap → the Cooking sheet: streak explained + every cooking
/// badge), then the next cooking badge with a progress bar (tap → Me's trophy shelf, opened on that badge's card).
/// Frosted, no accent fill.
struct TodayProgressCard: View {
    let progress: TodayProgress
    let onOpen: () -> Void
    let onOpenBadges: (TrophyShelfRequest) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Text("Your cooking")
                .font(.headline)
                .adaptiveForegroundColor()
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 0) {
                Button {
                    HapticManager.shared.light()
                    onOpen()
                } label: {
                    statsRow
                        .padding(AppTheme.spacing16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(statsAccessibilityLabel)
                .accessibilityHint("Shows your streak and cooking badges")
                .accessibilityIdentifier("today.progress")

                Divider().overlay(AppTheme.subtleStroke)
                    .padding(.horizontal, AppTheme.spacing16)

                Button {
                    HapticManager.shared.light()
                    onOpenBadges(progress.badgeShelfRequest)
                } label: {
                    badgeRow
                        .padding(AppTheme.spacing16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(progress.badgeRowSpokenText)
                .accessibilityHint(progress.nextBadge == nil ? "Opens your badges" : "Opens this badge on your shelf")
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("today.progress.badges")
            }
            .appCard()
        }
    }

    private var statsRow: some View {
        HStack(spacing: AppTheme.spacing12) {
            stat(icon: "flame.fill", tint: .orange, value: "\(progress.streakWeeks)", label: "week streak")
            Divider().overlay(AppTheme.subtleStroke).frame(height: 36)
            stat(
                icon: "fork.knife", tint: .green, value: "\(progress.cooksThisWeek)",
                label: progress.cooksThisWeek == 1 ? "cook this week" : "cooks this week"
            )
            Spacer(minLength: 0)
            chevron
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
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

    /// The next badge with its bar; once every cooking badge is earned, a trophy and the all-earned line.
    private var badgeRow: some View {
        let badge = progress.nextBadge?.type.badge
        let color = badge.map { Badge.color(for: $0.color) } ?? .yellow
        return HStack(spacing: AppTheme.spacing12) {
            IconBadge(
                systemName: badge?.icon ?? "trophy.fill", tint: color, diameter: 36,
                iconSize: AppTheme.fontSize16, style: .tinted
            )
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(progress.badgeRowText)
                    .font(.subheadline.weight(.semibold))
                    .adaptiveForegroundColor()
                    .fixedSize(horizontal: false, vertical: true)
                if let next = progress.nextBadge {
                    ProgressView(value: Double(next.current), total: Double(next.target))
                        .tint(color)
                    Text("\(next.current) / \(next.target)")
                        .font(.caption2)
                        .adaptiveSecondaryForeground()
                } else {
                    Text("See your badges")
                        .font(.caption)
                        .adaptiveSecondaryForeground()
                }
            }
            Spacer(minLength: 0)
            chevron
        }
    }

    private var statsAccessibilityLabel: String {
        "\(progress.streakWeeks) week streak. "
            + "\(progress.cooksThisWeek) \(progress.cooksThisWeek == 1 ? "cook" : "cooks") this week"
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
                    RecipeImageView(recipe: recipe, imageName: recipe.heroImageName, height: 72)
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
