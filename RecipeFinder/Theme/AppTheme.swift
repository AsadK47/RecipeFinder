//
//  AppTheme.swift
//  RecipeFinder
//
//  Created by asad.e.khan on 12/10/2025.
//
 import SwiftUI

// MARK: - Theme Configuration
struct AppTheme {
    // Purple to Blue to Teal gradient
    static let gradientStart = Color(red: 131/255, green: 58/255, blue: 180/255) // Purple
    static let gradientMiddle = Color(red: 88/255, green: 86/255, blue: 214/255) // Blue-Purple
    static let gradientEnd = Color(red: 64/255, green: 224/255, blue: 208/255) // Turquoise/Teal
    
    static let cardBackground = Color.white.opacity(0.95)
    static let cardBackgroundDark = Color(white: 0.15)
    static let accentColor = Color(red: 131/255, green: 58/255, blue: 180/255)
    static let secondaryText = Color.gray
    static let dividerColor = Color.gray.opacity(0.3)
    
    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientMiddle, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
