import SwiftUI

/// Trophy shelf on Me: one swipeable row per badge group (Cooking / Streaks / Importing / Planning), newest earned
/// first, locked badges as silhouettes with a progress ring. Tap any badge → the full-screen pager.
struct ProfileBadgesSection: View {
    let sections: [BadgeShelfSection]
    let metrics: BadgeMetrics
    let onSelectBadge: (Badge) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing16) {
            HStack {
                Label("Trophy shelf", systemImage: "trophy.fill")
                    .font(.headline)
                    .adaptiveForegroundColor()
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(BadgeShelf.countText(sections))
                    .font(.subheadline.weight(.semibold))
                    .adaptiveSecondaryForeground()
                    .accessibilityLabel(BadgeShelf.spokenCount(sections))
            }

            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                    HStack(spacing: AppTheme.spacing6) {
                        Image(systemName: section.group.icon)
                            .font(.caption)
                            .adaptiveSecondaryForeground()
                        Text(section.group.title)
                            .font(.subheadline.weight(.semibold))
                            .adaptiveForegroundColor()
                        Spacer()
                        Text(section.countText)
                            .font(.caption.weight(.semibold))
                            .adaptiveSecondaryForeground()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: AppTheme.spacing4) {
                            ForEach(section.badges) { badge in
                                tile(badge)
                            }
                        }
                    }
                }
            }
        }
        .padding(AppTheme.cardHorizontalPadding)
        .appCard(cornerRadius: AppTheme.cornerRadius16)
    }

    private func tile(_ badge: Badge) -> some View {
        let type = BadgeType(rawValue: badge.id)
        let progressText = badge.isUnlocked ? nil : type?.progressText(for: metrics)
        return Button {
            HapticManager.shared.light()
            onSelectBadge(badge)
        } label: {
            BadgeCard(badge: badge, progress: badge.isUnlocked ? nil : type?.progressFraction(for: metrics))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(badge.title)
        .accessibilityValue(badge.isUnlocked ? "Earned" : ["Locked", progressText].compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint("Opens the badge")
        .accessibilityIdentifier("me.badge.\(badge.id)")
    }
}
