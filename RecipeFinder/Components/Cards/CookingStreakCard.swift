import SwiftUI

/// Compact home habit card: the weekly cooking streak + cooks-this-week. Rewards the act of cooking
/// (not browsing) and gives a visible goal to keep — the core of the recipe-app habit loop.
struct CookingStreakCard: View {
    let streak: CookingStreak

    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(streak.currentWeeks > 0 ? 0.18 : 0.10))
                    .frame(width: 44, height: 44)
                Image(systemName: "flame.fill")
                    .font(.system(size: AppTheme.fontSize20, weight: .semibold))
                    .foregroundStyle(streak.currentWeeks > 0 ? .orange : .secondary)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                Text(title)
                    .font(.body).fontWeight(.semibold)
                    .adaptiveForegroundColor()
                Text(subtitle)
                    .font(.caption)
                    .adaptiveSecondaryForeground()
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(AppTheme.spacing16)
        .appCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }

    private var title: String {
        streak.currentWeeks > 0
            ? "\(streak.currentWeeks)-week cooking streak"
            : "Start a cooking streak"
    }

    private var subtitle: String {
        if streak.cookedThisWeek {
            return "\(streak.cooksThisWeek) cooked this week — keep it going 🔥"
        } else if streak.currentWeeks > 0 {
            return "Cook something this week to keep your streak alive"
        } else {
            return "Cook a recipe this week to begin"
        }
    }
}
