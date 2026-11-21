import SwiftUI

/// Today's greeting with the streak chip (or a "Start a streak" nudge before the first cook).
struct TodayGreetingHeader: View {
    let greeting: String
    let streak: CookingStreak

    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.spacing12) {
            Text(greeting)
                .font(.title2.weight(.bold))
                .adaptiveForegroundColor()
            Spacer(minLength: 0)
            if streak.currentWeeks > 0 {
                StreakChip(streak: streak)
            } else {
                Label("Start a streak", systemImage: "flame")
                    .font(.footnote.weight(.semibold))
                    .adaptiveSecondaryForeground()
                    .padding(.horizontal, AppTheme.spacing10)
                    .padding(.vertical, AppTheme.spacing6)
                    .appCard(in: Capsule())
                    .accessibilityLabel("Start a streak: cook anything this week")
                    .accessibilityIdentifier("today.startStreak")
            }
        }
    }
}

/// New users' first card: bring in a recipe so Today has something of theirs to suggest.
struct TodayFirstRecipeCard: View {
    let onAddRecipe: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Bring in your first recipe")
                .font(.headline)
                .adaptiveForegroundColor()
            Text("Add one from a link, a photo, pasted text or your own notes, and Today starts suggesting what to cook.")
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton("Add a recipe", systemImage: "plus.circle.fill") {
                HapticManager.shared.light()
                onAddRecipe()
            }
            .accessibilityIdentifier("today.addFirstRecipe")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacing20)
        .appCard()
    }
}

/// A card that switches to another tab (e.g. "Plan tonight" when nothing is lined up).
struct TodayShortcutCard: View {
    let tab: AppTab
    let title: String
    let subtitle: String
    let color: Color
    let onOpen: (AppTab) -> Void

    var body: some View {
        Button {
            HapticManager.shared.light()
            onOpen(tab)
        } label: {
            HStack(spacing: AppTheme.spacing16) {
                IconBadge(systemName: tab.icon, tint: color, diameter: 44, iconSize: AppTheme.fontSize18, style: .tinted)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(AppTheme.spacing20)
            .appCard()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("today.open.\(tab.rawValue)")
    }
}

/// Under tonight's pick: when it doesn't appeal, one tap opens Recipes on Discover to keep looking (owner 2026-11-16,
/// option D — Today stays one pick; the endless feed lives on Recipes).
struct TodayKeepBrowsingRow: View {
    /// "Not feeling it?" under a pick; with no pick to turn down, an invitation instead.
    var lead = "Not feeling it?"
    let onBrowse: () -> Void

    var body: some View {
        Button(action: onBrowse) {
            // One Text, so large type wraps as a sentence with the arrow at its end.
            (Text("\(lead) ").foregroundStyle(.secondary)
                + Text("Keep browsing \(Image(systemName: "arrow.right"))").fontWeight(.semibold))
                .font(.subheadline)
                .adaptiveForegroundColor()
                .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.spacing4)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(lead) Keep browsing")
        .accessibilityHint("Opens Discover in Recipes")
        .accessibilityIdentifier("today.keepBrowsing")
    }
}

/// "Plan the week" under Tonight (owner 2026-11-20: the swipe deck should be reachable from home). Shown while a night
/// in the coming seven has no dinner; opens Plan my week's deck on Plan.
struct TodayPlanWeekRow: View {
    let onPlan: () -> Void

    var body: some View {
        Button(action: onPlan) {
            HStack(spacing: AppTheme.spacing8) {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundStyle(AppTheme.accentColor)
                    .accessibilityHidden(true)
                (Text("Plan the week").fontWeight(.semibold)
                    + Text(" · swipe to pick dinners \(Image(systemName: "arrow.right"))").foregroundStyle(.secondary))
                    .font(.subheadline)
                    .adaptiveForegroundColor()
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.spacing4)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Plan the week, swipe to pick dinners")
        .accessibilityHint("Opens Plan my week")
        .accessibilityIdentifier("today.planWeek")
    }
}
