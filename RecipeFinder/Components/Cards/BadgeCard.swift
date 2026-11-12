import SwiftUI

/// One badge on the trophy shelf. Earned: full colour + date. Locked: a grey silhouette with a ring showing how far
/// along you are (threshold badges only).
struct BadgeCard: View {
    let badge: Badge
    /// Share done (0…1) toward a locked threshold badge; nil hides the ring.
    var progress: Double?

    var badgeColor: Color { Badge.color(for: badge.color) }

    var body: some View {
        VStack(spacing: AppTheme.spacing6) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? badgeColor.opacity(AppTheme.cardDarkMediumOpacity) : AppTheme.subtleFill)
                    .frame(width: AppTheme.width60, height: AppTheme.width60)

                if !badge.isUnlocked, let progress {
                    Circle()
                        .stroke(AppTheme.subtleStroke, lineWidth: 3)
                        .frame(width: 66, height: 66)
                    Circle()
                        .trim(from: 0, to: max(0.02, min(progress, 1)))
                        .stroke(badgeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 66, height: 66)
                }

                Image(systemName: badge.icon)
                    .font(.system(size: AppTheme.fontSize28))
                    .foregroundStyle(badge.isUnlocked ? badgeColor : AppTheme.secondaryText.opacity(AppTheme.glassLightOpacity))
            }
            .frame(width: AppTheme.width70, height: AppTheme.width70)

            // Full title — first-word truncation turned "First Bite" / "Head Chef" into "First" / "Head".
            // Fixed width on the Text itself: a horizontal scroll proposes infinite width, so without it the title
            // stays on one line and is clipped ("Kitchen Veterar"). Fixed grey was unreadable on the gradient.
            Text(badge.title)
                .font(.caption2)
                .fontWeight(.semibold)
                .adaptiveForegroundColor(opacity: badge.isUnlocked ? 1 : AppTheme.subduedEmphasisOpacity)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
                .frame(width: AppTheme.width88)

            if badge.isUnlocked, let date = badge.dateEarned {
                Text(date.formatted(.dateTime.day().month(.abbreviated).year(.twoDigits)))
                    .font(.system(size: AppTheme.fontSize11))
                    .adaptiveSecondaryForeground()
            } else {
                Text(badge.isUnlocked ? "Earned" : "Locked")
                    .font(.system(size: AppTheme.fontSize11))
                    .adaptiveSecondaryForeground()
            }
        }
        .frame(width: AppTheme.width88)
    }
}
