import Foundation

/// A colour in OKLCH — lightness (0–1), chroma and hue (degrees). Themes are defined here rather than in sRGB so every
/// accent shares one perceived lightness per mode and gradients can step lightness while staying on one hue family.
struct OKLCH: Equatable, Sendable {
    let l: Double
    let c: Double
    let h: Double

    init(l: Double, c: Double, h: Double) {
        self.l = l
        self.c = c
        self.h = h
    }

    /// Oklab coordinates (L, a, b); distances between them are perceived colour differences (ΔE OK).
    var lab: (l: Double, a: Double, b: Double) {
        let radians = h * .pi / 180
        return (l, c * cos(radians), c * sin(radians))
    }

    /// Linear-light sRGB, unclamped — a component outside 0…1 means the colour is out of the sRGB gamut.
    var linearRGB: (r: Double, g: Double, b: Double) {
        let (lightness, a, b) = lab
        let lCone = pow(lightness + 0.3963377774 * a + 0.2158037573 * b, 3)
        let mCone = pow(lightness - 0.1055613458 * a - 0.0638541728 * b, 3)
        let sCone = pow(lightness - 0.0894841775 * a - 1.2914855480 * b, 3)
        return (
            4.0767416621 * lCone - 3.3077115913 * mCone + 0.2309699292 * sCone,
            -1.2684380046 * lCone + 2.6097574011 * mCone - 0.3413193965 * sCone,
            -0.0041960863 * lCone - 0.7034186147 * mCone + 1.7076147010 * sCone
        )
    }

    /// Gamma-encoded sRGB components (0–1), clamped into the gamut — what the screen shows.
    var srgb: SRGB {
        let linear = linearRGB
        return SRGB(
            r: SRGB.encode(linear.r.clamped01),
            g: SRGB.encode(linear.g.clamped01),
            b: SRGB.encode(linear.b.clamped01)
        )
    }

    /// True when the colour shows on screen unclipped (every linear sRGB component within 0…1).
    var isInGamut: Bool {
        let rgb = linearRGB
        return [rgb.r, rgb.g, rgb.b].allSatisfy { $0 >= -1e-9 && $0 <= 1 + 1e-9 }
    }

    /// The same hue at another lightness, with chroma eased down only as far as needed to stay inside sRGB.
    func withLightness(_ lightness: Double) -> OKLCH {
        let target = OKLCH(l: lightness, c: c, h: h)
        if target.isInGamut { return target }
        var low = 0.0
        var high = c
        for _ in 0..<32 {
            let mid = (low + high) / 2
            if OKLCH(l: lightness, c: mid, h: h).isInGamut { low = mid } else { high = mid }
        }
        return OKLCH(l: lightness, c: low, h: h)
    }

    /// Perceived difference to another colour (Euclidean distance in Oklab).
    func distance(to other: OKLCH) -> Double {
        let (l1, a1, b1) = lab
        let (l2, a2, b2) = other.lab
        return ((l1 - l2) * (l1 - l2) + (a1 - a2) * (a1 - a2) + (b1 - b2) * (b1 - b2)).squareRoot()
    }
}

/// Gamma-encoded sRGB colour, components 0–1.
struct SRGB: Equatable, Sendable {
    let r: Double
    let g: Double
    let b: Double

    static let white = SRGB(r: 1, g: 1, b: 1)
    static let black = SRGB(r: 0, g: 0, b: 0)

    /// WCAG 2.x relative luminance.
    var relativeLuminance: Double {
        0.2126 * Self.decode(r) + 0.7152 * Self.decode(g) + 0.0722 * Self.decode(b)
    }

    /// WCAG 2.x contrast ratio (1…21) between two colours, order-independent.
    func contrast(with other: SRGB) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func decode(_ value: Double) -> Double {
        value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }

    static func encode(_ value: Double) -> Double {
        value <= 0.0031308 ? 12.92 * value : 1.055 * pow(value, 1 / 2.4) - 0.055
    }
}

/// One theme's colours. Accents carry white text (`AppTheme.onAccent`, ≥4.5:1) and stand out from the mode's base
/// surface (≥3:1) — in Dark from every gradient stop too, which is why Dark gradients are deep; gradients stay within
/// ±25° of the theme hue and keep the mode's text colour ≥4.5:1 on every stop.
struct ThemeSwatch: Equatable, Sendable {
    let hue: Double
    let accentLight: OKLCH
    let accentDark: OKLCH
    let gradientLight: [OKLCH]
    let gradientDark: [OKLCH]
}

/// Increase Contrast (Settings → Accessibility → Display & Text Size). Light: a deeper accent carries white text at
/// ≥7:1 and the gradient lifts so black text is ≥7:1. Dark: the accent goes *lighter* and carries black text
/// (`AppTheme.onAccent`) at ≥7:1 — a Dark accent deep enough for white at 7:1 would sink into the dark base (<3:1),
/// so this follows iOS's own Dark high-contrast colours. Dark gradients already carry white text far above 7:1.
extension ThemeSwatch {
    static let highContrastAccentLightness = (light: 0.42, dark: 0.78)
    static let highContrastGradientLift = 0.06

    func accent(dark: Bool, highContrast: Bool) -> OKLCH {
        switch (dark, highContrast) {
        case (false, false): return accentLight
        case (true, false): return accentDark
        case (false, true): return accentLight.withLightness(Self.highContrastAccentLightness.light)
        case (true, true): return accentDark.withLightness(Self.highContrastAccentLightness.dark)
        }
    }

    func gradient(dark: Bool, highContrast: Bool) -> [OKLCH] {
        if dark { return gradientDark }
        guard highContrast else { return gradientLight }
        return gradientLight.map { $0.withLightness($0.l + Self.highContrastGradientLift) }
    }
}

