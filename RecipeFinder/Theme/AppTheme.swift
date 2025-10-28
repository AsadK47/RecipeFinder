//
//  AppTheme.swift
//  RecipeFinder
//
//  Created by asad.e.khan on 12/10/2025.
//
 import SwiftUI

// MARK: - Theme Environment Key
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
    // MARK: - Golden Ratio Constants
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
    
    // 1. Teal Theme (DEFAULT)
    private static let tealStart = Color(red: 20/255, green: 184/255, blue: 166/255)        // Bright Teal
    
    // 2. Purple Theme
    private static let purpleStart = Color(red: 131/255, green: 58/255, blue: 180/255)      // Rich Purple
    private static let purpleMiddle = Color(red: 88/255, green: 86/255, blue: 214/255)      // Deep Blue
    private static let purpleEnd = Color(red: 64/255, green: 224/255, blue: 208/255)        // Turquoise
    
    // 3. Red Theme - Deep Red to Deep Orange (velvety hues)
    private static let redDeep = Color(red: 139/255, green: 0/255, blue: 0/255)             // Deep Velvety Red
    private static let redBurnt = Color(red: 178/255, green: 34/255, blue: 34/255)          // Burnt Red
    private static let orangeRust = Color(red: 204/255, green: 85/255, blue: 0/255)         // Rustic Orange
    private static let orangeDeep = Color(red: 230/255, green: 81/255, blue: 0/255)         // Deep Velvety Orange
    
    // 4. Orange Theme - Bright Orange to Deep Coral
    private static let orangeBright = Color(red: 251/255, green: 146/255, blue: 60/255)     // Bright Orange
    private static let orangeWarm = Color(red: 255/255, green: 127/255, blue: 80/255)       // Coral Orange
    private static let coralDeep = Color(red: 220/255, green: 94/255, blue: 75/255)         // Deep Coral
    private static let coralRich = Color(red: 183/255, green: 65/255, blue: 84/255)         // Rich Coral-Red
    
    // 5. Yellow Theme - Sunny Yellow to Amber
    private static let yellowSunny = Color(red: 250/255, green: 204/255, blue: 21/255)      // Sunny Yellow
    private static let yellowGold = Color(red: 255/255, green: 193/255, blue: 7/255)        // Golden Yellow
    private static let amberWarm = Color(red: 255/255, green: 160/255, blue: 0/255)         // Warm Amber
    private static let amberDeep = Color(red: 230/255, green: 126/255, blue: 34/255)        // Deep Amber
    
    // 6. Green Theme - Green to Blue undertone
    private static let greenStart = Color(red: 34/255, green: 197/255, blue: 94/255)        // Fresh Green
    
    // 7. Pink Theme - Pink to Blue undertone
    private static let pinkStart = Color(red: 236/255, green: 72/255, blue: 153/255)        // Hot Pink
    
    // 8. Gold Theme - Sparkly Gold to Velvety Black (with cool silver accent line)
    private static let goldSparkle = Color(red: 255/255, green: 223/255, blue: 0/255)       // Sparkly Gold
    private static let goldShiny = Color(red: 255/255, green: 215/255, blue: 77/255)        // Shiny Gold
    private static let goldRich = Color(red: 212/255, green: 175/255, blue: 55/255)         // Rich Gold
    private static let silverCool = Color(red: 192/255, green: 192/255, blue: 192/255)      // Cool Silver Accent ✨
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
        case .teal:     return tealStart
        case .purple:   return purpleStart
        case .red:      return redDeep
        case .orange:   return orangeBright
        case .yellow:   return yellowSunny
        case .green:    return greenStart
        case .pink:     return pinkStart
        case .gold:     return goldRich
        }
    }
    
    // Computed property for environment-based access
    static var accentColor: Color {
        return tealStart // Teal default
    }
    
    static func backgroundGradient(for theme: ThemeType, colorScheme: ColorScheme) -> LinearGradient {
        switch theme {
        case .teal:
            return LinearGradient(
                colors: [tealStart, blueUndertone, lightBlueUndertone],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .purple:
            return LinearGradient(
                colors: [purpleStart, purpleMiddle, purpleEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .red:
            return LinearGradient(
                colors: [redDeep, redBurnt, orangeRust, orangeDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .orange:
            return LinearGradient(
                colors: [orangeBright, orangeWarm, coralDeep, coralRich],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .yellow:
            return LinearGradient(
                colors: [yellowSunny, yellowGold, amberWarm, amberDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .green:
            return LinearGradient(
                colors: [greenStart, blueUndertone, lightBlueUndertone],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pink:
            return LinearGradient(
                colors: [pinkStart, blueUndertone, lightBlueUndertone],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .gold:
            return LinearGradient(
                colors: [goldSparkle, goldShiny, goldRich, silverCool, goldBronze, goldCharcoal, goldBlack],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - View Extension for Theme Access
extension View {
    var themeAccentColor: Color {
        AppTheme.accentColor
    }
}
