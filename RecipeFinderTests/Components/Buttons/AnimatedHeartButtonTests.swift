import Testing
import Foundation
import SwiftUI
@testable import RecipeFinder

@MainActor
@Suite("AnimatedHeartButton burst geometry")
struct AnimatedHeartButtonTests {

    private typealias Palette = HeartPalette
    private typealias Layout  = AnimatedHeartButton.Layout

    private func makeButton() -> AnimatedHeartButton {
        AnimatedHeartButton(isFavorite: .constant(false), action: {})
    }

    // MARK: - Particle colours

    @Test("The first eight particles use the heart palette in order", arguments: [
        (0, Palette.coralRed),
        (1, Palette.tomato),
        (2, Palette.salmon),
        (3, Palette.deepOrange),
        (4, Palette.amber),
        (5, Palette.blush),
        (6, Palette.magenta),
        (7, Palette.rose)
    ])
    func usesPaletteColorInOrder(index: Int, expected: Color) {
        #expect(makeButton().particleColor(for: index) == expected)
    }

    @Test("Particle colours repeat every eight particles", arguments: [
        (8, 0), (9, 1), (15, 7), (16, 0), (80, 0)
    ])
    func colorRepeatsEveryEight(index: Int, sameAs: Int) {
        let button = makeButton()
        #expect(button.particleColor(for: index) == button.particleColor(for: sameAs))
    }

    // MARK: - Particle offsets (cardinal directions)

    /// Expected unit direction for the quarter-turn indices; multiplied by the
    /// particle radius it gives the offset. Index 0 points right, then clockwise.
    @Test("Quarter-turn particles point in the four cardinal directions", arguments: [
        (index: 0, unitX:  1.0, unitY:  0.0),   // right
        (index: 2, unitX:  0.0, unitY:  1.0),   // down
        (index: 4, unitX: -1.0, unitY:  0.0),   // left
        (index: 6, unitX:  0.0, unitY: -1.0)    // up
    ])
    func offsetPointsInCardinalDirection(index: Int, unitX: Double, unitY: Double) {
        let offset = makeButton().particleOffset(for: index)
        let radius = Double(Layout.particleRadius)
        #expect(abs(Double(offset.width)  - unitX * radius) < 0.001)
        #expect(abs(Double(offset.height) - unitY * radius) < 0.001)
    }

    // MARK: - Particle offsets (invariants)

    @Test("Every particle sits exactly on the particle radius")
    func offsetsLieOnRadius() {
        let button = makeButton()
        for index in 0..<Layout.particleCount {
            let offset = button.particleOffset(for: index)
            let radius = (offset.width * offset.width + offset.height * offset.height).squareRoot()
            #expect(abs(Double(radius) - Double(Layout.particleRadius)) < 0.001)
        }
    }

    @Test("Adjacent particles are evenly spaced around the circle")
    func offsetsAreEvenlySpaced() {
        let button = makeButton()
        for index in 0..<(Layout.particleCount - 1) {
            let a = button.particleOffset(for: index)
            let b = button.particleOffset(for: index + 1)
            let angleA = atan2(Double(a.height), Double(a.width))
            let angleB = atan2(Double(b.height), Double(b.width))
            // atan2 wraps at ±π; normalise the step into (-π, π] before comparing.
            var step = angleB - angleA
            if step <= -.pi { step += 2 * .pi }
            if step >   .pi { step -= 2 * .pi }
            #expect(abs(step - Layout.particleAngleStep) < 0.001)
        }
    }

    @Test("Particle offsets wrap to the start after a full circle")
    func offsetsWrapAfterFullCircle() {
        let button = makeButton()
        let first   = button.particleOffset(for: 0)
        let wrapped = button.particleOffset(for: Layout.particleCount)
        #expect(abs(Double(first.width)  - Double(wrapped.width))  < 0.001)
        #expect(abs(Double(first.height) - Double(wrapped.height)) < 0.001)
    }

    @Test("A 45° particle splits its offset equally between x and y")
    func diagonalParticleHasEqualComponents() {
        let offset = makeButton().particleOffset(for: 1)
        let expected = Double(Layout.particleRadius) / 2.0.squareRoot()
        #expect(abs(Double(offset.width)  - expected) < 0.001)
        #expect(abs(Double(offset.height) - expected) < 0.001)
    }

    @Test("Diametrically opposite particles cancel out")
    func oppositeParticlesCancel() {
        let button = makeButton()
        let half = Layout.particleCount / 2
        for index in 0..<half {
            let a = button.particleOffset(for: index)
            let b = button.particleOffset(for: index + half)
            #expect(abs(Double(a.width  + b.width))  < 0.001)
            #expect(abs(Double(a.height + b.height)) < 0.001)
        }
    }
}
