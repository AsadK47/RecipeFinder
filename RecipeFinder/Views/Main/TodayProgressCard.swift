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

                if let next = progress.nextBadge, let request = progress.badgeShelfRequest {
                    Divider().overlay(AppTheme.subtleStroke)
                        .padding(.horizontal, AppTheme.spacing16)

                    Button {
                        HapticManager.shared.light()
                        onOpenBadges(request)
                    } label: {
                        badgeRow(next)
                            .padding(AppTheme.spacing16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(next.spokenText)
                    .accessibilityHint("Opens this badge on your shelf")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("today.progress.badges")
                }
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
            Spacer(minLength: 0)
            chevron
        }
    }

    private var statsAccessibilityLabel: String {
        "\(progress.streakWeeks) week streak. "
            + "\(progress.cooksThisWeek) \(progress.cooksThisWeek == 1 ? "cook" : "cooks") this week"
    }
}
