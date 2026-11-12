import CoreGraphics

/// Rules for the full-screen badge reveal, kept pure so tests can pin them.
enum BadgeReveal {
    /// The reveal waits while the Made it or "+" sheet is up: the same cook or import often earns the badge, and two
    /// modals at once left neither on screen.
    static func showing(_ pending: BadgeType?, isAnotherSheetUp: Bool) -> BadgeType? {
        isAnotherSheetUp ? nil : pending
    }

    /// How long the reveal stays before closing itself; nil = it waits for the cook. 8 s, not 4: 4 was too short to
    /// reach "View all badges". VoiceOver users close it themselves (it would vanish mid-read), and the screenshot run
    /// holds it so a slow simulator's ✕ tap isn't beaten by the timer.
    static func autoCloseAfter(voiceOverOn: Bool, heldForUITest: Bool) -> Duration? {
        voiceOverOn || heldForUITest ? nil : .seconds(8)
    }

    /// How the reveal moves. Reduce Motion keeps the moment (title, haptic) but drops the flip, shine, confetti and
    /// the settle toward the tab bar.
    struct Motion: Equatable {
        /// Degrees around the vertical axis the medallion flips in from (0 = already facing you).
        let flipFromDegrees: Double
        let sweepsShine: Bool
        let firesConfetti: Bool
        /// Shrinks the medallion down toward the Me tab when the reveal closes.
        let settles: Bool
    }

    static func motion(reduceMotion: Bool) -> Motion {
        reduceMotion
            ? Motion(flipFromDegrees: 0, sweepsShine: false, firesConfetti: false, settles: false)
            : Motion(flipFromDegrees: 90, sweepsShine: true, firesConfetti: true, settles: true)
    }
}

/// Where the shine sits on an earned badge as the phone tilts.
enum BadgeShine {
    /// Radians of tilt (~35°) that move the shine from the centre to the edge.
    static let fullTravel = 0.6

    /// Offset per axis in -1...1, relative to how the phone was held when the card opened (so holding it at any
    /// angle starts centred). Tilting right moves the shine right; tilting the top away moves it up.
    static func offset(roll: Double, pitch: Double, baselineRoll: Double, baselinePitch: Double) -> CGSize {
        CGSize(
            width: travel(roll - baselineRoll),
            height: -travel(pitch - baselinePitch)
        )
    }

    private static func travel(_ radians: Double) -> CGFloat {
        guard radians.isFinite else { return 0 }
        return CGFloat(min(max(radians / fullTravel, -1), 1))
    }
}
