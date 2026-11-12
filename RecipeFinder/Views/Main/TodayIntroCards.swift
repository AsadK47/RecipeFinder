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
