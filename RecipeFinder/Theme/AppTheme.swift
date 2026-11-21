import SwiftUI

/// Design tokens and theming, split across focused extensions: `+Metrics` (sizing), `+Constants` (opacities/timings), `+Palette` (colors), `+Colors` (adaptive/accent), `+Gradients`.
enum AppTheme {
    /// Eight food-named hues spread round the colour wheel (see `ThemePalette.swift`).
    enum ThemeType: String, CaseIterable, Identifiable, Sendable {
        case tomato = "Tomato"
        case saffron = "Saffron"
        case honey = "Honey"
        case herb = "Herb"
        case teal = "Teal"
        case blueberry = "Blueberry"
        case plum = "Plum"
        case raspberry = "Raspberry"

        var id: String { rawValue }

        /// Shown on the picker swatch so themes are told apart by shape too: under colour blindness Tomato, Saffron and
        /// Honey (deuteranopia) and Herb/Teal (tritanopia) look almost alike, and no in-contrast palette fixes that
        /// (owner 2026-11-21).
        var symbol: String {
            switch self {
            case .tomato: return "flame.fill"
            case .saffron: return "sparkles"
            case .honey: return "drop.fill"
            case .herb: return "leaf.fill"
            case .teal: return "water.waves"
            case .blueberry: return "circle.hexagongrid.fill"
            case .plum: return "moon.fill"
            case .raspberry: return "heart.fill"
            }
        }

        /// Reads a saved choice, including the names used before the colour-theory palette (Nov 2026), so nobody's
        /// theme resets on update. Yellow and Gold were near-duplicates and both become Honey.
        init?(storedValue: String) {
            if let theme = Self(rawValue: storedValue) {
                self = theme
                return
            }
            switch storedValue {
            case "Red": self = .tomato
            case "Orange": self = .saffron
            case "Yellow", "Gold": self = .honey
            case "Green": self = .herb
            case "Purple": self = .plum
            case "Pink": self = .raspberry
            default: return nil
            }
        }
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
