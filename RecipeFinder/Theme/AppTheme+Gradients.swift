import SwiftUI

/// Per-theme background gradients, cached because `backgroundGradient` is read from every screen's `body` on each render/tab switch.
extension AppTheme {

    private static let gradientCache = MemoCache<String, LinearGradient>(maxSize: AppTheme.ThemeType.allCases.count * 2)

    static func backgroundGradient(for theme: ThemeType, colorScheme: ColorScheme) -> LinearGradient {
        let cacheKey = "\(theme.rawValue)-\(colorScheme == .dark ? "dark" : "light")"
        return gradientCache.value(for: cacheKey) { _ in
            buildBackgroundGradient(for: theme, colorScheme: colorScheme)
        }
    }

    private static func buildBackgroundGradient(for theme: ThemeType, colorScheme: ColorScheme) -> LinearGradient {
        let swatch = theme.swatch
        let stops = colorScheme == .dark ? swatch.gradientDark : swatch.gradientLight
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
