//
//  AppTheme.swift
//  RecipeFinder
//
//  Created by asad.e.khan on 12/10/2025.
//
 import SwiftUI

// Theme Environment Key
private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppTheme.ThemeType = .teal // Changed to teal as default
}

extension EnvironmentValues {
    var appTheme: AppTheme.ThemeType {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// Theme Configuration
enum AppTheme {
    // MARK: - Typography System
    
    // Font Sizes - Semantic naming based on Apple's Human Interface Guidelines
    static let fontSizeLargeTitle: CGFloat = 34      // Large titles, hero text
    static let fontSizeTitle1: CGFloat = 28          // Primary section titles
    static let fontSizeTitle2: CGFloat = 22          // Secondary section titles
    static let fontSizeTitle3: CGFloat = 20          // Tertiary titles
    static let fontSizeHeadline: CGFloat = 17        // Prominent body text, headlines
    static let fontSizeBody: CGFloat = 16            // Standard body text
    static let fontSizeCallout: CGFloat = 15         // Callouts, less prominent body
    static let fontSizeSubheadline: CGFloat = 14     // Subheadings, captions
    static let fontSizeFootnote: CGFloat = 13        // Footnotes, auxiliary info
    static let fontSizeCaption1: CGFloat = 12        // Small captions, labels
    static let fontSizeCaption2: CGFloat = 11        // Smallest readable text
    static let fontSizeTiny: CGFloat = 10            // Minimal text (badges, etc.)
    
    // Special sizes for specific use cases
    static let fontSizeHero: CGFloat = 80            // Hero/splash screens
    static let fontSizeDisplay: CGFloat = 60         // Large display text
    static let fontSizeLarge: CGFloat = 42           // Large accent text
    static let fontSizeMediumLarge: CGFloat = 38     // Medium-large display
    static let fontSizeMedium: CGFloat = 32          // Medium display
    static let fontSizeEmoji: CGFloat = 50           // Emoji displays
    static let fontSizeIcon: CGFloat = 24            // Icon sizing
    static let fontSizeTinyIcon: CGFloat = 6         // Tiny icons/indicators
    static let fontSizeTinyText: CGFloat = 7         // Very small text
    
    // MARK: - Spacing System
    
    // Base spacing unit (8pt grid system)
    static let spacingBase: CGFloat = 8
    
    // Spacing scale (multiples of base unit)
    static let spacingXXS: CGFloat = 2               // 2pt
    static let spacingXS: CGFloat = 4                // 4pt
    static let spacingSM: CGFloat = 8                // 8pt (1x base)
    static let spacingMD: CGFloat = 12               // 12pt (1.5x base)
    static let spacingLG: CGFloat = 16               // 16pt (2x base)
    static let spacingXL: CGFloat = 20               // 20pt (2.5x base)
    static let spacingXXL: CGFloat = 24              // 24pt (3x base)
    static let spacing3XL: CGFloat = 32              // 32pt (4x base)
    static let spacing4XL: CGFloat = 40              // 40pt (5x base)
    static let spacing5XL: CGFloat = 48              // 48pt (6x base)
    
    // Common spacing values that don't fit the grid perfectly
    static let spacing5: CGFloat = 5                 // Small gap
    static let spacing6: CGFloat = 6                 // Small gap
    static let spacing10: CGFloat = 10               // Medium gap
    static let spacing18: CGFloat = 18               // Specific use cases
    
    // MARK: - Layout Constants
    
    //  Golden Ratio Constants
    static let goldenRatio: CGFloat = 1.618
    static let goldenRatioInverse: CGFloat = 0.618
    
    // Card proportions using golden ratio
    static let cardHorizontalPadding: CGFloat = 20
    static let cardVerticalSpacing: CGFloat = 12 // Golden ratio relationship to padding
    static let cardCornerRadius: CGFloat = 16
    static let cardImageSize: CGFloat = 70
    
    // Corner radii for different UI elements
    static let cornerRadiusXS: CGFloat = 4
    static let cornerRadiusSM: CGFloat = 8
    static let cornerRadiusMD: CGFloat = 12
    static let cornerRadiusLG: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 20
    static let cornerRadiusXXL: CGFloat = 24
    static let cornerRadiusPill: CGFloat = 999      // Fully rounded pill shape
    
    // Common dimension values
    static let iconSizeSmall: CGFloat = 20
    static let iconSizeMedium: CGFloat = 24
    static let iconSizeLarge: CGFloat = 28
    static let iconSizeXLarge: CGFloat = 32
    
    static let buttonHeight: CGFloat = 44            // Minimum touch target
    static let buttonHeightCompact: CGFloat = 36
    static let buttonHeightLarge: CGFloat = 52
    
    // Shadow values
    static let shadowRadiusSmall: CGFloat = 2
    static let shadowRadiusMedium: CGFloat = 4
    static let shadowRadiusLarge: CGFloat = 8
    static let shadowRadiusXL: CGFloat = 12
    
    static let shadowOffsetSmall: CGFloat = 1
    static let shadowOffsetMedium: CGFloat = 2
    static let shadowOffsetLarge: CGFloat = 4
    
    // Gradient cache
    nonisolated(unsafe) private static var gradientCache: [String: LinearGradient] = [:]
    
    private static func cacheKey(theme: ThemeType, colorScheme: ColorScheme) -> String {
        return "\(theme.rawValue)-\(colorScheme == .dark ? "dark" : "light")"
    }
    
    // Theme Options
    enum ThemeType: String, CaseIterable, Identifiable {
        case teal = "Teal"
        case purple = "Purple"
        case red = "Red"
        case orange = "Orange"
        case yellow = "Yellow"
        case green = "Green"
        case pink = "Pink"
        case gold = "Gold"
        
        var id: String { rawValue }
    }
    
    // Shared blue undertone (used in teal and purple)
    private static let blueUndertone = Color(red: 59/255, green: 130/255, blue: 246/255)    // Medium Blue
    private static let lightBlueUndertone = Color(red: 96/255, green: 165/255, blue: 250/255) // Light Blue
    
    // 1. Teal Theme - Darker teal for light mode, even darker ocean for dark mode
    // Frost Light mode colors (the darker teal version)
    private static let tealBrightLight = Color(red: 20/255, green: 184/255, blue: 166/255)   // Bright Teal
    private static let tealMediumLight = Color(red: 45/255, green: 155/255, blue: 180/255)   // Medium Teal-Blue
    private static let tealDeepLight = Color(red: 59/255, green: 130/255, blue: 246/255)     // Deep Ocean Blue
    private static let tealRichLight = Color(red: 67/255, green: 97/255, blue: 238/255)      // Rich Royal Blue
    
    // Fire Dark mode colors (even darker ocean teal)
    private static let tealBrightDark = Color(red: 15/255, green: 120/255, blue: 110/255)    // Dark Teal
    private static let tealMediumDark = Color(red: 25/255, green: 95/255, blue: 120/255)     // Dark Teal-Blue
    private static let tealDeepDark = Color(red: 30/255, green: 70/255, blue: 150/255)       // Deep Dark Ocean
    private static let tealRichDark = Color(red: 35/255, green: 50/255, blue: 130/255)       // Rich Dark Blue
    
    // 2. Purple Theme - Rich Purple to Electric Teal (enhanced vibrancy)
    private static let purpleRich = Color(red: 131/255, green: 58/255, blue: 180/255)       // Rich Purple
    private static let purpleVibrant = Color(red: 108/255, green: 75/255, blue: 210/255)    // Vibrant Purple-Blue
    private static let purpleDeep = Color(red: 88/255, green: 86/255, blue: 214/255)        // Deep Violet-Blue
    private static let purpleTeal = Color(red: 64/255, green: 224/255, blue: 208/255)       // Electric Teal
    
    // 3. Red Theme - Deep Crimson to Burnt Sienna (enhanced warmth)
    private static let redCrimson = Color(red: 139/255, green: 0/255, blue: 0/255)          // Deep Crimson
    private static let redWarm = Color(red: 178/255, green: 34/255, blue: 34/255)           // Warm Red
    private static let redBurnt = Color(red: 204/255, green: 85/255, blue: 0/255)           // Burnt Sienna
    private static let redOrange = Color(red: 230/255, green: 81/255, blue: 0/255)          // Deep Red-Orange
    
    // 4. Orange Theme - Bright Tangerine to Deep Coral (REFERENCE - keep as is)
    private static let orangeBright = Color(red: 251/255, green: 146/255, blue: 60/255)     // Bright Tangerine
    private static let orangeWarm = Color(red: 255/255, green: 127/255, blue: 80/255)       // Coral Orange
    private static let coralDeep = Color(red: 220/255, green: 94/255, blue: 75/255)         // Deep Coral
    private static let coralRich = Color(red: 183/255, green: 65/255, blue: 84/255)         // Rich Coral-Red
    
    // 5. Yellow Theme - Bright Sunshine to Deep Amber (enhanced richness)
    private static let yellowBright = Color(red: 255/255, green: 214/255, blue: 10/255)     // Bright Sunshine
    private static let yellowGold = Color(red: 255/255, green: 193/255, blue: 7/255)        // Golden Yellow
    private static let yellowAmber = Color(red: 255/255, green: 160/255, blue: 0/255)       // Warm Amber
    private static let yellowDeep = Color(red: 230/255, green: 126/255, blue: 34/255)       // Deep Amber-Orange
    
    // 6. Green Theme - Vibrant Emerald to Deep Ocean (enhanced depth)
    private static let greenVibrant = Color(red: 16/255, green: 185/255, blue: 129/255)     // Vibrant Emerald
    private static let greenMedium = Color(red: 34/255, green: 197/255, blue: 94/255)       // Fresh Green
    private static let greenTeal = Color(red: 20/255, green: 184/255, blue: 166/255)        // Green-Teal
    private static let greenDeep = Color(red: 59/255, green: 130/255, blue: 246/255)        // Deep Ocean
    
    // 7. Pink Theme - Hot Pink to Purple-Blue (enhanced drama)
    private static let pinkHot = Color(red: 236/255, green: 72/255, blue: 153/255)          // Hot Pink
    private static let pinkVibrant = Color(red: 219/255, green: 39/255, blue: 119/255)      // Vibrant Magenta
    private static let pinkPurple = Color(red: 168/255, green: 85/255, blue: 247/255)       // Pink-Purple
    private static let pinkBlue = Color(red: 96/255, green: 165/255, blue: 250/255)         // Purple-Blue
    
    // 8. Gold Theme - Brilliant Gold to Velvety Black (enhanced luxury)
    private static let goldBrilliant = Color(red: 255/255, green: 223/255, blue: 0/255)     // Brilliant Gold
    private static let goldShiny = Color(red: 255/255, green: 215/255, blue: 77/255)        // Shiny Gold
    private static let goldRich = Color(red: 212/255, green: 175/255, blue: 55/255)         // Rich Gold
    private static let silverCool = Color(red: 192/255, green: 192/255, blue: 192/255)      // Cool Silver ✨
    private static let goldBronze = Color(red: 139/255, green: 90/255, blue: 43/255)        // Bronze
    private static let goldCharcoal = Color(red: 45/255, green: 45/255, blue: 45/255)       // Deep Charcoal
    private static let goldBlack = Color(red: 15/255, green: 15/255, blue: 15/255)          // Velvety Black
    
    // MARK: - Starling-Inspired Eye-Friendly Colors
    
    // Soft background colors (dark toned, easy on eyes)
    static let cardBackground = Color.white.opacity(0.95)
    static let cardBackgroundDark = Color(red: 28/255, green: 28/255, blue: 30/255) // Softer dark background
    
    // Elevated card backgrounds (slightly lighter for depth)
    static let elevatedCardLight = Color.white
    static let elevatedCardDark = Color(red: 38/255, green: 38/255, blue: 40/255) // Soft elevated surface
    
    // Secondary background (for sections, grouped content)
    static let secondaryBackgroundLight = Color(red: 242/255, green: 242/255, blue: 247/255)
    static let secondaryBackgroundDark = Color(red: 18/255, green: 18/255, blue: 20/255) // Deeper background
    
    // Text colors (optimized for readability)
    static let primaryText = Color.primary // Adaptive
    static let secondaryText = Color(red: 142/255, green: 142/255, blue: 147/255) // Softer gray
    static let tertiaryText = Color(red: 99/255, green: 99/255, blue: 102/255) // Even softer
    
    // Status colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    // Dividers and borders (subtle, not harsh)
    static let dividerColor = Color(red: 60/255, green: 60/255, blue: 67/255).opacity(0.36)
    static let borderColor = Color(red: 72/255, green: 72/255, blue: 74/255)
    
    // Shadows and overlays
    static let shadowColor = Color.black.opacity(0.08) // Subtle shadow
    static let overlayColor = Color.black.opacity(0.4) // For modals/sheets
    
    // MARK: - Design Tokens (Opacity & Dimensions)
    
    // Opacity values for consistent transparency
    static let cardDarkOpacity: Double = 0.15 // Dark mode card backgrounds
    static let cardDarkMediumOpacity: Double = 0.2 // Dark mode medium backgrounds (search bars, inputs)
    static let cardLightOpacity: Double = 0.9 // Light mode card backgrounds
    static let cardLightHighOpacity: Double = 0.95 // Light mode elevated cards
    static let glassLightOpacity: Double = 0.5 // Glassmorphism light backgrounds
    static let dividerOpacity: Double = 0.1 // Divider/border transparency
    static let overlayLightOpacity: Double = 0.2 // Light overlay backgrounds
    static let shadowLightOpacity: Double = 0.1 // Light mode shadows
    static let shadowDarkOpacity: Double = 0.3 // Dark mode shadows
    
    // Text/Icon emphasis levels (for foreground colors)
    static let highEmphasisOpacity: Double = 0.8 // High emphasis (important secondary text)
    static let mediumEmphasisOpacity: Double = 0.6 // Medium emphasis (tertiary text)
    static let lowEmphasisOpacity: Double = 0.4 // Low emphasis (disabled/placeholder)
    static let cardHighEmphasisLightOpacity: Double = 0.75 // Card-specific high emphasis text (light mode)
    
    // MARK: - Dynamic Color Helpers (Starling-Style)
    
    /// Returns appropriate card background based on color scheme
    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? cardBackgroundDark : cardBackground
    }
    
    /// Returns elevated card background (slightly lighter than base)
    static func elevatedCard(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? elevatedCardDark : elevatedCardLight
    }
    
    /// Returns secondary background for grouped content
    static func secondaryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? secondaryBackgroundDark : secondaryBackgroundLight
    }
    
