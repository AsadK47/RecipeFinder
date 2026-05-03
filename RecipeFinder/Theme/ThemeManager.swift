
import SwiftUI
import Combine

enum CardStyle: String, CaseIterable {
    case frosted = "Frost Light"
    case solid = "Ember Dark"
}

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

import SwiftUI
import Combine

final class ThemeManager: ObservableObject, @unchecked Sendable {
    static let shared = ThemeManager()
    
    @AppStorage("appTheme") var selectedTheme: AppTheme.ThemeType = .teal {
        didSet {
            objectWillChange.send()
            NotificationCenter.default.post(name: .themeDidChange, object: nil)
        }
    }
    
    @AppStorage("cardStyle") var cardStyle: CardStyle = .frosted {
        didSet {
            objectWillChange.send()
            NotificationCenter.default.post(name: .cardStyleDidChange, object: nil)
        }
    }
    
    @AppStorage("appearanceMode") var appearanceMode: AppearanceMode = .system {
        didSet {
            objectWillChange.send()
            NotificationCenter.default.post(name: .appearanceModeDidChange, object: nil)
        }
    }
    
    private init() {}
    
    func cardBackground(for colorScheme: ColorScheme) -> some ShapeStyle {
        if cardStyle == .solid {
            return AnyShapeStyle(AppTheme.cardBackground(for: colorScheme))
        } else {
            return AnyShapeStyle(.regularMaterial)
        }
    }
    
    func cardTextColor(for colorScheme: ColorScheme) -> Color {
        return .black
    }
    
    func cardSecondaryTextColor(for colorScheme: ColorScheme) -> Color {
        return .black.opacity(AppTheme.mediumEmphasisOpacity)
    }
    
    func primaryTextColor(for colorScheme: ColorScheme) -> Color {
        return AppTheme.adaptiveEmphasis(for: colorScheme)
    }
    
    func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        return AppTheme.adaptiveSubtitle(for: colorScheme)
    }
    
    func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        return AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
    }
    
    var accentColor: Color {
        return AppTheme.accentColor(for: selectedTheme)
    }
}

extension Color {
    static func adaptiveText(for colorScheme: ColorScheme) -> Color {
        return AppTheme.adaptiveEmphasis(for: colorScheme)
    }
    
    static func adaptiveSecondaryText(for colorScheme: ColorScheme) -> Color {
        return AppTheme.adaptiveSubtitle(for: colorScheme)
    }
}

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

extension View {
    func withThemeManager() -> some View {
        self.environmentObject(ThemeManager.shared)
    }
}

extension Notification.Name {
    static let themeDidChange = Notification.Name("themeDidChange")
    static let cardStyleDidChange = Notification.Name("cardStyleDidChange")
    static let appearanceModeDidChange = Notification.Name("appearanceModeDidChange")
}
