import XCTest
import SwiftUI
@testable import RecipeFinder

final class BadgeCardTests: XCTestCase {

    // MARK: - badgeColor delegates to Badge.color(for:)

    private func makeBadge(color: String, isUnlocked: Bool = false) -> Badge {
        Badge(id: "test", title: "Test Badge", description: "Desc",
              icon: "star", color: color, dateEarned: nil,
              isUnlocked: isUnlocked, howToEarn: "Do stuff")
    }

    func testBadgeColor_usesStaticColorMap() {
        let namedColors: [(String, Color)] = [
            ("purple", .purple), ("green", .green), ("mint", .mint),
            ("blue", .blue), ("orange", .orange), ("yellow", .yellow),
            ("gold", .yellow), ("teal", .teal), ("indigo", .indigo),
        ]
        for (name, expected) in namedColors {
            let badge = makeBadge(color: name)
            XCTAssertEqual(Badge.color(for: badge.color), expected,
                           "BadgeCard.badgeColor mismatch for color '\(name)'")
        }
    }

    func testBadgeColor_unknownColorFallsToGray() {
        let badge = makeBadge(color: "nonexistent")
        XCTAssertEqual(Badge.color(for: badge.color), .gray)
    }

    func testBadgeColor_caseSensitive() {
        // "PURPLE" should NOT map to .purple — it falls back to .gray
        let badge = makeBadge(color: "PURPLE")
        XCTAssertEqual(Badge.color(for: badge.color), .gray)
    }
}