    /// Returns adaptive text color based on color scheme
    static func textColor(for colorScheme: ColorScheme, opacity: Double = 1.0) -> Color {
        let baseColor = colorScheme == .dark ? Color.white : Color.black
        return opacity == 1.0 ? baseColor : baseColor.opacity(opacity)
    }
    
    // MARK: - Adaptive Background Helpers
    
    /// Standard adaptive card background (most common pattern)
    static func adaptiveCard(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: cardDarkOpacity) : Color.white.opacity(cardLightOpacity)
    }
    
    /// Medium opacity card background (for search bars, inputs)
    static func adaptiveCardMedium(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: cardDarkMediumOpacity) : Color.white.opacity(cardLightOpacity)
    }
    
    /// High opacity card background (for elevated/prominent cards)
    static func adaptiveCardHigh(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: cardDarkOpacity) : Color.white.opacity(cardLightHighOpacity)
    }
    
    /// Glass effect background (lighter, more transparent)
    static func adaptiveGlass(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(white: cardDarkOpacity) : Color.white.opacity(glassLightOpacity)
    }
    
    /// Adaptive shadow color
    static func adaptiveShadow(for colorScheme: ColorScheme) -> Color {
        Color.black.opacity(colorScheme == .dark ? shadowDarkOpacity : shadowLightOpacity)
    }
    
    /// Dimmed filter/chip background (commonly used in FilterChip, overlays)
    static func adaptiveFilterChip(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color(white: cardDarkMediumOpacity).opacity(highEmphasisOpacity) 
            : Color(white: cardLightOpacity).opacity(cardLightOpacity)
    }
    
    /// Adaptive text/icon color with emphasis levels
    static func adaptiveEmphasis(for colorScheme: ColorScheme, level: Double = 1.0) -> Color {
        colorScheme == .dark ? Color.white.opacity(level) : Color.black.opacity(level)
    }
    
    /// High emphasis text/icon (0.8 opacity for secondary important elements)
    static func adaptiveHighEmphasis(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(highEmphasisOpacity) : Color.black.opacity(mediumEmphasisOpacity)
    }
    
    /// Medium emphasis text/icon (0.6 opacity for tertiary elements)
    static func adaptiveMediumEmphasis(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(mediumEmphasisOpacity) : Color.black.opacity(lowEmphasisOpacity)
    }
    
    /// Custom emphasis for secondary indicators (chevrons, arrows, etc) - 0.5 dark / 0.4 light
    static func adaptiveSecondaryIndicator(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(glassLightOpacity) : Color.black.opacity(lowEmphasisOpacity)
    }
    
    /// Medium-high emphasis for subtitles (0.7 dark / 0.6 light)
    static func adaptiveSubtitle(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.black.opacity(mediumEmphasisOpacity)
    }
    
    /// Card-specific high emphasis text (time, difficulty labels) - 0.95 dark / 0.75 light
    static func adaptiveCardTextEmphasis(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark 
            ? Color.white.opacity(cardLightHighOpacity) 
            : Color.black.opacity(cardHighEmphasisLightOpacity)
    }
    
    // Dynamic accent color based on theme
    static func accentColor(for theme: ThemeType) -> Color {
        switch theme {
        case .teal:     return tealBrightLight  // Use light teal for accent
        case .purple:   return purpleRich
        case .red:      return redCrimson
        case .orange:   return orangeBright
        case .yellow:   return yellowBright
        case .green:    return greenVibrant
        case .pink:     return pinkHot
        case .gold:     return goldRich
        }
    }
    
    // Computed property for environment-based access
    static var accentColor: Color {
        return tealBrightLight // Teal default
    }
    
    static func backgroundGradient(for theme: ThemeType, colorScheme: ColorScheme) -> LinearGradient {
        // Check cache first (performance optimization)
        let key = cacheKey(theme: theme, colorScheme: colorScheme)
        if let cached = gradientCache[key] {
            return cached
        }
        
        // Use system color scheme directly
        // Light mode = Frost Light (bright gradients)
        // Dark mode = Ember Dark (dark gradients)
        let useDarkColors = (colorScheme == .dark)
        
        let gradient: LinearGradient
        
        switch theme {
        case .teal:
            gradient = LinearGradient(
                gradient: Gradient(colors: useDarkColors ? 
                    // Dark mode: Softer, more subtle teal (Starling-inspired)
                    [
                        tealBrightDark.opacity(0.7),
                        tealMediumDark.opacity(0.6),
                        tealDeepDark.opacity(0.5),
                        Color(red: 25/255, green: 25/255, blue: 28/255) // Very dark base
                    ] :
                    // Light mode/Frost Light: Bright teal
                    [tealBrightLight, tealMediumLight, tealDeepLight, tealRichLight]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .purple:
            gradient = LinearGradient(
                gradient: Gradient(colors: useDarkColors ?
                    [
                        purpleRich.opacity(0.5),
                        purpleVibrant.opacity(0.4),
                        purpleDeep.opacity(0.35),
                        Color(red: 22/255, green: 22/255, blue: 25/255)
                    ] :
                    [purpleRich, purpleVibrant, purpleDeep, purpleTeal]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .red:
            gradient = LinearGradient(
                gradient: Gradient(colors: useDarkColors ?
                    [
                        redCrimson.opacity(0.5),
                        redWarm.opacity(0.4),
                        redBurnt.opacity(0.35),
                        Color(red: 28/255, green: 20/255, blue: 20/255)
                    ] :
                    [redCrimson, redWarm, redBurnt, redOrange]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .orange:
            gradient = LinearGradient(
                gradient: Gradient(colors: useDarkColors ?
                    [
                        orangeBright.opacity(0.4),
                        orangeWarm.opacity(0.35),
                        coralDeep.opacity(0.4),
                        Color(red: 30/255, green: 25/255, blue: 22/255)
                    ] :
                    [orangeBright, orangeWarm, coralDeep, coralRich]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .yellow:
            gradient = LinearGradient(
                gradient: Gradient(colors: useDarkColors ?
                    [
                        yellowGold.opacity(0.3),
                        yellowAmber.opacity(0.35),
                        yellowDeep.opacity(0.4),
                        Color(red: 35/255, green: 30/255, blue: 22/255)
                    ] :
                    [yellowBright, yellowGold, yellowAmber, yellowDeep]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .green:
            gradient = LinearGradient(
                gradient: Gradient(colors: useDarkColors ?
                    [
                        greenVibrant.opacity(0.4),
                        greenMedium.opacity(0.35),
                        greenTeal.opacity(0.4),
                        Color(red: 20/255, green: 28/255, blue: 25/255)
                    ] :
                    [greenVibrant, greenMedium, greenTeal, greenDeep]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pink:
            gradient = LinearGradient(
                gradient: Gradient(colors: useDarkColors ?
                    [
                        pinkHot.opacity(0.4),
                        pinkVibrant.opacity(0.35),
                        pinkPurple.opacity(0.35),
                        Color(red: 25/255, green: 22/255, blue: 28/255)
                    ] :
                    [pinkHot, pinkVibrant, pinkPurple, pinkBlue]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .gold:
            gradient = LinearGradient(
                gradient: Gradient(colors: useDarkColors ?
                    [
                        goldRich.opacity(0.3),
                        goldBronze.opacity(0.4),
                        goldCharcoal.opacity(0.8),
                        Color(red: 18/255, green: 18/255, blue: 18/255) // Near black
                    ] :
                    [goldBrilliant, goldShiny, goldRich, silverCool, goldBronze, goldCharcoal, goldBlack]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        // Cache the gradient before returning (performance optimization)
        gradientCache[key] = gradient
        return gradient
    }
}

// View Extension for Theme Access
extension View {
    var themeAccentColor: Color {
        AppTheme.accentColor
    }
    
    /// Adaptive foreground color modifier - automatically adjusts for light/dark mode
    nonisolated func adaptiveForegroundColor(opacity: Double = 1.0) -> some View {
        modifier(AdaptiveForegroundColorModifier(opacity: opacity))
    }
}

// ViewModifier for adaptive text color
private struct AdaptiveForegroundColorModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let opacity: Double
    
    func body(content: Content) -> some View {
        content.foregroundColor(AppTheme.textColor(for: colorScheme, opacity: opacity))
    }
}
