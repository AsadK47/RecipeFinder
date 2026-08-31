import Foundation

/// Non-dimensional tokens: opacities, animation timings, shimmer/confetti config,
/// haptic intervals, and other constants.
extension AppTheme {

    static let shimmerPhaseDistance: CGFloat = 400
    static let shimmerRotation: Double = 30
    static let shimmerDuration: Double = 1.5
    static let shimmerOpacity: Double = 0.3

    static let animationDelayXShort: Double = 0.3
    static let animationDelayShort: Double = 0.4
    static let animationDelayMedium: Double = 0.5
    static let animationDelayLong: Double = 1.0
    static let animationDelayXLong: Double = 1.5
    static let animationDelayFeedback: Double = 2.0
    static let animationDelayXXLong: Double = 5.0

    static let animationDuration07: Double = 0.7
    static let animationDuration08: Double = 0.8
    static let animationDuration25: Double = 2.5

    static let confettiCount: Int = 50
    static let confettiRadius: CGFloat = 500
    static let confettiRadiusSmall: CGFloat = 400

    static let cardDarkOpacity: Double = 0.15
    static let cardDarkMediumOpacity: Double = 0.2
    static let cardLightOpacity: Double = 0.9
    static let cardLightHighOpacity: Double = 0.95
    static let glassLightOpacity: Double = 0.5
    static let dividerOpacity: Double = 0.1
    static let overlayLightOpacity: Double = 0.2
    static let shadowLightOpacity: Double = 0.1
    static let shadowDarkOpacity: Double = 0.3

    static let tinyOpacity: Double = 0.08
    static let microOpacity: Double = 0.12
    static let dimGlassOpacity: Double = 0.18
    static let softOverlayOpacity: Double = 0.25
    static let mediumOverlayOpacity: Double = 0.35
    static let glassSubtleOpacity: Double = 0.05
    static let zeroOpacity: Double = 0.0
    static let fullOpacity: Double = 1.0
    static let highEmphasisOpacity: Double = 0.8
    static let mediumEmphasisOpacity: Double = 0.6
    static let subduedEmphasisOpacity: Double = 0.7
    static let disabledEmphasisOpacity: Double = 0.65
    static let lowEmphasisOpacity: Double = 0.4
    static let nearSolidOpacity: Double = 0.85
    static let veryHighEmphasisOpacity: Double = 0.9
    static let cardHighEmphasisLightOpacity: Double = 0.75
    static let bannerHeightRatio: Double = 0.18

    static let rotationFlipped: Double = 180
    static let rotationNeutral: Double = 0

    static let jpegCompressionQuality: Double = 0.8

    static let hapticIntervalShort: UInt64 = 100_000_000
    static let hapticIntervalMedium: UInt64 = 150_000_000
    static let hapticIntervalBase: UInt64 = 200_000_000
    static let hapticIntervalLong: UInt64 = 300_000_000
    static let hapticIntervalXLong: UInt64 = 500_000_000
}
