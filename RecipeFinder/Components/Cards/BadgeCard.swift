import SwiftUI

struct BadgeCard: View {
    let badge: Badge
    let colorScheme: ColorScheme
    let cardStyle: CardStyle

    var badgeColor: Color { Badge.color(for: badge.color) }

    var body: some View {
        VStack(spacing: AppTheme.spacing8) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? badgeColor.opacity(AppTheme.cardDarkMediumOpacity) : AppTheme.secondaryText.opacity(AppTheme.shadowLightOpacity))
                    .frame(width: AppTheme.width60, height: AppTheme.width60)

                Image(systemName: badge.icon)
                    .font(.system(size: AppTheme.fontSize28))
                    .foregroundColor(badge.isUnlocked ? badgeColor : .gray.opacity(AppTheme.glassLightOpacity))
            }

            Text(badge.title.components(separatedBy: " ").first ?? badge.title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(badge.isUnlocked ? AppTheme.adaptiveEmphasis(for: colorScheme) : .gray)
                .lineLimit(1)

            if badge.isUnlocked, let date = badge.dateEarned {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: AppTheme.fontSize11))
                    .adaptiveSecondaryForeground()
            } else {
                Text("Locked")
                    .font(.system(size: AppTheme.fontSize11))
                    .adaptiveSecondaryForeground()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacing12)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(colorScheme == .dark
                          ? Color(white: 0.1)
                          : Color.white.opacity(AppTheme.glassLightOpacity))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(.ultraThinMaterial.opacity(AppTheme.glassLightOpacity))
            }
        }
        .overlay {
            if !badge.isUnlocked {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(Color.black.opacity(AppTheme.shadowDarkOpacity))
            }
        }
    }
}