extension AppTheme.ThemeType {
    /// Hues spread round the wheel (OKLCH degrees; HSL ≈ 5° Tomato … 335° Raspberry). Values were solved for gamut
    /// and contrast, then rounded; `ThemePaletteTests` re-checks every number, so edit freely and let the tests judge.
    var swatch: ThemeSwatch {
        switch self {
        case .tomato:
            return ThemeSwatch(
                hue: 30,
                accentLight: .init(l: 0.520, c: 0.169, h: 30),
                accentDark: .init(l: 0.570, c: 0.149, h: 30),
                gradientLight: [.init(l: 0.82, c: 0.102, h: 10), .init(l: 0.74, c: 0.139, h: 30), .init(l: 0.66, c: 0.139, h: 50)],
                gradientDark: [.init(l: 0.28, c: 0.079, h: 10), .init(l: 0.23, c: 0.069, h: 30), .init(l: 0.18, c: 0.047, h: 50), .init(l: 0.15, c: 0.010, h: 50)]
            )
        case .saffron:
            return ThemeSwatch(
                hue: 55,
                accentLight: .init(l: 0.520, c: 0.127, h: 55),
                accentDark: .init(l: 0.570, c: 0.140, h: 55),
                gradientLight: [.init(l: 0.82, c: 0.101, h: 35), .init(l: 0.74, c: 0.139, h: 55), .init(l: 0.66, c: 0.138, h: 75)],
                gradientDark: [.init(l: 0.28, c: 0.079, h: 35), .init(l: 0.23, c: 0.056, h: 55), .init(l: 0.18, c: 0.037, h: 75), .init(l: 0.15, c: 0.010, h: 75)]
            )
        case .honey:
            return ThemeSwatch(
                hue: 85,
                accentLight: .init(l: 0.520, c: 0.105, h: 85),
                accentDark: .init(l: 0.565, c: 0.114, h: 85),
                gradientLight: [.init(l: 0.82, c: 0.131, h: 65), .init(l: 0.74, c: 0.139, h: 85), .init(l: 0.66, c: 0.139, h: 105)],
                gradientDark: [.init(l: 0.28, c: 0.062, h: 65), .init(l: 0.23, c: 0.046, h: 85), .init(l: 0.18, c: 0.038, h: 105), .init(l: 0.15, c: 0.010, h: 105)]
            )
        case .herb:
            return ThemeSwatch(
                hue: 148,
                accentLight: .init(l: 0.520, c: 0.149, h: 148),
                accentDark: .init(l: 0.545, c: 0.149, h: 148),
                gradientLight: [.init(l: 0.82, c: 0.139, h: 128), .init(l: 0.74, c: 0.139, h: 148), .init(l: 0.66, c: 0.132, h: 168)],
                gradientDark: [.init(l: 0.28, c: 0.072, h: 128), .init(l: 0.23, c: 0.066, h: 148), .init(l: 0.18, c: 0.036, h: 168), .init(l: 0.15, c: 0.010, h: 168)]
            )
        case .teal:
            return ThemeSwatch(
                hue: 185,
                accentLight: .init(l: 0.520, c: 0.090, h: 185),
                accentDark: .init(l: 0.550, c: 0.095, h: 185),
                gradientLight: [.init(l: 0.82, c: 0.139, h: 165), .init(l: 0.74, c: 0.129, h: 185), .init(l: 0.66, c: 0.111, h: 205)],
                gradientDark: [.init(l: 0.28, c: 0.058, h: 165), .init(l: 0.23, c: 0.039, h: 185), .init(l: 0.18, c: 0.030, h: 205), .init(l: 0.15, c: 0.010, h: 205)]
            )
        case .blueberry:
            return ThemeSwatch(
                hue: 262,
                accentLight: .init(l: 0.520, c: 0.169, h: 262),
                accentDark: .init(l: 0.565, c: 0.149, h: 262),
                gradientLight: [.init(l: 0.82, c: 0.098, h: 242), .init(l: 0.74, c: 0.132, h: 262), .init(l: 0.66, c: 0.139, h: 282)],
                gradientDark: [.init(l: 0.28, c: 0.065, h: 242), .init(l: 0.23, c: 0.069, h: 262), .init(l: 0.18, c: 0.049, h: 282), .init(l: 0.15, c: 0.010, h: 282)]
            )
        case .plum:
            return ThemeSwatch(
                hue: 315,
                accentLight: .init(l: 0.520, c: 0.169, h: 315),
                accentDark: .init(l: 0.570, c: 0.149, h: 315),
                gradientLight: [.init(l: 0.82, c: 0.099, h: 295), .init(l: 0.74, c: 0.139, h: 315), .init(l: 0.66, c: 0.139, h: 335)],
                gradientDark: [.init(l: 0.28, c: 0.079, h: 295), .init(l: 0.23, c: 0.069, h: 315), .init(l: 0.18, c: 0.049, h: 335), .init(l: 0.15, c: 0.010, h: 335)]
            )
        case .raspberry:
            return ThemeSwatch(
                hue: 358,
                accentLight: .init(l: 0.520, c: 0.169, h: 358),
                accentDark: .init(l: 0.570, c: 0.149, h: 358),
                gradientLight: [.init(l: 0.82, c: 0.139, h: 338), .init(l: 0.74, c: 0.139, h: 358), .init(l: 0.66, c: 0.139, h: 18)],
                gradientDark: [.init(l: 0.28, c: 0.079, h: 338), .init(l: 0.23, c: 0.069, h: 358), .init(l: 0.18, c: 0.049, h: 18), .init(l: 0.15, c: 0.010, h: 18)]
            )
        }
    }
}

private extension Double {
    var clamped01: Double { Swift.min(Swift.max(self, 0), 1) }
}
