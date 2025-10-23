//
//  AppTheme.swift
//  RecipeFinder
//
//  Created by asad.e.khan on 12/10/2025.
//
 import SwiftUI

// MARK: - Theme Environment Key
private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppTheme.ThemeType = .purple
}

extension EnvironmentValues {
    var appTheme: AppTheme.ThemeType {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// Theme Configuration
enum AppTheme {
    // Theme Options
    enum ThemeType: String, CaseIterable, Identifiable {
        case purple = "Purple"
        case teal = "Teal"
        
        var id: String { rawValue }
    }
    
    // Purple Theme (Original) - Purple to Blue gradient
    private static let purpleGradientStart = Color(red: 131/255, green: 58/255, blue: 180/255)
    private static let purpleGradientMiddle = Color(red: 88/255, green: 86/255, blue: 214/255)
    private static let purpleGradientEnd = Color(red: 64/255, green: 224/255, blue: 208/255)
    
    // Teal Theme (New) - Teal to Blue gradient
    private static let tealGradientStart = Color(red: 20/255, green: 184/255, blue: 166/255)     // Bright Teal
    private static let tealGradientMiddle = Color(red: 59/255, green: 130/255, blue: 246/255)    // Medium Blue
    private static let tealGradientEnd = Color(red: 96/255, green: 165/255, blue: 250/255)       // Light Blue
    
    static let cardBackground = Color.white.opacity(0.95)
    static let cardBackgroundDark = Color(white: 0.15)
    static let secondaryText = Color.gray
    static let dividerColor = Color.gray.opacity(0.3)
    
    // Dynamic accent color based on theme
    static func accentColor(for theme: ThemeType) -> Color {
        switch theme {
        case .purple:
            return purpleGradientStart
        case .teal:
            return tealGradientStart
        }
    }
    
    // Computed property for environment-based access
    static var accentColor: Color {
        // This will be overridden by environment access in views
        return purpleGradientStart
    }
    
    static func backgroundGradient(for theme: ThemeType, colorScheme: ColorScheme) -> LinearGradient {
        switch theme {
        case .purple:
            return LinearGradient(
                colors: [purpleGradientStart, purpleGradientMiddle, purpleGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .teal:
            return LinearGradient(
                colors: [tealGradientStart, tealGradientMiddle, tealGradientEnd],
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
