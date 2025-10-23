//
//  AppTheme.swift
//  RecipeFinder
//
//  Created by asad.e.khan on 12/10/2025.
//
 import SwiftUI

// Theme Configuration
enum AppTheme {
    // Theme Options
    enum ThemeType: String, CaseIterable, Identifiable {
        case purple = "Purple"
        case teal = "Teal"
        
        var id: String { rawValue }
    }
    
    // Current theme (can be made @AppStorage for persistence)
    static var currentTheme: ThemeType = .purple
    
    // Purple Theme (Original)
    private static let purpleGradientStart = Color(red: 131/255, green: 58/255, blue: 180/255)
    private static let purpleGradientMiddle = Color(red: 88/255, green: 86/255, blue: 214/255)
    private static let purpleGradientEnd = Color(red: 64/255, green: 224/255, blue: 208/255)
    
    // Teal Theme (New)
    private static let tealGradientStart = Color(red: 20/255, green: 184/255, blue: 166/255) // Teal
    private static let tealGradientMiddle = Color(red: 56/255, green: 178/255, blue: 172/255) // Medium Teal
    private static let tealGradientEnd = Color(red: 72/255, green: 209/255, blue: 204/255) // Light Teal
    
    static let cardBackground = Color.white.opacity(0.95)
    static let cardBackgroundDark = Color(white: 0.15)
    static let secondaryText = Color.gray
    static let dividerColor = Color.gray.opacity(0.3)
    
    // Dynamic accent color based on theme
    static var accentColor: Color {
        switch currentTheme {
        case .purple:
            return purpleGradientStart
        case .teal:
            return tealGradientStart
        }
    }
    
    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        switch currentTheme {
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
