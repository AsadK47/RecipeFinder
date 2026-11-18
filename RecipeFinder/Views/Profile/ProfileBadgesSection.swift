import SwiftUI

/// Trophy shelf on Me › Profile: earned medals first (newest first), then "Next up" — the three badges you're closest
/// to, with progress rings. The full shelf (one row per group, locked badges included) sits behind See all, so a new
/// cook doesn't face a wall of locked circles. Tap any badge → the full-screen pager.
struct ProfileBadgesSection: View {
    let sections: [BadgeShelfSection]
    let earned: [Badge]
    let nextUp: [Badge]
    let metrics: BadgeMetrics
    let onSelectBadge: (Badge) -> Void
    /// The empty medal row's one action (Me › Profile has no tab of its own to switch to).
    let onStartCooking: () -> Void

    @State private var showAll = false

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

            earnedRow

            if !nextUp.isEmpty {
                nextUpRow
            }

            Button {
                HapticManager.shared.light()
                withAnimation(.appSpring) { showAll.toggle() }
            } label: {
                HStack(spacing: AppTheme.spacing6) {
                    Text(showAll ? "Show less" : "See all \(BadgeShelf.total(sections)) badges")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: showAll ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                }
                .adaptiveForegroundColor()
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.spacing8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("me.badges.seeAll")

            if showAll {
                ForEach(sections) { section in
                    groupRow(section)
                }
            }
        }
        .padding(AppTheme.cardHorizontalPadding)
        .appCard(cornerRadius: AppTheme.cornerRadius16)
    }

    // MARK: - Earned

    @ViewBuilder private var earnedRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            subheading("Earned", icon: "medal.fill", trailing: earned.isEmpty ? nil : "\(earned.count)")
            if earned.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                    Text("Your first medal is one cook away.")
                        .font(.subheadline)
                        .adaptiveSecondaryForeground()
                        .fixedSize(horizontal: false, vertical: true)
                    PrimaryButton(BadgeEarnAction.cook.title, systemImage: BadgeEarnAction.cook.icon, size: .compact) {
                        onStartCooking()
                    }
                    .accessibilityIdentifier("me.badges.startCooking")
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: AppTheme.spacing4) {
                        ForEach(earned) { badge in
                            tile(badge, identifier: "me.earned.\(badge.id)")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Next up

    private var nextUpRow: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            subheading("Next up", icon: "arrow.up.forward.circle.fill", trailing: nil)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: AppTheme.spacing4) {
                    ForEach(nextUp) { badge in
                        tile(badge, identifier: "me.nextUp.\(badge.id)", showCount: true)
                    }
                }
            }
        }
    }

    // MARK: - Full shelf (See all)

    private func groupRow(_ section: BadgeShelfSection) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            subheading(section.group.title, icon: section.group.icon, trailing: section.countText)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: AppTheme.spacing4) {
                    ForEach(section.badges) { badge in
                        tile(badge, identifier: "me.badge.\(badge.id)")
                    }
                }
            }
        }
    }

    private func subheading(_ title: String, icon: String, trailing: String?) -> some View {
        HStack(spacing: AppTheme.spacing6) {
            Image(systemName: icon)
                .font(.caption)
                .adaptiveSecondaryForeground()
            Text(title)
                .font(.subheadline.weight(.semibold))
                .adaptiveForegroundColor()
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.semibold))
                    .adaptiveSecondaryForeground()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func tile(_ badge: Badge, identifier: String, showCount: Bool = false) -> some View {
        let type = BadgeType(rawValue: badge.id)
        let progressText = badge.isUnlocked ? nil : type?.progressText(for: metrics)
        return Button {
            HapticManager.shared.light()
            onSelectBadge(badge)
        } label: {
            BadgeCard(
                badge: badge,
                progress: badge.isUnlocked ? nil : type?.progressFraction(for: metrics),
                caption: showCount ? progressText : nil
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(badge.title)
        .accessibilityValue(badge.isUnlocked ? "Earned" : ["Locked", progressText].compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint("Opens the badge")
        .accessibilityIdentifier(identifier)
    }
}
