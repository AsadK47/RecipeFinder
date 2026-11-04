import SwiftUI

/// App-wide colour theme — the single source of truth. Views read it through `AppTheme.accentColor` and
/// `AppBackground`; Observation tracks those reads inside any `body`, so every screen re-renders on a theme change
/// without each view keeping its own `@AppStorage` copy. A design token rather than a manager, so it's read via
/// `.shared` instead of an `@Environment` seam.
@MainActor
@Observable
final class ThemeStore {
    static let shared = ThemeStore()
    /// Same key the old per-view `@AppStorage("appTheme")` used, so existing choices carry over.
    static let storageKey = "appTheme"

    var theme: AppTheme.ThemeType {
        didSet { defaults.set(theme.rawValue, forKey: Self.storageKey) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        theme = defaults.string(forKey: Self.storageKey).flatMap(AppTheme.ThemeType.init(rawValue:)) ?? .teal
    }
}

/// Full-screen themed gradient behind every screen and sheet.
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppTheme.backgroundGradient(for: ThemeStore.shared.theme, colorScheme: colorScheme)
            .ignoresSafeArea()
    }
}
