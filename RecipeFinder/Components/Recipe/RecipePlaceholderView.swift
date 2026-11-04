import SwiftUI

/// Gradient + dish glyph for imageless recipes (loading placeholder with shimmer, or permanent fallback without); hue seeded from the name so lists look varied.
struct RecipePlaceholderView: View {
    let recipeName: String?
    var showShimmer: Bool = false


    private static let palettes: [(Color, Color)] = [
        (Color(red: 0.20, green: 0.60, blue: 0.70), Color(red: 0.10, green: 0.40, blue: 0.90)),
        (Color(red: 0.60, green: 0.20, blue: 0.80), Color(red: 0.40, green: 0.10, blue: 0.90)),
        (Color(red: 0.90, green: 0.50, blue: 0.10), Color(red: 0.90, green: 0.20, blue: 0.20)),
        (Color(red: 0.20, green: 0.70, blue: 0.40), Color(red: 0.10, green: 0.50, blue: 0.60)),
        (Color(red: 0.90, green: 0.30, blue: 0.60), Color(red: 0.70, green: 0.10, blue: 0.80)),
        (Color(red: 0.85, green: 0.75, blue: 0.10), Color(red: 0.90, green: 0.50, blue: 0.10)),
        (Color(red: 0.20, green: 0.40, blue: 0.90), Color(red: 0.10, green: 0.70, blue: 0.90)),
        (Color(red: 0.50, green: 0.20, blue: 0.70), Color(red: 0.20, green: 0.30, blue: 0.90)),
    ]

    // Sum Unicode scalars (not String.hashValue, which is randomised per-session) so the hue is stable across launches.
    private var palette: (Color, Color) {
        guard let name = recipeName, !name.isEmpty else { return Self.palettes[0] }
        let hash = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return Self.palettes[abs(hash) % Self.palettes.count]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.adaptive(light: palette.0.opacity(0.35), dark: palette.0.opacity(0.45)),
                    AppTheme.adaptive(light: palette.1.opacity(0.20), dark: palette.1.opacity(0.30)),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "fork.knife")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(AppTheme.adaptive(light: palette.0.opacity(0.55), dark: palette.0.opacity(0.65)))
        }
        .shimmering(active: showShimmer)
    }
}
