 import SwiftUI

private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppTheme.ThemeType = .teal
}

extension EnvironmentValues {
    var appTheme: AppTheme.ThemeType {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

enum AppTheme {
    
    static let fontSize4: CGFloat = 4
    static let fontSize6: CGFloat = 6
    static let fontSize7: CGFloat = 7
    static let fontSize8: CGFloat = 8
    static let fontSize10: CGFloat = 10
    static let fontSize11: CGFloat = 11
    static let fontSize12: CGFloat = 12
    static let fontSize13: CGFloat = 13
    static let fontSize14: CGFloat = 14
    static let fontSize15: CGFloat = 15
    static let fontSize16: CGFloat = 16
    static let fontSize17: CGFloat = 17
    static let fontSize18: CGFloat = 18
    static let fontSize20: CGFloat = 20
    static let fontSize22: CGFloat = 22
    static let fontSize24: CGFloat = 24
    static let fontSize28: CGFloat = 28
    static let fontSize32: CGFloat = 32
    static let fontSize34: CGFloat = 34
    static let fontSize36: CGFloat = 36
    static let fontSize38: CGFloat = 38
    static let fontSize42: CGFloat = 42
    static let fontSize50: CGFloat = 50
    static let fontSize55: CGFloat = 55
    static let fontSize60: CGFloat = 60
    static let fontSize75: CGFloat = 75
    static let fontSize80: CGFloat = 80
    
    static let spacingBase: CGFloat = 8
    
    static let spacing2: CGFloat = 2
    static let spacing3: CGFloat = 3
    static let spacing4: CGFloat = 4
    static let spacing5: CGFloat = 5
    static let spacing6: CGFloat = 6
    static let spacing8: CGFloat = 8
    static let spacing10: CGFloat = 10
    static let spacing12: CGFloat = 12
    static let spacing14: CGFloat = 14
    static let spacing16: CGFloat = 16
    static let spacing18: CGFloat = 18
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    static let spacing40: CGFloat = 40
    static let spacing42: CGFloat = 42
    static let spacing48: CGFloat = 48
    static let spacing50: CGFloat = 50
    static let spacing60: CGFloat = 60
    static let spacing62: CGFloat = 62
    static let spacing86: CGFloat = 86
    static let spacing100: CGFloat = 100
    
    static let goldenRatio: CGFloat = 1.618
    static let goldenRatioInverse: CGFloat = 0.618
    
    static let cardHorizontalPadding: CGFloat = 20
    static let cardVerticalSpacing: CGFloat = 12
    static let cardCornerRadius: CGFloat = 16
    static let cardImageSize: CGFloat = 70
    
    static let cornerRadius3: CGFloat = 3
    static let cornerRadius4: CGFloat = 4
    static let cornerRadius6: CGFloat = 6
    static let cornerRadius8: CGFloat = 8
    static let cornerRadius10: CGFloat = 10
    static let cornerRadius12: CGFloat = 12
    static let cornerRadius14: CGFloat = 14
    static let cornerRadius16: CGFloat = 16
    static let cornerRadius18: CGFloat = 18
    static let cornerRadius20: CGFloat = 20
    static let cornerRadius24: CGFloat = 24
    static let cornerRadiusPill: CGFloat = 999
    
    static let iconSize18: CGFloat = 18
    static let iconSize20: CGFloat = 20
    static let iconSize24: CGFloat = 24
    static let iconSize28: CGFloat = 28
    static let iconSize32: CGFloat = 32
    static let iconSize40: CGFloat = 40
    static let iconSize48: CGFloat = 48
    
    static let height1: CGFloat = 1
    static let height4: CGFloat = 4
    static let height8: CGFloat = 8
    static let height12: CGFloat = 12
    static let height14: CGFloat = 14
    static let height16: CGFloat = 16
    static let height20: CGFloat = 20
    static let height24: CGFloat = 24
    static let height28: CGFloat = 28
    static let height34: CGFloat = 34
    static let height36: CGFloat = 36
    static let height40: CGFloat = 40
    static let height44: CGFloat = 44
    static let height48: CGFloat = 48
    static let height50: CGFloat = 50
    static let height54: CGFloat = 54
    static let height56: CGFloat = 56
    static let height60: CGFloat = 60
    static let height80: CGFloat = 80
    static let height100: CGFloat = 100
    static let height120: CGFloat = 120
    static let height140: CGFloat = 140
    static let height160: CGFloat = 160
    static let height180: CGFloat = 180
    static let height200: CGFloat = 200
    
    static let width29: CGFloat = 29
    static let width30: CGFloat = 30
    static let width60: CGFloat = 60
    static let width70: CGFloat = 70
    static let width80: CGFloat = 80
    static let width88: CGFloat = 88
    static let width100: CGFloat = 100
    static let width120: CGFloat = 120
    static let width140: CGFloat = 140
    static let width150: CGFloat = 150
    static let width200: CGFloat = 200
    static let width220: CGFloat = 220
    static let width250: CGFloat = 250
    
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

    static let blurRadiusHairline: CGFloat = 1
    static let blurRadiusTiny: CGFloat = 2
    static let blurRadiusHeavy: CGFloat = 30

    static let transitionScaleDown: Double = 0.95
    static let transitionScaleUp: Double = 1.05

    static let confettiCount: Int = 50
    static let confettiRadius: CGFloat = 500
    static let confettiRadiusSmall: CGFloat = 400

    static let buttonHeight: CGFloat = 44
    static let buttonHeightCompact: CGFloat = 36
    static let buttonHeightLarge: CGFloat = 52
    
    static let shadowRadiusSmall: CGFloat = 2
    static let shadowRadiusMedium: CGFloat = 4
    static let shadowRadiusLarge: CGFloat = 8
    static let shadowRadiusXL: CGFloat = 12
    
    static let shadowOffsetSmall: CGFloat = 1
    static let shadowOffsetMedium: CGFloat = 2
    static let shadowOffsetLarge: CGFloat = 4
    
    nonisolated(unsafe) private static var gradientCache: [String: LinearGradient] = [:]
    
    private static func cacheKey(theme: ThemeType, colorScheme: ColorScheme) -> String {
        return "\(theme.rawValue)-\(colorScheme == .dark ? "dark" : "light")"
    }
    
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
    
    private static let blueUndertone = Color(red: 59/255, green: 130/255, blue: 246/255)
    private static let lightBlueUndertone = Color(red: 96/255, green: 165/255, blue: 250/255)
    
    private static let tealBrightLight = Color(red: 20/255, green: 184/255, blue: 166/255)
    private static let tealMediumLight = Color(red: 45/255, green: 155/255, blue: 180/255)
    private static let tealDeepLight = Color(red: 59/255, green: 130/255, blue: 246/255)
    private static let tealRichLight = Color(red: 67/255, green: 97/255, blue: 238/255)
    
    private static let tealBrightDark = Color(red: 15/255, green: 120/255, blue: 110/255)
    private static let tealMediumDark = Color(red: 25/255, green: 95/255, blue: 120/255)
    private static let tealDeepDark = Color(red: 30/255, green: 70/255, blue: 150/255)
    private static let tealRichDark = Color(red: 35/255, green: 50/255, blue: 130/255)
    
    private static let purpleRich = Color(red: 131/255, green: 58/255, blue: 180/255)
    private static let purpleVibrant = Color(red: 108/255, green: 75/255, blue: 210/255)
    private static let purpleDeep = Color(red: 88/255, green: 86/255, blue: 214/255)
    private static let purpleTeal = Color(red: 64/255, green: 224/255, blue: 208/255)
    
    private static let redCrimson = Color(red: 139/255, green: 0/255, blue: 0/255)
    private static let redWarm = Color(red: 178/255, green: 34/255, blue: 34/255)
    private static let redBurnt = Color(red: 204/255, green: 85/255, blue: 0/255)
    private static let redOrange = Color(red: 230/255, green: 81/255, blue: 0/255)
    
    private static let orangeBright = Color(red: 251/255, green: 146/255, blue: 60/255)
    private static let orangeWarm = Color(red: 255/255, green: 127/255, blue: 80/255)
    private static let coralDeep = Color(red: 220/255, green: 94/255, blue: 75/255)
    private static let coralRich = Color(red: 183/255, green: 65/255, blue: 84/255)
    
    private static let yellowBright = Color(red: 255/255, green: 214/255, blue: 10/255)
    private static let yellowGold = Color(red: 255/255, green: 193/255, blue: 7/255)
    private static let yellowAmber = Color(red: 255/255, green: 160/255, blue: 0/255)
    private static let yellowDeep = Color(red: 230/255, green: 126/255, blue: 34/255)
    
    private static let greenVibrant = Color(red: 16/255, green: 185/255, blue: 129/255)
    private static let greenMedium = Color(red: 34/255, green: 197/255, blue: 94/255)
    private static let greenTeal = Color(red: 20/255, green: 184/255, blue: 166/255)
    private static let greenDeep = Color(red: 59/255, green: 130/255, blue: 246/255)
    
    private static let pinkHot = Color(red: 236/255, green: 72/255, blue: 153/255)
    private static let pinkVibrant = Color(red: 219/255, green: 39/255, blue: 119/255)
    private static let pinkPurple = Color(red: 168/255, green: 85/255, blue: 247/255)
    private static let pinkBlue = Color(red: 96/255, green: 165/255, blue: 250/255)
    
    private static let goldBrilliant = Color(red: 255/255, green: 223/255, blue: 0/255)
    private static let goldShiny = Color(red: 255/255, green: 215/255, blue: 77/255)
    private static let goldRich = Color(red: 212/255, green: 175/255, blue: 55/255)
    private static let silverCool = Color(red: 192/255, green: 192/255, blue: 192/255)
    private static let goldBronze = Color(red: 139/255, green: 90/255, blue: 43/255)
    private static let goldCharcoal = Color(red: 45/255, green: 45/255, blue: 45/255)
    private static let goldBlack = Color(red: 15/255, green: 15/255, blue: 15/255)
    
    static let cardBackground = Color.white.opacity(0.95)
    static let cardBackgroundDark = Color(red: 28/255, green: 28/255, blue: 30/255)
    
    static let elevatedCardLight = Color.white
    static let elevatedCardDark = Color(red: 38/255, green: 38/255, blue: 40/255)
    
    static let secondaryBackgroundLight = Color(red: 242/255, green: 242/255, blue: 247/255)
    static let secondaryBackgroundDark = Color(red: 18/255, green: 18/255, blue: 20/255)
    
    static let primaryText = Color.primary
    static let secondaryText = Color(red: 142/255, green: 142/255, blue: 147/255)
    static let tertiaryText = Color(red: 99/255, green: 99/255, blue: 102/255)
    
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    static let dividerColor = Color(red: 60/255, green: 60/255, blue: 67/255).opacity(0.36)
    static let borderColor = Color(red: 72/255, green: 72/255, blue: 74/255)
    
    static let shadowColor = Color.black.opacity(0.08)
    static let overlayColor = Color.black.opacity(0.4)
    
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
    static let highEmphasisOpacity: Double = 0.8
    static let mediumEmphasisOpacity: Double = 0.6
    static let subduedEmphasisOpacity: Double = 0.7
    static let disabledEmphasisOpacity: Double = 0.65
    static let lowEmphasisOpacity: Double = 0.4
    static let nearSolidOpacity: Double = 0.85
    static let veryHighEmphasisOpacity: Double = 0.9
    static let cardHighEmphasisLightOpacity: Double = 0.75
    static let bannerHeightRatio: Double = 0.18
    
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
    
    static func backgroundGradient(for theme: ThemeType, colorScheme: ColorScheme) -> LinearGradient {
        let key = cacheKey(theme: theme, colorScheme: colorScheme)
        if let cached = gradientCache[key] {
            return cached
        }
        
        let useDarkColors = (colorScheme == .dark)
        
        let gradient: LinearGradient
        
        switch theme {
        case .teal:
            gradient = LinearGradient(
                gradient: Gradient(colors: useDarkColors ? 
                    [
                        tealBrightDark.opacity(0.7),
                        tealMediumDark.opacity(0.6),
                        tealDeepDark.opacity(0.5),
                        Color(red: 25/255, green: 25/255, blue: 28/255)
                    ] :
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
                        Color(red: 18/255, green: 18/255, blue: 18/255)
                    ] :
                    [goldBrilliant, goldShiny, goldRich, silverCool, goldBronze, goldCharcoal, goldBlack]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        gradientCache[key] = gradient
        return gradient
    }
}

extension View {
    var themeAccentColor: Color {
        AppTheme.accentColor
    }
    
    nonisolated func adaptiveForegroundColor(opacity: Double = 1.0) -> some View {
        modifier(AdaptiveForegroundColorModifier(opacity: opacity))
    }
}

private struct AdaptiveForegroundColorModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let opacity: Double
    
    func body(content: Content) -> some View {
        content.foregroundColor(AppTheme.textColor(for: colorScheme, opacity: opacity))
    }
}
