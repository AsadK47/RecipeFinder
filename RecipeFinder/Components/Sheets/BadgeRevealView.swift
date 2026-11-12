import SwiftUI
import ConfettiSwiftUI

/// Full-screen moment for each badge unlock: the medallion flips in, a shine sweeps across, confetti in the badge's
/// colour and its own haptic pattern; on close it shrinks down toward the Me tab. Closes by the ✕, a swipe down,
/// "View all badges", or on its own after 8 s. The caller dequeues the next badge via `BadgeManager.dismissCelebration()`.
struct BadgeRevealView: View {
    let badge: BadgeType
    let onDismiss: () -> Void
    /// Fired only on an explicit "View all badges" tap (distinct from auto-dismiss) so the caller can navigate.
    let onViewAllBadges: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var flip: Double?
    @State private var shine = CGSize(width: -1.8, height: -1.8)
    @State private var settled = false
    @State private var closing = false
    @State private var confettiCounter = 0

    private var badgeColor: Color { Badge.color(for: badge.badge.color) }
    private var motion: BadgeReveal.Motion { BadgeReveal.motion(reduceMotion: reduceMotion) }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: AppTheme.spacing24) {
                HStack {
                    Spacer()
                    Button { close(then: onDismiss) } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("badge.reveal.close")
                }
                .padding(.horizontal, AppTheme.cardHorizontalPadding)
                .padding(.top, AppTheme.spacing12)

                Spacer()

                BadgeMedallion(
                    icon: badge.badge.icon,
                    color: badgeColor,
                    isUnlocked: true,
                    shine: motion.sweepsShine ? shine : nil
                )
                .rotation3DEffect(.degrees(flip ?? motion.flipFromDegrees), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .scaleEffect(settled ? 0.2 : 1)
                .offset(y: settled ? 420 : 0)
                .opacity(settled ? 0 : 1)

                VStack(spacing: AppTheme.spacing8) {
                    Text("Badge Earned!")
                        .font(.caption.weight(.semibold))
                        .adaptiveSecondaryForeground()
                        .textCase(.uppercase)
                        .tracking(1.2)

                    Text(badge.badge.title)
                        .font(.system(size: AppTheme.fontSize28, weight: .bold))
                        .adaptiveForegroundColor()
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("badge.reveal.title")

                    Text(badge.badge.description)
                        .font(.title3)
                        .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.spacing32)

                Spacer()

                PrimaryButton("View all badges", systemImage: "trophy.fill", fillWidth: true) {
                    close(then: onViewAllBadges)
                }
                .accessibilityIdentifier("badge.reveal.viewAll")
                .padding(.horizontal, AppTheme.spacing32)
                .padding(.bottom, AppTheme.spacing32)
            }
        }
        .contentShape(Rectangle())
        // Full-screen covers don't swipe away on their own; a downward drag keeps the old sheet gesture working.
        .gesture(
            DragGesture(minimumDistance: 20).onEnded { value in
                if value.translation.height > 80 { close(then: onDismiss) }
            }
        )
        .accessibilityAction(.escape) { close(then: onDismiss) }
        .confettiCannon(
            trigger: $confettiCounter,
            num: AppTheme.confettiCount,
            colors: [badgeColor, badgeColor.opacity(0.6), .white],
            radius: AppTheme.confettiRadius
        )
        .task { await play() }
    }

    /// Flip in → land (confetti + haptic) → shine sweep → close by itself after 8 s. Cancelled when the view goes.
    private func play() async {
        let motion = motion
        if motion.flipFromDegrees != 0 {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.55)) { flip = 0 }
            try? await Task.sleep(for: .milliseconds(350))
        } else {
            flip = 0
        }
        guard !Task.isCancelled else { return }
        HapticManager.shared.badgeReveal()
        if motion.firesConfetti { confettiCounter += 1 }
        if motion.sweepsShine {
            withAnimation(.easeInOut(duration: 1.1).delay(0.2)) { shine = CGSize(width: 1.8, height: 1.8) }
        }
        // 8 s, not 4: 4 was too short to reach "View all badges".
        try? await Task.sleep(for: .seconds(8))
        guard !Task.isCancelled else { return }
        close(then: onDismiss)
    }

    /// Settle the medallion down toward the tab bar, then hand back to the caller (once — taps, swipes and the timer
    /// can race).
    private func close(then action: @escaping () -> Void) {
        guard !closing else { return }
        closing = true
        guard motion.settles else {
            action()
            return
        }
        withAnimation(.easeIn(duration: 0.35)) {
            settled = true
        } completion: {
            action()
        }
    }
}

#Preview {
    BadgeRevealView(badge: .headChef, onDismiss: {}, onViewAllBadges: {})
}
