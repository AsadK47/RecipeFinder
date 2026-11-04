import SwiftUI

struct BadgeDetailView: View {
    let badge: Badge
    @Environment(\.dismiss) var dismiss
    @Environment(\.recipeStore) private var recipeStore
    @Environment(\.cookingStreak) private var cookingStreak

    var badgeColor: Color { Badge.color(for: badge.color) }

    /// How far the user is toward a still-locked threshold badge, or nil for event/unlocked badges.
    private var progress: (current: Int, target: Int)? {
        guard !badge.isUnlocked, let type = BadgeType(rawValue: badge.id) else { return nil }
        let metrics = BadgeMetrics.from(recipes: recipeStore.recipes, streakWeeks: cookingStreak.streak.currentWeeks)
        return type.progress(for: metrics)
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: AppTheme.spacing32) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                    }
                }
                .padding(.horizontal, AppTheme.cardHorizontalPadding)
                .padding(.top, AppTheme.spacing20)

                Spacer()

                ZStack {
                    Circle()
                        .fill(badge.isUnlocked ? badgeColor.opacity(AppTheme.cardDarkMediumOpacity) : AppTheme.secondaryText.opacity(AppTheme.shadowLightOpacity))
                        .frame(width: AppTheme.width120, height: AppTheme.width120)

                    Image(systemName: badge.icon)
                        .font(.system(size: AppTheme.fontSize60))
                        .foregroundStyle(badge.isUnlocked ? badgeColor : .gray.opacity(AppTheme.glassLightOpacity))
                }
                .shadow(color: badge.isUnlocked ? badgeColor.opacity(AppTheme.shadowDarkOpacity) : .clear, radius: 20)

                Text(badge.title)
                    .font(.system(size: AppTheme.fontSize28, weight: .bold))
                    .adaptiveForegroundColor()
                    .multilineTextAlignment(.center)

                Text(badge.description)
                    .font(.title3)
                    .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                    .multilineTextAlignment(.center)

                if badge.isUnlocked, let date = badge.dateEarned {
                    VStack(spacing: AppTheme.spacing8) {
                        HStack(spacing: AppTheme.spacing8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Unlocked!").fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.spacing12)
                        .padding(.vertical, AppTheme.spacing6)
                        .background(Capsule().fill(.green))

                        Text("Earned on \(date.formatted(date: .long, time: .omitted))")
                            .font(.subheadline)
                            .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                    }
                    .padding()
                    .appCard(cornerRadius: AppTheme.cornerRadius12)
                } else {
                    VStack(spacing: AppTheme.spacing8) {
                        HStack(spacing: AppTheme.spacing8) {
                            Image(systemName: "lock.fill").adaptiveSecondaryForeground()
                            Text("Locked").fontWeight(.semibold).adaptiveSecondaryForeground()
                        }
                        .font(.headline)

                        if !badge.howToEarn.isEmpty {
                            Divider().padding(.vertical, AppTheme.spacing4)

                            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                                Text("How to Earn:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                                    .textCase(.uppercase)

                                Text(badge.howToEarn)
                                    .font(.subheadline)
                                    .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        if let progress {
                            Divider().padding(.vertical, AppTheme.spacing4)
                            VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                                ProgressView(value: Double(progress.current), total: Double(progress.target))
                                    .tint(badgeColor)
                                Text("\(progress.current) / \(progress.target)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .appCard(cornerRadius: AppTheme.cornerRadius12)
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, AppTheme.spacing20)
        }
    }
}
