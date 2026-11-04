import SwiftUI

/// Design tokens and theming, split across focused extensions: `+Metrics` (sizing), `+Constants` (opacities/timings), `+Palette` (colors), `+Colors` (adaptive/accent), `+Gradients`.
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

    nonisolated func adaptiveSecondaryForeground() -> some View {
        foregroundStyle(AppTheme.adaptiveSecondary)
    }
}

private struct AdaptiveForegroundColorModifier: ViewModifier {
    let opacity: Double

    func body(content: Content) -> some View {
        content.foregroundStyle(AppTheme.textColor(opacity: opacity))
    }
}
