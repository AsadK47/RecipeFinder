import SwiftUI

/// Adaptive (color-scheme aware) color helpers and theme accent colors.
extension AppTheme {

    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? cardBackgroundDark : cardBackground
    }
    
    static func elevatedCard(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? elevatedCardDark : elevatedCardLight
    }
    
    static func secondaryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? secondaryBackgroundDark : secondaryBackgroundLight
    }
    
    static func textColor(for colorScheme: ColorScheme, opacity: Double = 1.0) -> Color {
        let baseColor = colorScheme == .dark ? Color.white : Color.black
        return opacity == 1.0 ? baseColor : baseColor.opacity(opacity)
    }
    
    static func adaptiveCard(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: cardDarkOpacity) : Color.white.opacity(cardLightOpacity)
    }
    
    static func adaptiveCardMedium(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: cardDarkMediumOpacity) : Color.white.opacity(cardLightOpacity)
    }
    
    static func adaptiveCardHigh(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: cardDarkOpacity) : Color.white.opacity(cardLightHighOpacity)
    }
    
    static func adaptiveGlass(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: cardDarkOpacity) : Color.white.opacity(glassLightOpacity)
    }
    
    static func adaptiveShadow(for colorScheme: ColorScheme) -> Color {
        Color.black.opacity(colorScheme == .dark ? shadowDarkOpacity : shadowLightOpacity)
    }
    
    static func adaptiveFilterChip(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: cardDarkMediumOpacity).opacity(highEmphasisOpacity) 
            : Color(white: cardLightOpacity).opacity(cardLightOpacity)
    }
    
    static func adaptiveEmphasis(for colorScheme: ColorScheme, level: Double = 1.0) -> Color {
        colorScheme == .dark ? Color.white.opacity(level) : Color.black.opacity(level)
    }
    
    static func adaptiveHighEmphasis(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(highEmphasisOpacity) : Color.black.opacity(mediumEmphasisOpacity)
    }
    
    static func adaptiveMediumEmphasis(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(mediumEmphasisOpacity) : Color.black.opacity(lowEmphasisOpacity)
    }
    
    static func adaptiveSecondaryIndicator(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(glassLightOpacity) : Color.black.opacity(lowEmphasisOpacity)
    }
    
    static func adaptiveSubtitle(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(mediumEmphasisOpacity)
    }
    
    static func adaptiveCardTextEmphasis(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color.white.opacity(cardLightHighOpacity) 
            : Color.black.opacity(cardHighEmphasisLightOpacity)
    }
    
    /// Secondary text: pure black in light mode for legibility, secondaryLabel in dark; apply via `.adaptiveSecondaryForeground()`, not directly.
    static let adaptiveSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? .secondaryLabel : .label
    })

    /// Trait-resolved light/dark colour, so shared modifiers needn't read `@Environment(\.colorScheme)` (which warns when evaluated outside a view, e.g. under ViewInspector).
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
    
    static var accentColor: Color {
        return tealBrightLight
    }
}
