import SwiftUI

/// Per-theme background gradients, cached because `backgroundGradient` is read from every screen's `body` on each render/tab switch.
extension AppTheme {

    private static let gradientCache = MemoCache<String, LinearGradient>(maxSize: AppTheme.ThemeType.allCases.count * 4)

    static func backgroundGradient(
        for theme: ThemeType, colorScheme: ColorScheme, contrast: ColorSchemeContrast = .standard
    ) -> LinearGradient {
        let dark = colorScheme == .dark
        let highContrast = contrast == .increased
        let cacheKey = "\(theme.rawValue)-\(dark ? "dark" : "light")-\(highContrast ? "high" : "standard")"
        return gradientCache.value(for: cacheKey) { _ in
            buildBackgroundGradient(for: theme, dark: dark, highContrast: highContrast)
        }
    }

    private static func buildBackgroundGradient(for theme: ThemeType, dark: Bool, highContrast: Bool) -> LinearGradient {
        let stops = theme.swatch.gradient(dark: dark, highContrast: highContrast)
        return LinearGradient(
            gradient: Gradient(colors: stops.map { Color($0) }),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    /// Shows an OKLCH palette colour (clamped into sRGB).
    init(_ oklch: OKLCH) {
        let rgb = oklch.srgb
        self.init(.sRGB, red: rgb.r, green: rgb.g, blue: rgb.b, opacity: 1)
    }
}
