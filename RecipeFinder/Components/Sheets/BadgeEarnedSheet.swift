import SwiftUI
import ConfettiSwiftUI

/// Celebratory bottom sheet shown once per badge unlock.
/// Fires confetti + success haptic on appear, auto-dismisses after 4 s,
/// and dequeues the next badge via `BadgeManager.dismissCelebration()`.
struct BadgeEarnedSheet: View {
    let badge: BadgeType
    let onDismiss: () -> Void

    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @State private var confettiCounter = 0
    @State private var appeared = false

    private var badgeColor: Color { Badge.color(for: badge.badge.color) }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: theme, colorScheme: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: AppTheme.spacing24) {
                // Badge icon
                ZStack {
                    Circle()
                        .fill(badgeColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                    Image(systemName: badge.badge.icon)
                        .font(.system(size: 64))
                        .foregroundStyle(badgeColor)
                        .symbolEffect(.bounce, value: appeared)
                }
                .padding(.top, AppTheme.spacing32)

                // Text
                VStack(spacing: AppTheme.spacing8) {
                    Text("Badge Earned!")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1.2)

                    Text(badge.badge.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()

                    Text(badge.badge.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppTheme.spacing32)

                Spacer()

                // CTA
                Button(action: onDismiss) {
                    Text("View all badges")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.height50)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(badgeColor.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                        .stroke(badgeColor.opacity(0.4), lineWidth: 1)
                                )
                        )
                }
                .padding(.horizontal, AppTheme.spacing32)
                .padding(.bottom, AppTheme.spacing32)
            }
        }
        .confettiCannon(trigger: $confettiCounter, num: AppTheme.confettiCount, radius: AppTheme.confettiRadiusSmall)
        .onAppear {
            appeared = true
            confettiCounter += 1
            HapticManager.shared.celebrate()
            // Auto-dismiss after 4 s so it never blocks the UI indefinitely.
            Task {
                try? await Task.sleep(for: .seconds(4))
                onDismiss()
            }
        }
    }
}

#Preview {
    BadgeEarnedSheet(badge: .firstRecipe, onDismiss: {})
}
