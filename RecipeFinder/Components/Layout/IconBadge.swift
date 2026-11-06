import SwiftUI

/// An SF Symbol centred in a tinted circle — the one recipe for row/header icon badges so sizes and fills can't drift.
struct IconBadge: View {
    enum Style {
        /// Tint at low opacity behind a tint-coloured icon.
        case tinted
        /// Solid tint fill behind a white icon.
        case solid
    }

    let systemName: String
    let tint: Color
    let diameter: CGFloat
    let iconFont: Font
    let style: Style
    let tintOpacity: Double

    /// Fixed-size icon; `iconSize` defaults to ~45% of the circle.
    init(
        systemName: String,
        tint: Color,
        diameter: CGFloat,
        iconSize: CGFloat? = nil,
        weight: Font.Weight = .semibold,
        style: Style = .tinted,
        tintOpacity: Double = AppTheme.cardDarkOpacity
    ) {
        self.init(
            systemName: systemName,
            tint: tint,
            diameter: diameter,
            iconFont: .system(size: iconSize ?? diameter * 0.45, weight: weight),
            style: style,
            tintOpacity: tintOpacity
        )
    }

    /// Text-style icon (e.g. `.caption2`) for small dots that should scale with Dynamic Type.
    init(
        systemName: String,
        tint: Color,
        diameter: CGFloat,
        iconFont: Font,
        style: Style = .tinted,
        tintOpacity: Double = AppTheme.cardDarkOpacity
    ) {
        self.systemName = systemName
        self.tint = tint
        self.diameter = diameter
        self.iconFont = iconFont
        self.style = style
        self.tintOpacity = tintOpacity
    }

    var body: some View {
        Circle()
            .fill(style == .solid ? tint : tint.opacity(tintOpacity))
            .frame(width: diameter, height: diameter)
            .overlay(
                Image(systemName: systemName)
                    .font(iconFont)
                    .foregroundStyle(style == .solid ? Color.white : tint)
            )
    }
}

/// A collection's colour dot (28pt, white glyph) — shared by the collection grid, smart collections and the add-to sheet.
struct CollectionDot: View {
    let color: Color
    var systemImage: String = "rectangle.stack.fill"
    var iconFont: Font = .caption2

    var body: some View {
        IconBadge(systemName: systemImage, tint: color, diameter: 28, iconFont: iconFont, style: .solid)
    }
}
