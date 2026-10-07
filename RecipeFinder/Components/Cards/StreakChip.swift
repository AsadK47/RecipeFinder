import SwiftUI

/// Compact flame + week-count pill for the Recipes header — a persistent, always-visible streak
/// indicator (Duolingo-style) that uses colour for loss aversion: warm orange when you've cooked
/// this week, amber when the streak is at risk (not cooked yet this week).
struct StreakChip: View {
    let streak: CookingStreak

    // Warm orange when on track this week; amber-yellow when at risk, so the colour itself signals "act".
    private var tint: Color { streak.isAtRisk ? .yellow : .orange }

    var body: some View {
        HStack(spacing: AppTheme.spacing4) {
            Image(systemName: "flame.fill")
                .font(.system(size: AppTheme.fontSize14, weight: .bold))
            Text("\(streak.currentWeeks)")
                .font(.system(size: AppTheme.fontSize15, weight: .bold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, AppTheme.spacing10)
        .padding(.vertical, AppTheme.spacing6)
        .background(Capsule().fill(tint.opacity(0.15)))
        .accessibilityIdentifier("streak.chip")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            streak.isAtRisk
                ? "\(streak.currentWeeks) week cooking streak, at risk — cook this week to keep it"
                : "\(streak.currentWeeks) week cooking streak"
        )
    }
}
