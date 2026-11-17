import SwiftUI

/// Top of Me: who you are as a cook — photo or initials on your chef type's colour, name, chef type as a title, and
/// one stats strip (meals cooked · week streak · cuisines tried). Opens Profile, where the badges and form live.
struct MeHeroCard: View {
    let image: UIImage?
    /// Empty when there's no name yet: the avatar shows a person symbol, not "RC" from the "Recipe Chef" stand-in.
    let initials: String
    let name: String
    let chefType: ChefType
    let stats: [MeStat]
    let badgeCount: String
    let spokenBadgeCount: String
    let onTap: () -> Void

    @ScaledMetric(relativeTo: .title) private var avatarSize: CGFloat = 72
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button {
            HapticManager.shared.light()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                identity
                if MeStats.hasCooked(stats) {
                    statsStrip
                } else {
                    Text("Cook your first meal and your story starts here.")
                        .font(.subheadline)
                        .adaptiveSecondaryForeground()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(AppTheme.spacing16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard(cornerRadius: AppTheme.cornerRadius16, elevated: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityValue(spokenValue)
        .accessibilityHint("Opens your profile, badges and chef type")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("me.profile")
    }

    private var spokenValue: String {
        let cooking = MeStats.hasCooked(stats) ? MeStats.spokenSummary(stats) : "Nothing cooked yet"
        return "\(chefType.rawValue), \(cooking), \(spokenBadgeCount)"
    }

    // MARK: - Identity

    @ViewBuilder private var identity: some View {
        // At accessibility sizes the name goes under the avatar so it isn't squeezed into a sliver.
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                avatar
                nameAndTitle
            }
        } else {
            HStack(spacing: AppTheme.spacing16) {
                avatar
                nameAndTitle
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .adaptiveSecondaryForeground()
                    .accessibilityHidden(true)
            }
        }
    }

    private var nameAndTitle: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
            Text(name)
                .font(.title2.weight(.bold))
                .adaptiveForegroundColor()
                .fixedSize(horizontal: false, vertical: true)
            Label(chefType.rawValue, systemImage: chefType.icon)
                .font(.subheadline.weight(.semibold))
                .adaptiveForegroundColor()
            Label(badgeCount, systemImage: "trophy.fill")
                .font(.subheadline)
                .adaptiveSecondaryForeground()
        }
    }

    @ViewBuilder private var avatar: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
                .overlay(Circle().stroke(chefType.heroColor, lineWidth: 3))
                .accessibilityHidden(true)
        } else if initials.isEmpty {
            IconBadge(systemName: "person.fill", tint: chefType.heroColor, diameter: avatarSize, style: .solid)
                .accessibilityHidden(true)
        } else {
            Text(initials)
                .font(.title.weight(.bold))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(AppTheme.spacing6)
                // Fixed white: every hero colour is deep enough for white text in both modes.
                .foregroundStyle(.white)
                .frame(width: avatarSize, height: avatarSize)
                .background(Circle().fill(chefType.heroColor))
                .accessibilityHidden(true)
        }
    }

    // MARK: - Stats strip

    @ViewBuilder private var statsStrip: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                ForEach(stats) { stat in
                    HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacing8) {
                        statValue(stat)
                        statLabel(stat)
                    }
                }
            }
        } else {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                    if index > 0 {
                        Rectangle()
                            .fill(AppTheme.subtleStroke)
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)
                    }
                    VStack(spacing: AppTheme.spacing2) {
                        statValue(stat)
                        statLabel(stat)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func statValue(_ stat: MeStat) -> some View {
        Text("\(stat.value)")
            .font(.title2.weight(.bold))
            .monospacedDigit()
            .adaptiveForegroundColor()
    }

    private func statLabel(_ stat: MeStat) -> some View {
        Text(stat.label)
            .font(.caption.weight(.medium))
            .adaptiveSecondaryForeground()
    }
}

extension ChefType {
    /// The hero avatar's backdrop (`AppTheme` palette — deep enough for white initials).
    var heroColor: Color {
        switch self {
        case .homeCook:         AppTheme.chefHomeCook
        case .foodie:           AppTheme.chefFoodie
        case .baker:            AppTheme.chefBaker
        case .grillMaster:      AppTheme.chefGrillMaster
        case .healthNut:        AppTheme.chefHealthNut
        case .adventurousEater: AppTheme.chefAdventurousEater
        }
    }
}

#Preview("Seasoned cook") {
    MeHeroCard(image: nil, initials: "AK", name: "Asad Khan", chefType: .grillMaster,
               stats: MeStats.strip(meals: 42, streakWeeks: 6, cuisines: 9),
               badgeCount: "7 / 24", spokenBadgeCount: "7 of 24 badges earned") {}
        .padding()
        .background(AppBackground())
}

#Preview("New cook") {
    MeHeroCard(image: nil, initials: "", name: "Recipe Chef", chefType: .homeCook,
               stats: MeStats.strip(meals: 0, streakWeeks: 0, cuisines: 0),
               badgeCount: "0 / 24", spokenBadgeCount: "0 of 24 badges earned") {}
        .padding()
        .background(AppBackground())
}
