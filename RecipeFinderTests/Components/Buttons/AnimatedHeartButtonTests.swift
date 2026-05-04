import XCTest
import SwiftUI
@testable import RecipeFinder

@MainActor
final class AnimatedHeartButtonTests: XCTestCase {

    private var sut: AnimatedHeartButton!

    override func setUp() {
        super.setUp()
        sut = AnimatedHeartButton(isFavorite: .constant(false), action: {})
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - particleColor(for:) — specific colors

    func testParticleColorIndex0IsCoralRed() {
        XCTAssertEqual(sut.particleColor(for: 0), Color(red: 1.00, green: 0.20, blue: 0.40))
    }

    func testParticleColorIndex1IsTomato() {
        XCTAssertEqual(sut.particleColor(for: 1), Color(red: 0.96, green: 0.26, blue: 0.21))
    }

    func testParticleColorIndex2IsSalmon() {
        XCTAssertEqual(sut.particleColor(for: 2), Color(red: 1.00, green: 0.38, blue: 0.27))
    }

    func testParticleColorIndex3IsDeepOrange() {
        XCTAssertEqual(sut.particleColor(for: 3), Color(red: 1.00, green: 0.50, blue: 0.00))
    }

    func testParticleColorIndex4IsAmber() {
        XCTAssertEqual(sut.particleColor(for: 4), Color(red: 1.00, green: 0.65, blue: 0.00))
    }

    func testParticleColorIndex5IsBlush() {
        XCTAssertEqual(sut.particleColor(for: 5), Color(red: 1.00, green: 0.75, blue: 0.80))
    }

    func testParticleColorIndex6IsMagenta() {
        XCTAssertEqual(sut.particleColor(for: 6), Color(red: 0.80, green: 0.20, blue: 0.60))
    }

    func testParticleColorIndex7IsRose() {
        XCTAssertEqual(sut.particleColor(for: 7), Color(red: 1.00, green: 0.40, blue: 0.50))
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
        // angle = 0 → (cos 0, sin 0) × 25 = (25, 0)
        XCTAssertEqual(offset.width, 25.0, accuracy: 0.001)
        XCTAssertEqual(offset.height, 0.0, accuracy: 0.001)
    }

    func testParticleOffsetIndex2PointsDown() {
        let offset = sut.particleOffset(for: 2)
        // angle = π/2 → (cos π/2, sin π/2) × 25 ≈ (0, 25)
        XCTAssertEqual(offset.width, 0.0, accuracy: 0.001)
        XCTAssertEqual(offset.height, 25.0, accuracy: 0.001)
    }

    func testParticleOffsetIndex4PointsLeft() {
        let offset = sut.particleOffset(for: 4)
        // angle = π → (cos π, sin π) × 25 = (-25, 0)
        XCTAssertEqual(offset.width, -25.0, accuracy: 0.001)
        XCTAssertEqual(offset.height, 0.0, accuracy: 0.001)
    }

    func testParticleOffsetIndex6PointsUp() {
        let offset = sut.particleOffset(for: 6)
        // angle = 3π/2 → (cos 3π/2, sin 3π/2) × 25 ≈ (0, -25)
        XCTAssertEqual(offset.width, 0.0, accuracy: 0.001)
        XCTAssertEqual(offset.height, -25.0, accuracy: 0.001)
    }

    // MARK: - particleOffset(for:) — radius invariant

    func testParticleOffsetAllIndicesLieOnRadius25() {
        for index in 0..<8 {
            let offset = sut.particleOffset(for: index)
            let radius = (offset.width * offset.width + offset.height * offset.height).squareRoot()
            XCTAssertEqual(Double(radius), 25.0, accuracy: 0.001, "index \(index) radius should be 25")
        }
    }

    // MARK: - particleOffset(for:) — even angular spacing
    // atan2 wraps at ±π, so normalise the difference into (-π, π] before comparing.

    func testParticleOffsetAnglesAreEvenlySpaced() {
        for index in 0..<7 {
            let a = sut.particleOffset(for: index)
            let b = sut.particleOffset(for: index + 1)
            let angleA = atan2(Double(a.height), Double(a.width))
            let angleB = atan2(Double(b.height), Double(b.width))
            var diff = angleB - angleA
            if diff <= -.pi { diff += 2 * .pi }
            if diff >   .pi { diff -= 2 * .pi }
            XCTAssertEqual(diff, .pi / 4, accuracy: 0.001,
                           "angle step between index \(index) and \(index + 1) should be π/4")
        }
    }

    func testParticleOffset8IndicesCompleteFullCircle() {
        let first   = sut.particleOffset(for: 0)
        let wrapped = sut.particleOffset(for: 8)
        XCTAssertEqual(first.width,  wrapped.width,  accuracy: 0.001)
        XCTAssertEqual(first.height, wrapped.height, accuracy: 0.001)
    }

    // MARK: - particleOffset(for:) — diagonal symmetry

    func testParticleOffsetIndex1IsTopRightDiagonal() {
        let offset = sut.particleOffset(for: 1)
        // angle = π/4 → cos(π/4) = sin(π/4) = √2/2, so both components = 25/√2 ≈ 17.677
        let expected = 25.0 / 2.0.squareRoot()
        XCTAssertEqual(Double(offset.width),  expected, accuracy: 0.001)
        XCTAssertEqual(Double(offset.height), expected, accuracy: 0.001)
    }

    func testParticleOffsetOppositeIndicesSumToZero() {
        // Indices 4 apart are diametrically opposite; their offsets must cancel
        for index in 0..<4 {
            let a = sut.particleOffset(for: index)
            let b = sut.particleOffset(for: index + 4)
            XCTAssertEqual(Double(a.width  + b.width),  0.0, accuracy: 0.001,
                           "x offsets at index \(index) and \(index + 4) should sum to 0")
            XCTAssertEqual(Double(a.height + b.height), 0.0, accuracy: 0.001,
                           "y offsets at index \(index) and \(index + 4) should sum to 0")
        }
    }
}
