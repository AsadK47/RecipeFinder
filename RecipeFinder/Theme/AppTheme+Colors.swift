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

    /// Chip / secondary-button fill. Dark keeps the original white wash; light needs a dark wash, as white vanished on the light gradient.
    static let subtleFill = adaptive(light: .black.opacity(0.06), dark: .white.opacity(cardDarkOpacity))

    /// Opaque card surface for Reduce Transparency (white in Light, iOS's raised grey in Dark).
    static let solidCard = Color(uiColor: .secondarySystemGroupedBackground)

    /// Hairlines, dividers, outlines and grabbers — the stronger partner of `subtleFill`.
    static let subtleStroke = adaptive(light: .black.opacity(0.12), dark: .white.opacity(shadowDarkOpacity))

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

    /// Trait-resolved colour with Increase Contrast variants (`accessibilityContrast == .high`).
    static func adaptive(light: Color, dark: Color, highContrastLight: Color, highContrastDark: Color) -> Color {
        Color(UIColor { traits in
            let high = traits.accessibilityContrast == .high
            if traits.userInterfaceStyle == .dark {
                return UIColor(high ? highContrastDark : dark)
            }
            return UIColor(high ? highContrastLight : light)
        })
    }

    /// Text and icons on an accent fill (buttons, toasts, ticks, avatars). White on every accent (≥4.5:1, ≥7:1 under
    /// Increase Contrast in Light); black on Dark + Increase Contrast, whose accents go light (see `ThemeSwatch`).
    static let onAccent = adaptive(light: .white, dark: .white, highContrastLight: .white, highContrastDark: .black)

    /// Built once per theme: `accentColor` is read from many `body`s, and one instance per theme keeps it `==` itself.
    static func accentColor(for theme: ThemeType) -> Color {
        accentColors[theme] ?? Color.accentColor
    }

    private static let accentColors: [ThemeType: Color] = Dictionary(uniqueKeysWithValues: ThemeType.allCases.map { theme in
        let swatch = theme.swatch
        return (theme, adaptive(
            light: Color(swatch.accent(dark: false, highContrast: false)),
            dark: Color(swatch.accent(dark: true, highContrast: false)),
            highContrastLight: Color(swatch.accent(dark: false, highContrast: true)),
            highContrastDark: Color(swatch.accent(dark: true, highContrast: true))
        ))
    })

    /// The user's chosen theme colour (was hard-coded teal, so 22 call sites ignored the picker).
    @MainActor
    static var accentColor: Color {
        accentColor(for: ThemeStore.shared.theme)
    }
}
