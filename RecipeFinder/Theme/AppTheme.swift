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

/// Design tokens and theming for the app. Tokens are grouped into focused
/// extensions to keep this navigable:
/// - `AppTheme+Metrics` — sizing (fonts, spacing, radii, heights, widths, shadows)
/// - `AppTheme+Constants` — opacities, animation timings, counts, intervals
/// - `AppTheme+Palette` — raw and semantic colors
/// - `AppTheme+Colors` — adaptive color helpers and accent colors
/// - `AppTheme+Gradients` — cached background gradients
enum AppTheme {
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
