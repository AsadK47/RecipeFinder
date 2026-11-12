import SwiftUI

/// Illustrated art for imageless recipes (loading placeholder with shimmer, or permanent fallback without): a dish
/// symbol picked from the name/category with small accents, on a gradient coloured by cuisine (`RecipePlaceholderArt`).
struct RecipePlaceholderView: View {
    let recipeName: String?
    var category: String? = nil
    var cuisine: String? = nil
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

    private var art: RecipePlaceholderArt {
        RecipePlaceholderArt.art(name: recipeName, category: category, cuisine: cuisine)
    }

    var body: some View {
        let art = art
        let palette = Self.palettes[art.paletteIndex % Self.palettes.count]
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let mainSize = min(max(side * 0.34, 18), 72)
            let accentSize = mainSize * 0.38
            ZStack {
                LinearGradient(
                    colors: [
                        AppTheme.adaptive(light: palette.0.opacity(0.35), dark: palette.0.opacity(0.45)),
                        AppTheme.adaptive(light: palette.1.opacity(0.20), dark: palette.1.opacity(0.30)),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                // Soft halo so the dish reads as a plated illustration, not a bare glyph.
                Circle()
                    .fill(AppTheme.adaptive(light: Color.white.opacity(0.35), dark: Color.white.opacity(0.10)))
                    .frame(width: mainSize * 1.7, height: mainSize * 1.7)
                Image(systemName: art.motif.symbol)
                    .font(.system(size: mainSize, weight: .light))
                    .foregroundStyle(AppTheme.adaptive(light: palette.0.opacity(0.75), dark: palette.0.opacity(0.85)))
                // Accents only where there's room — on 56pt thumbnails they'd just be noise.
                if side >= 90, art.motif.accents.count >= 2 {
                    accent(art.motif.accents[0], size: accentSize, color: palette.1)
                        .rotationEffect(.degrees(-14))
                        .position(x: proxy.size.width * 0.22, y: proxy.size.height * 0.26)
                    accent(art.motif.accents[1], size: accentSize, color: palette.1)
                        .rotationEffect(.degrees(12))
                        .position(x: proxy.size.width * 0.78, y: proxy.size.height * 0.74)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityHidden(true)
        .shimmering(active: showShimmer)
    }

    private func accent(_ symbol: String, size: CGFloat, color: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: size, weight: .regular))
            .foregroundStyle(AppTheme.adaptive(light: color.opacity(0.45), dark: color.opacity(0.55)))
    }
}
