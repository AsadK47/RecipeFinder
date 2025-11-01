//
//  ThemeManager.swift
//  RecipeFinder
//
//  Created by GitHub Copilot on 11/01/2025.
//

import SwiftUI
import Combine

/// Centralized theme manager that controls app-wide theme and card style settings
/// Use as @EnvironmentObject to access throughout the app
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("appTheme") var selectedTheme: AppTheme.ThemeType = .teal {
        didSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("cardStyle") var cardStyle: CardStyle = .frosted {
        didSet {
            objectWillChange.send()
        }
    }
    
    @AppStorage("appearanceMode") var appearanceMode: AppearanceMode = .system {
        didSet {
            objectWillChange.send()
        }
    }
    
    private init() {}
    
    /// Get the appropriate card background based on current card style and color scheme
    func cardBackground(for colorScheme: ColorScheme) -> some ShapeStyle {
        if cardStyle == .solid {
            return AnyShapeStyle(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
        } else {
            return AnyShapeStyle(.regularMaterial)
        }
    }
    
    /// Get text color that works on cards - black for readability
    func cardTextColor(for colorScheme: ColorScheme) -> Color {
        return .black
    }
    
    /// Get secondary text color for cards
    func cardSecondaryTextColor(for colorScheme: ColorScheme) -> Color {
        return .black.opacity(0.6)
    }
    
    /// Get primary text color based on color scheme (for non-card text)
    /// Use this for text on gradient backgrounds, headers, etc.
    func primaryTextColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .white : .black
    }
    
    /// Get secondary text color based on color scheme (for non-card text)
    func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6)
    }
    
    /// Get the background gradient for the current theme
    func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        return AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme, cardStyle: cardStyle)
    }
    
    /// Get the accent color for the current theme
    var accentColor: Color {
        return AppTheme.accentColor(for: selectedTheme)
    }
}

// Convenience extension for all text colors
extension Color {
    /// Text color that adapts to light/dark mode - black in light, white in dark
    static func adaptiveText(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .white : .black
    }
    
    /// Secondary text color that adapts to light/dark mode
    static func adaptiveSecondaryText(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6)
    }
}

// Appearance Mode enum (moved from SettingsView if needed)
enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

// Environment key for ThemeManager
private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// View extension for easy access
extension View {
    func withThemeManager() -> some View {
        self.environmentObject(ThemeManager.shared)
    }
}
