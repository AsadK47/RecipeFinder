import Testing
import Foundation
import SwiftUI
import UIKit
@testable import RecipeFinder

/// The contrast table: every theme's accent and gradient, in Light and Dark, against WCAG 2.x.
@Suite("Theme palette")
struct ThemePaletteTests {

    private static let themes = AppTheme.ThemeType.allCases
    /// Dark mode's base surface (`AppTheme.secondaryBackgroundDark`).
    private static let darkBase = SRGB(r: 18 / 255, g: 18 / 255, b: 20 / 255)

    private func hueDistance(_ a: Double, _ b: Double) -> Double {
        let d = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(d, 360 - d)
    }

    private func inGamut(_ colour: OKLCH) -> Bool {
        let rgb = colour.linearRGB
        return [rgb.r, rgb.g, rgb.b].allSatisfy { $0 >= -0.002 && $0 <= 1.002 }
    }

    // MARK: Colour maths

    @Test("OKLCH converts sRGB red back to red")
    func oklchMatchesReferenceRed() {
        let red = OKLCH(l: 0.62796, c: 0.25768, h: 29.2339).srgb
        #expect(abs(red.r - 1) < 0.003 && abs(red.g) < 0.003 && abs(red.b) < 0.003)
    }

    @Test("White on black is 21:1, and contrast ignores order")
    func contrastMatchesWCAG() {
        #expect(abs(SRGB.white.contrast(with: .black) - 21) < 0.001)
        let grey = SRGB(r: 0.5, g: 0.5, b: 0.5)
        #expect(grey.contrast(with: .white) == SRGB.white.contrast(with: grey))
        // #777777 on white is the textbook "just under AA" pair (4.48:1) — pins the gamma curve, not just 0 and 1.
        let midGrey = SRGB(r: 119 / 255, g: 119 / 255, b: 119 / 255)
        #expect(abs(midGrey.contrast(with: .white) - 4.48) < 0.01)
    }

    // MARK: Accents

    @Test("White text on the Light accent is at least 4.5:1", arguments: themes)
    func lightAccentCarriesWhiteText(theme: AppTheme.ThemeType) {
        #expect(theme.swatch.accentLight.srgb.contrast(with: .white) >= 4.5)
    }

    @Test("White text on the Dark accent is at least 4.5:1", arguments: themes)
    func darkAccentCarriesWhiteText(theme: AppTheme.ThemeType) {
        #expect(theme.swatch.accentDark.srgb.contrast(with: .white) >= 4.5)
    }

    @Test("The Dark accent stands out from the dark base by at least 3:1", arguments: themes)
    func darkAccentStandsOut(theme: AppTheme.ThemeType) {
        #expect(theme.swatch.accentDark.srgb.contrast(with: Self.darkBase) >= 3)
    }

    @Test("The Light accent stands out from the light base by at least 3:1", arguments: themes)
    func lightAccentStandsOut(theme: AppTheme.ThemeType) {
        // `AppTheme.secondaryBackgroundLight`, a touch darker than white.
        let lightBase = SRGB(r: 242 / 255, g: 242 / 255, b: 247 / 255)
        #expect(theme.swatch.accentLight.srgb.contrast(with: lightBase) >= 3)
    }

    @Test("Every palette colour is inside sRGB, so nothing is clipped", arguments: themes)
    func paletteIsInGamut(theme: AppTheme.ThemeType) {
        let swatch = theme.swatch
        let colours = [swatch.accentLight, swatch.accentDark] + swatch.gradientLight + swatch.gradientDark
        #expect(colours.allSatisfy(inGamut))
    }

    @Test("Accents share one perceived lightness per mode")
    func accentsShareLightness() {
        for accents in [Self.themes.map(\.swatch.accentLight), Self.themes.map(\.swatch.accentDark)] {
            let lightness = accents.map(\.l)
            #expect((lightness.max() ?? 0) - (lightness.min() ?? 0) <= 0.03)
        }
    }

