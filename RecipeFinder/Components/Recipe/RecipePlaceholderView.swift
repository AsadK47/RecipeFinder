import SwiftUI

/// Themed gradient + dish glyph shown when a recipe has no image — used as both
/// the Kingfisher loading placeholder (with shimmer) and the permanent fallback
/// when a load fails (without shimmer).
///
/// The gradient hue is seeded from the recipe name so a mixed list looks varied
/// rather than a uniform grey wall.
struct RecipePlaceholderView: View {
    let recipeName: String?
    var showShimmer: Bool = false

    @Environment(\.colorScheme) private var colorScheme

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

    // Stable across launches: sum Unicode scalar values rather than using
    // String.hashValue, which is randomised per-session in Swift.
    private var palette: (Color, Color) {
        guard let name = recipeName, !name.isEmpty else { return Self.palettes[0] }
        let hash = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return Self.palettes[abs(hash) % Self.palettes.count]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    palette.0.opacity(colorScheme == .dark ? 0.45 : 0.35),
                    palette.1.opacity(colorScheme == .dark ? 0.30 : 0.20),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "fork.knife")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(palette.0.opacity(colorScheme == .dark ? 0.65 : 0.55))
        }
        .shimmering(active: showShimmer)
    }
}
