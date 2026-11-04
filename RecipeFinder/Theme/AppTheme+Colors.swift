import SwiftUI

/// Adaptive (color-scheme aware) color helpers and theme accent colors.
extension AppTheme {

    // Every colour here resolves light/dark from the trait collection, so views use them directly — no
    // `@Environment(\.colorScheme)` read or `colorScheme == .dark ? … : …` at call sites.

    static let secondaryBackground = adaptive(light: secondaryBackgroundLight, dark: secondaryBackgroundDark)

    /// Black in light mode, white in dark.
    static func textColor(opacity: Double = 1.0) -> Color {
        adaptive(light: .black.opacity(opacity), dark: .white.opacity(opacity))
    }

    static let adaptiveFilterChip = adaptive(
        light: Color(white: cardLightOpacity).opacity(cardLightOpacity),
        dark: Color(white: cardDarkMediumOpacity).opacity(highEmphasisOpacity)
    )

    /// Same as `textColor(opacity:)`; kept as the emphasis-scale spelling used across views.
    static func adaptiveEmphasis(level: Double = 1.0) -> Color {
        textColor(opacity: level)
    }

    static let adaptiveHighEmphasis = adaptive(light: .black.opacity(mediumEmphasisOpacity), dark: .white.opacity(highEmphasisOpacity))

    static let adaptiveMediumEmphasis = adaptive(light: .black.opacity(lowEmphasisOpacity), dark: .white.opacity(mediumEmphasisOpacity))

    static let adaptiveSubtitle = adaptive(light: .black.opacity(mediumEmphasisOpacity), dark: .white.opacity(0.7))

    static let adaptiveCardTextEmphasis = adaptive(
        light: .black.opacity(cardHighEmphasisLightOpacity),
        dark: .white.opacity(cardLightHighOpacity)
    )

    /// Secondary text: pure black in light mode for legibility, secondaryLabel in dark; apply via `.adaptiveSecondaryForeground()`, not directly.
    static let adaptiveSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? .secondaryLabel : .label
    })

    /// Trait-resolved light/dark colour, so views and shared modifiers needn't read `@Environment(\.colorScheme)` (which warns when evaluated outside a view, e.g. under ViewInspector).
    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    static func accentColor(for theme: ThemeType) -> Color {
        switch theme {
        case .teal:     return tealBrightLight
        case .purple:   return purpleRich
        case .red:      return redCrimson
        case .orange:   return orangeBright
        case .yellow:   return yellowBright
        case .green:    return greenVibrant
        case .pink:     return pinkHot
        case .gold:     return goldRich
        }
    }
    
    /// The user's chosen theme colour (was hard-coded teal, so 22 call sites ignored the picker).
    @MainActor
    static var accentColor: Color {
        accentColor(for: ThemeStore.shared.theme)
    }
}
