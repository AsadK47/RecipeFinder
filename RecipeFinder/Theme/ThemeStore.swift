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

/// Repaints the backdrop over the transparent navigation bar, fading out at its bottom edge, so content scrolling up
/// disappears behind the toolbar buttons instead of showing through them. Invisible at rest: it draws the same
/// pixels as the `AppBackground` beneath it (the opaque base matches the window colour the translucent gradient
/// sits on). Place it above the ScrollView in the screen's ZStack.
struct NavigationBarScrollFade: View {
    var body: some View {
        GeometryReader { proxy in
            // Fade ends at the bar's bottom edge so content resting just below it (the hero photo) is never dimmed.
            let barHeight = max(proxy.safeAreaInsets.top, 1)
            let solidEnd = max(barHeight - AppTheme.spacing16, 0) / barHeight
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()
                AppBackground()
            }
            .mask(alignment: .top) {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: solidEnd),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: barHeight)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
