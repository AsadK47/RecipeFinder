import SwiftUI

/// Which badge the full-screen pager opens on.
struct BadgePagerStart: Identifiable {
    let badgeID: String
    var id: String { badgeID }
}

/// Full-screen badge cards: swipe left/right through every badge in shelf order. Locked cards show how far along
/// you are and a button to where you earn it.
struct BadgePagerView: View {
    let badges: [Badge]
    let metrics: BadgeMetrics
    /// Called after the pager closes itself, so the caller can switch tab.
    let onEarn: (BadgeEarnAction) -> Void

    @State private var selection: String
    /// Earned cards catch the light as the phone tilts (off under Reduce Motion — the sensors stay idle).
    @State private var tilt = TiltMotion()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(badges: [Badge], startID: String, metrics: BadgeMetrics, onEarn: @escaping (BadgeEarnAction) -> Void) {
        self.badges = badges
        self.metrics = metrics
        self.onEarn = onEarn
        let index = BadgeShelf.startIndex(of: startID, in: badges)
        _selection = State(initialValue: badges.indices.contains(index) ? badges[index].id : startID)
    }

    private var position: Int { BadgeShelf.startIndex(of: selection, in: badges) + 1 }

    var body: some View {
        ZStack {
            AppBackground()

            TabView(selection: $selection) {
                ForEach(badges) { badge in
                    BadgePage(badge: badge, metrics: metrics, tilt: reduceMotion ? nil : tilt, onEarn: { action in
                        dismiss()
                        onEarn(action)
                    })
                    .padding(.horizontal, AppTheme.spacing20)
                    .tag(badge.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear { if !reduceMotion { tilt.start() } }
            .onDisappear { tilt.stop() }
            .onChange(of: reduceMotion) { _, isReduced in
                if isReduced { tilt.stop() } else { tilt.start() }
            }

            VStack {
                HStack {
                    Text("\(position) of \(badges.count)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .adaptiveSecondaryForeground()
                        .accessibilityIdentifier("badge.pager.position")
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("badge.pager.close")
                }
                .padding(.horizontal, AppTheme.cardHorizontalPadding)
                .padding(.top, AppTheme.spacing12)
                Spacer()
            }
        }
    }
}

/// One full-screen badge card.
private struct BadgePage: View {
    let badge: Badge
    let metrics: BadgeMetrics
    let tilt: TiltMotion?
    let onEarn: (BadgeEarnAction) -> Void

    private var type: BadgeType? { BadgeType(rawValue: badge.id) }
    private var badgeColor: Color { Badge.color(for: badge.color) }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spacing24) {
                medallion
                    .padding(.top, AppTheme.spacing60)

                VStack(spacing: AppTheme.spacing8) {
                    if let group = type?.group {
                        Text(group.title)
                            .font(.caption.weight(.semibold))
                            .textCase(.uppercase)
                            .tracking(1.2)
                            .adaptiveSecondaryForeground()
                    }
                    Text(badge.title)
                        .font(.system(size: AppTheme.fontSize28, weight: .bold))
                        .adaptiveForegroundColor()
                    Text(badge.description)
                        .font(.title3)
                        .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                }
                .multilineTextAlignment(.center)

                if badge.isUnlocked {
                    earnedCard
                } else {
                    lockedCard
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, AppTheme.spacing32)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var medallion: some View {
        if badge.isUnlocked, let tilt {
            TiltingMedallion(badge: badge, tilt: tilt)
        } else {
            BadgeMedallion(badge: badge, progress: type?.progressFraction(for: metrics))
        }
    }

    private var earnedCard: some View {
        HStack(spacing: AppTheme.spacing8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(badgeColor)
            if let date = badge.dateEarned {
                Text("Earned \(date.formatted(date: .long, time: .omitted))")
            } else {
                Text("Earned")
            }
        }
        .font(.subheadline.weight(.semibold))
        .adaptiveForegroundColor()
        .padding()
        .appCard(cornerRadius: AppTheme.cornerRadius12)
    }

    private var lockedCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing8) {
                Image(systemName: "lock.fill")
                Text("Locked").fontWeight(.semibold)
                Spacer()
                if let progressText = type?.progressText(for: metrics) {
                    Text(progressText)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .accessibilityIdentifier("badge.pager.progress.\(badge.id)")
                }
            }
            .font(.subheadline)
            .adaptiveForegroundColor()

            if !badge.howToEarn.isEmpty {
                Text(badge.howToEarn)
                    .font(.subheadline)
                    .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let action = type?.earnAction {
                PrimaryButton(action.title, systemImage: action.icon, fillWidth: true) { onEarn(action) }
                    .accessibilityIdentifier("badge.pager.earn.\(badge.id)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .appCard(cornerRadius: AppTheme.cornerRadius12)
    }
}

/// Reads the tilt in its own body so 30 Hz motion updates redraw only the medallion, not the whole card.
private struct TiltingMedallion: View {
    let badge: Badge
    let tilt: TiltMotion

    var body: some View {
        BadgeMedallion(badge: badge, shine: tilt.shine)
    }
}
