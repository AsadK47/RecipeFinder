import XCTest
import SwiftUI
@testable import RecipeFinder

private typealias Palette = HeartPalette
private typealias Layout  = AnimatedHeartButton.Layout

@MainActor
final class AnimatedHeartButtonTests: XCTestCase {

    private var sut: AnimatedHeartButton!

    override func setUp() async throws {
        try await super.setUp()
        sut = AnimatedHeartButton(isFavorite: .constant(false), action: {})
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - particleColor(for:) — specific colors

    func testParticleColorIndex0IsCoralRed() {
        XCTAssertEqual(sut.particleColor(for: 0), Palette.coralRed)
    }

    func testParticleColorIndex1IsTomato() {
        XCTAssertEqual(sut.particleColor(for: 1), Palette.tomato)
    }

    func testParticleColorIndex2IsSalmon() {
        XCTAssertEqual(sut.particleColor(for: 2), Palette.salmon)
    }

    func testParticleColorIndex3IsDeepOrange() {
        XCTAssertEqual(sut.particleColor(for: 3), Palette.deepOrange)
    }

    func testParticleColorIndex4IsAmber() {
        XCTAssertEqual(sut.particleColor(for: 4), Palette.amber)
    }

    func testParticleColorIndex5IsBlush() {
        XCTAssertEqual(sut.particleColor(for: 5), Palette.blush)
    }

    func testParticleColorIndex6IsMagenta() {
        XCTAssertEqual(sut.particleColor(for: 6), Palette.magenta)
    }

    func testParticleColorIndex7IsRose() {
        XCTAssertEqual(sut.particleColor(for: 7), Palette.rose)
    }

    // MARK: - particleColor(for:) — cycling / modulo

    func testParticleColorCyclesAtIndex8() {
        XCTAssertEqual(sut.particleColor(for: 8), sut.particleColor(for: 0))
    }

    func testParticleColorCyclesAtIndex9() {
        XCTAssertEqual(sut.particleColor(for: 9), sut.particleColor(for: 1))
    }

    func testParticleColorCyclesAtIndex15() {
        XCTAssertEqual(sut.particleColor(for: 15), sut.particleColor(for: 7))
    }

    func testParticleColorCyclesAtIndex16() {
        XCTAssertEqual(sut.particleColor(for: 16), sut.particleColor(for: 0))
    }

    func testParticleColorCyclesAtLargeMultiple() {
        XCTAssertEqual(sut.particleColor(for: 80), sut.particleColor(for: 0))
    }

    // MARK: - particleOffset(for:) — cardinal directions

    func testParticleOffsetIndex0PointsRight() {
        let offset = sut.particleOffset(for: 0)
        // angle = 0 → (cos 0, sin 0) × radius = (radius, 0)
        XCTAssertEqual(offset.width,  Layout.particleRadius, accuracy: 0.001)
        XCTAssertEqual(offset.height, 0.0,                   accuracy: 0.001)
    }

    func testParticleOffsetIndex2PointsDown() {
        let offset = sut.particleOffset(for: 2)
        // angle = π/2 → (cos π/2, sin π/2) × radius ≈ (0, radius)
        XCTAssertEqual(offset.width,  0.0,                   accuracy: 0.001)
        XCTAssertEqual(offset.height, Layout.particleRadius, accuracy: 0.001)
    }

    func testParticleOffsetIndex4PointsLeft() {
        let offset = sut.particleOffset(for: 4)
        // angle = π → (cos π, sin π) × radius = (-radius, 0)
        XCTAssertEqual(offset.width,  -Layout.particleRadius, accuracy: 0.001)
        XCTAssertEqual(offset.height,  0.0,                   accuracy: 0.001)
    }

    func testParticleOffsetIndex6PointsUp() {
        let offset = sut.particleOffset(for: 6)
        // angle = 3π/2 → (cos 3π/2, sin 3π/2) × radius ≈ (0, -radius)
        XCTAssertEqual(offset.width,   0.0,                    accuracy: 0.001)
        XCTAssertEqual(offset.height, -Layout.particleRadius,  accuracy: 0.001)
    }

    // MARK: - particleOffset(for:) — radius invariant

    func testParticleOffsetAllIndicesLieOnRadius25() {
        for index in 0..<Layout.particleCount {
            let offset = sut.particleOffset(for: index)
            let radius = (offset.width * offset.width + offset.height * offset.height).squareRoot()
            XCTAssertEqual(Double(radius), Double(Layout.particleRadius), accuracy: 0.001,
                           "index \(index) radius should be \(Layout.particleRadius)")
        }
    }

    // MARK: - particleOffset(for:) — even angular spacing
    // atan2 wraps at ±π, so normalise the difference into (-π, π] before comparing.

    func testParticleOffsetAnglesAreEvenlySpaced() {
        for index in 0..<(Layout.particleCount - 1) {
            let a = sut.particleOffset(for: index)
            let b = sut.particleOffset(for: index + 1)
            let angleA = atan2(Double(a.height), Double(a.width))
            let angleB = atan2(Double(b.height), Double(b.width))
            var diff = angleB - angleA
            if diff <= -.pi { diff += 2 * .pi }
            if diff >   .pi { diff -= 2 * .pi }
            XCTAssertEqual(diff, Layout.particleAngleStep, accuracy: 0.001,
                           "angle step between index \(index) and \(index + 1) should be π/4")
        }
    }

    func testParticleOffset8IndicesCompleteFullCircle() {
        let first   = sut.particleOffset(for: 0)
        let wrapped = sut.particleOffset(for: Layout.particleCount)
        XCTAssertEqual(first.width,  wrapped.width,  accuracy: 0.001)
        XCTAssertEqual(first.height, wrapped.height, accuracy: 0.001)
    }

    // MARK: - particleOffset(for:) — diagonal symmetry

    func testParticleOffsetIndex1IsTopRightDiagonal() {
        let offset = sut.particleOffset(for: 1)
        // angle = π/4 → cos(π/4) = sin(π/4) = √2/2, so both components = radius/√2
        let expected = Double(Layout.particleRadius) / 2.0.squareRoot()
        XCTAssertEqual(Double(offset.width),  expected, accuracy: 0.001)
        XCTAssertEqual(Double(offset.height), expected, accuracy: 0.001)
    }

    func testParticleOffsetOppositeIndicesSumToZero() {
        // Indices half a circle apart are diametrically opposite; their offsets must cancel
        for index in 0..<(Layout.particleCount / 2) {
            let a = sut.particleOffset(for: index)
            let b = sut.particleOffset(for: index + Layout.particleCount / 2)
            XCTAssertEqual(Double(a.width  + b.width),  0.0, accuracy: 0.001,
                           "x offsets at index \(index) and \(index + Layout.particleCount / 2) should sum to 0")
            XCTAssertEqual(Double(a.height + b.height), 0.0, accuracy: 0.001,
                           "y offsets at index \(index) and \(index + Layout.particleCount / 2) should sum to 0")
        }
    }
}
