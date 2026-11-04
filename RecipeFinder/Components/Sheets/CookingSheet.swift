import SwiftUI

/// Opened from the Recipes-header streak chip — the home of the cooking reward loop. Explains the weekly
/// streak in plain language (so the flame isn't a mystery) and shows progress toward every cooking badge.
struct CookingSheet: View {
    let streak: CookingStreak

    @Environment(\.recipeStore) private var recipeStore
    @Environment(\.badges) private var badges
    @Environment(\.dismiss) private var dismiss

    private var metrics: BadgeMetrics {
        BadgeMetrics.from(recipes: recipeStore.recipes, streakWeeks: streak.currentWeeks)
    }

    /// Only the cook-centric badges live here (this screen is their home); feature-first badges stay on Profile.
    private var cookingBadges: [BadgeType] {
        let cookingMetrics: Set<BadgeMetric> = [.recipesCooked, .weeklyStreak, .cuisinesCooked,
                                                .sameRecipeCooked, .recipesRated, .cookPhotos]
        return BadgeType.allCases.filter {
            if let metric = $0.criterion.metric { return cookingMetrics.contains(metric) }
            return false
        }
    }

    private var unlockedIds: Set<String> {
        Set(badges.getAllBadges(recipeCount: 0).filter(\.isUnlocked).map(\.id))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: AppTheme.spacing20) {
                        streakCard
                        badgesCard
                    }
                    .padding(AppTheme.spacing20)
                }
            }
            .appNavigationTitle("Cooking")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Streak

    private var streakCard: some View {
        VStack(spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(streak.isAtRisk ? .yellow : .orange)
                Text(streak.currentWeeks == 0 ? "No streak yet" : "\(streak.currentWeeks)-week streak")
                    .font(.title2).fontWeight(.bold)
                    .adaptiveForegroundColor()
            }

            Text(streakExplainer)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)

            if streak.currentWeeks > 0 {
                Text("Cooked \(streak.cooksThisWeek) time\(streak.cooksThisWeek == 1 ? "" : "s") this week")
                    .font(.caption)
                    .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .appCard(cornerRadius: AppTheme.cornerRadius16)
    }

    private var streakExplainer: String {
        let weeks = streak.currentWeeks
        let weekWord = weeks == 1 ? "week" : "weeks"
        if weeks == 0 {
            return "Cook a recipe this week to start a streak. It counts the weeks in a row you cook at least once."
        }
        if streak.isAtRisk {
            return "You've cooked at least once a week for \(weeks) \(weekWord). Cook this week to keep your streak alive 🔥"
        }
        return "You've cooked at least once a week for \(weeks) \(weekWord) in a row. Keep it going!"
    }

    // MARK: - Badges

    private var badgesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
            Text("Cooking badges")
                .font(.headline)
                .adaptiveForegroundColor()

            ForEach(cookingBadges, id: \.rawValue) { type in
                badgeRow(type, unlocked: unlockedIds.contains(type.rawValue))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .appCard(cornerRadius: AppTheme.cornerRadius16)
    }

    private func badgeRow(_ type: BadgeType, unlocked: Bool) -> some View {
        let badge = type.badge
        let color = Badge.color(for: badge.color)
        let progress = type.progress(for: metrics)

        return HStack(spacing: AppTheme.spacing12) {
            Image(systemName: badge.icon)
                .font(.title3)
                .foregroundStyle(unlocked ? color : .gray.opacity(AppTheme.glassLightOpacity))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(badge.title)
                    .font(.subheadline).fontWeight(.semibold)
                    .adaptiveForegroundColor()

                if unlocked {
                    Text("Unlocked").font(.caption).foregroundStyle(.green)
                } else if let progress {
                    ProgressView(value: Double(progress.current), total: Double(progress.target))
                        .tint(color)
                    Text("\(progress.current) / \(progress.target)")
                        .font(.caption2)
                        .adaptiveSecondaryForeground()
                } else {
                    Text(badge.description).font(.caption).adaptiveSecondaryForeground()
                }
            }

            Spacer()

            if unlocked {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }
    }
}
