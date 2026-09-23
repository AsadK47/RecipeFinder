import SwiftUI

struct BiometricBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    let spacing: AdaptiveSpacing
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: spacing.lg) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(AppTheme.softOverlayOpacity),
                                Color.white.opacity(AppTheme.cardDarkOpacity)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: spacing.touchTarget, height: spacing.touchTarget)

                Image(systemName: icon)
                    .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                    .foregroundStyle(AppTheme.textColor(for: colorScheme))
            }

            VStack(alignment: .leading, spacing: spacing.xxs) {
                Text(title)
                    .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                    .foregroundStyle(AppTheme.textColor(for: colorScheme))

                Text(description)
                    .font(.system(size: AppTheme.fontSize14, weight: .medium))
                    .foregroundStyle(AppTheme.textColor(for: colorScheme, opacity: 0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, spacing.xxs)
    }
}