    @Test("No two themes look alike: accents differ by ΔE OK ≥ 0.06 in both modes")
    func accentsAreTellableApart() {
        for accents in [Self.themes.map(\.swatch.accentLight), Self.themes.map(\.swatch.accentDark)] {
            for (i, a) in accents.enumerated() {
                for b in accents[(i + 1)...] {
                    #expect(a.distance(to: b) >= 0.06, "\(a) vs \(b)")
                }
            }
        }
    }

    @Test("Hues spread round the wheel, at least 20° apart, with a blue")
    func huesAreSpread() {
        let hues = Self.themes.map(\.swatch.hue).sorted()
        let gaps = zip(hues, hues.dropFirst() + [(hues.first ?? 0) + 360]).map { $1 - $0 }
        #expect(gaps.allSatisfy { $0 >= 20 })
        #expect(hues.contains { (240...280).contains($0) })
    }

    @Test("Each accent sits on its theme's hue", arguments: themes)
    func accentMatchesHue(theme: AppTheme.ThemeType) {
        let swatch = theme.swatch
        #expect(hueDistance(swatch.accentLight.h, swatch.hue) <= 5)
        #expect(hueDistance(swatch.accentDark.h, swatch.hue) <= 5)
    }

    @Test("The app's accent shows the Light variant in Light and the Dark variant in Dark", arguments: themes)
    func accentResolvesPerMode(theme: AppTheme.ThemeType) {
        let accent = UIColor(AppTheme.accentColor(for: theme))
        for (style, expected) in [(UIUserInterfaceStyle.light, theme.swatch.accentLight.srgb),
                                  (.dark, theme.swatch.accentDark.srgb)] {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            accent.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
                .getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            #expect(abs(Double(red) - expected.r) < 0.01 && abs(Double(green) - expected.g) < 0.01
                && abs(Double(blue) - expected.b) < 0.01, "\(theme) \(style.rawValue)")
        }
    }

    // MARK: Gradients

    @Test("Gradients stay within ±25° of the theme hue (analogous only)", arguments: themes)
    func gradientsAreAnalogous(theme: AppTheme.ThemeType) {
        let swatch = theme.swatch
        for stop in swatch.gradientLight + swatch.gradientDark {
            #expect(hueDistance(stop.h, swatch.hue) <= 25, "\(theme) stop \(stop)")
        }
    }

    @Test("Black text reads on every Light gradient stop (≥4.5:1)", arguments: themes)
    func lightGradientCarriesBlackText(theme: AppTheme.ThemeType) {
        #expect(theme.swatch.gradientLight.allSatisfy { $0.srgb.contrast(with: .black) >= 4.5 })
    }

    @Test("White text reads on every Dark gradient stop (≥4.5:1)", arguments: themes)
    func darkGradientCarriesWhiteText(theme: AppTheme.ThemeType) {
        #expect(theme.swatch.gradientDark.allSatisfy { $0.srgb.contrast(with: .white) >= 4.5 })
    }

    @Test("Gradients step lightness one way, light to dark", arguments: themes)
    func gradientsStepLightness(theme: AppTheme.ThemeType) {
        for stops in [theme.swatch.gradientLight, theme.swatch.gradientDark] {
            #expect(zip(stops, stops.dropFirst()).allSatisfy { $0.l > $1.l })
        }
    }

    // MARK: Saved themes

    @Test("Themes saved under the old names map to the new palette", arguments: [
        ("Teal", AppTheme.ThemeType.teal), ("Red", .tomato), ("Orange", .saffron), ("Yellow", .honey),
        ("Gold", .honey), ("Green", .herb), ("Purple", .plum), ("Pink", .raspberry)
    ])
    func oldNamesMigrate(stored: String, expected: AppTheme.ThemeType) {
        #expect(AppTheme.ThemeType(storedValue: stored) == expected)
    }

    @Test("New names read back as themselves", arguments: themes)
    func newNamesRoundTrip(theme: AppTheme.ThemeType) {
        #expect(AppTheme.ThemeType(storedValue: theme.rawValue) == theme)
    }

    @Test("An unknown name is not a theme")
    func unknownNameIsNil() {
        #expect(AppTheme.ThemeType(storedValue: "Chartreuse") == nil)
    }
}
