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
    //  Golden Ratio Constants
    static let goldenRatio: CGFloat = 1.618
    static let goldenRatioInverse: CGFloat = 0.618
    
    // Card proportions using golden ratio
    static let cardHorizontalPadding: CGFloat = 20
    static let cardVerticalSpacing: CGFloat = 12 // Golden ratio relationship to padding
    static let cardCornerRadius: CGFloat = 16
    static let cardImageSize: CGFloat = 70
    
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
    
    static let cardBackground = Color.white.opacity(0.95)
    static let cardBackgroundDark = Color(white: 0.15)
    static let secondaryText = Color.gray
    static let dividerColor = Color.gray.opacity(0.3)
    
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
    
    static func backgroundGradient(for theme: ThemeType, colorScheme: ColorScheme, cardStyle: CardStyle? = nil) -> LinearGradient {
        // Determine if we should use dark colors based on either:
        // 1. The cardStyle (if provided) - .solid = dark, .frosted = light
        // 2. The system colorScheme (if cardStyle not provided)
        let useDarkColors: Bool
        if let cardStyle = cardStyle {
            useDarkColors = (cardStyle == .solid)
        } else {
            useDarkColors = (colorScheme == .dark)
        }
        
        switch theme {
        case .teal:
            return LinearGradient(
                gradient: Gradient(colors: useDarkColors ? 
                    // Dark mode/Fire Dark: New darker ocean teal
                    [tealBrightDark, tealMediumDark, tealDeepDark, tealRichDark] :
                    // Light mode/Frost Light: Original bright teal
                    [tealBrightLight, tealMediumLight, tealDeepLight, tealRichLight]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .purple:
            return LinearGradient(
                gradient: Gradient(colors: useDarkColors ?
                    [purpleRich.opacity(0.6), purpleVibrant.opacity(0.5), purpleDeep.opacity(0.5), Color(red: 30/255, green: 40/255, blue: 80/255)] :
                    [purpleRich, purpleVibrant, purpleDeep, purpleTeal]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .red:
            return LinearGradient(
                gradient: Gradient(colors: useDarkColors ?
                    [redCrimson.opacity(0.6), redWarm.opacity(0.5), redBurnt.opacity(0.5), Color(red: 60/255, green: 20/255, blue: 20/255)] :
                    [redCrimson, redWarm, redBurnt, redOrange]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .orange:
            return LinearGradient(
                gradient: Gradient(colors: useDarkColors ?
                    [orangeBright.opacity(0.5), orangeWarm.opacity(0.5), coralDeep.opacity(0.6), Color(red: 60/255, green: 30/255, blue: 30/255)] :
                    [orangeBright, orangeWarm, coralDeep, coralRich]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .yellow:
            return LinearGradient(
                gradient: Gradient(colors: useDarkColors ?
                    [yellowGold.opacity(0.4), yellowAmber.opacity(0.5), yellowDeep.opacity(0.6), Color(red: 80/255, green: 50/255, blue: 20/255)] :
                    [yellowBright, yellowGold, yellowAmber, yellowDeep]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .green:
            return LinearGradient(
                gradient: Gradient(colors: useDarkColors ?
                    [greenVibrant.opacity(0.5), greenMedium.opacity(0.5), greenTeal.opacity(0.6), Color(red: 20/255, green: 50/255, blue: 60/255)] :
                    [greenVibrant, greenMedium, greenTeal, greenDeep]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pink:
            return LinearGradient(
                gradient: Gradient(colors: useDarkColors ?
                    [pinkHot.opacity(0.5), pinkVibrant.opacity(0.5), pinkPurple.opacity(0.5), Color(red: 40/255, green: 30/255, blue: 70/255)] :
                    [pinkHot, pinkVibrant, pinkPurple, pinkBlue]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .gold:
            return LinearGradient(
                gradient: Gradient(colors: useDarkColors ?
                    [goldRich.opacity(0.4), goldBronze.opacity(0.6), goldCharcoal, goldBlack] :
                    [goldBrilliant, goldShiny, goldRich, silverCool, goldBronze, goldCharcoal, goldBlack]
                ),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// View Extension for Theme Access
extension View {
    var themeAccentColor: Color {
        AppTheme.accentColor
    }
}
