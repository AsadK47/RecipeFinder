import SwiftUI

/// Per-theme background gradients, cached because `backgroundGradient` is read from every screen's `body` on each render/tab switch.
extension AppTheme {

    private static let gradientCache = MemoCache<String, LinearGradient>(maxSize: AppTheme.ThemeType.allCases.count * 2)

    static func backgroundGradient(for theme: ThemeType, colorScheme: ColorScheme) -> LinearGradient {
        let cacheKey = "\(theme.rawValue)-\(colorScheme == .dark ? "dark" : "light")"
        return gradientCache.value(for: cacheKey) { _ in
            buildBackgroundGradient(for: theme, colorScheme: colorScheme)
        }
    }

    private static func buildBackgroundGradient(for theme: ThemeType, colorScheme: ColorScheme) -> LinearGradient {
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
        
        return gradient
    }
}
