import Testing
import Foundation
@testable import RecipeFinder

@MainActor
@Suite("DifficultyBarsView")
struct DifficultyBarsViewTests {

    private typealias Layout = DifficultyBarsView.Layout

    // MARK: - filledBars

    @Test("Difficulty maps to filled-bar count, case-insensitively, defaulting to 2", arguments: [
        ("easy", 1),
        ("medium", 2),
        ("hard", 3),
        ("EASY", 1),        // case-insensitive
        ("Medium", 2),
        ("HARD", 3),
        ("extreme", 2),     // unknown difficulty → default of 2
        ("", 2)             // empty difficulty → default of 2
    ])
    func filledBarsForDifficulty(label: String, expected: Int) {
        #expect(DifficultyBarsView(difficulty: label).filledBars == expected)
    }

    // MARK: - cascadingHeight

    @Test("Each bar's height is its size scaled by that bar's multiplier", arguments: [0, 1, 2])
    func heightUsesMultiplierForIndex(index: Int) {
        let size: CGFloat = 4
        let sut = DifficultyBarsView(difficulty: "easy", size: size)
        #expect(sut.cascadingHeight(for: index) == size * Layout.heightMultipliers[index])
    }

    @Test("Bar heights scale linearly with the view's size")
    func heightScalesWithSize() {
        let small = DifficultyBarsView(difficulty: "easy", size: 4)
        let large = DifficultyBarsView(difficulty: "easy", size: 8)
        #expect(large.cascadingHeight(for: 0) == small.cascadingHeight(for: 0) * 2)
    }

    @Test("An out-of-range bar index falls back to the middle multiplier")
    func outOfBoundsIndexUsesMiddleMultiplier() {
        let size: CGFloat = 4
        let sut = DifficultyBarsView(difficulty: "easy", size: size)
        #expect(sut.cascadingHeight(for: 99) == size * Layout.heightMultipliers[1])
    }

    @Test("Bars cascade: each is taller than the one before it")
    func heightsAreStrictlyIncreasing() {
        let sut = DifficultyBarsView(difficulty: "easy", size: 4)
        for index in 0..<(Layout.barCount - 1) {
            #expect(sut.cascadingHeight(for: index) < sut.cascadingHeight(for: index + 1))
        }
    }
}
