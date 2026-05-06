import XCTest
@testable import RecipeFinder

final class DifficultyBarsViewTests: XCTestCase {

    private typealias Layout = DifficultyBarsView.Layout

    // MARK: - filledBars

    func testEasyReturnsOnebar() {
        let sut = DifficultyBarsView(difficulty: "easy")
        XCTAssertEqual(sut.filledBars, 1)
    }

    func testMediumReturnsTwoBars() {
        let sut = DifficultyBarsView(difficulty: "medium")
        XCTAssertEqual(sut.filledBars, 2)
    }

    func testHardReturnsThreeBars() {
        let sut = DifficultyBarsView(difficulty: "hard")
        XCTAssertEqual(sut.filledBars, 3)
    }

    func testUnknownDifficultyDefaultsToTwoBars() {
        let sut = DifficultyBarsView(difficulty: "extreme")
        XCTAssertEqual(sut.filledBars, 2)
    }

    func testEmptyDifficultyDefaultsToTwoBars() {
        let sut = DifficultyBarsView(difficulty: "")
        XCTAssertEqual(sut.filledBars, 2)
    }

    func testFilledBarsIsCaseInsensitive() {
        XCTAssertEqual(DifficultyBarsView(difficulty: "EASY").filledBars, 1)
        XCTAssertEqual(DifficultyBarsView(difficulty: "Medium").filledBars, 2)
        XCTAssertEqual(DifficultyBarsView(difficulty: "HARD").filledBars, 3)
    }

    // MARK: - cascadingHeight

    func testIndex0HeightUsesFirstMultiplier() {
        let size: CGFloat = 4
        let sut = DifficultyBarsView(difficulty: "easy", size: size)
        XCTAssertEqual(sut.cascadingHeight(for: 0), size * Layout.heightMultipliers[0])
    }

    func testIndex1HeightUsesSecondMultiplier() {
        let size: CGFloat = 4
        let sut = DifficultyBarsView(difficulty: "easy", size: size)
        XCTAssertEqual(sut.cascadingHeight(for: 1), size * Layout.heightMultipliers[1])
    }

    func testIndex2HeightUsesThirdMultiplier() {
        let size: CGFloat = 4
        let sut = DifficultyBarsView(difficulty: "easy", size: size)
        XCTAssertEqual(sut.cascadingHeight(for: 2), size * Layout.heightMultipliers[2])
    }

    func testHeightScalesWithSize() {
        let sut1 = DifficultyBarsView(difficulty: "easy", size: 4)
        let sut2 = DifficultyBarsView(difficulty: "easy", size: 8)
        XCTAssertEqual(sut2.cascadingHeight(for: 0), sut1.cascadingHeight(for: 0) * 2)
    }

    func testOutOfBoundsIndexDefaultsToMiddleMultiplier() {
        let size: CGFloat = 4
        let sut = DifficultyBarsView(difficulty: "easy", size: size)
        XCTAssertEqual(sut.cascadingHeight(for: 99), size * Layout.heightMultipliers[1])
    }

    func testHeightIsStrictlyIncreasing() {
        let sut = DifficultyBarsView(difficulty: "easy", size: 4)
        for index in 0..<(Layout.barCount - 1) {
            XCTAssertLessThan(
                sut.cascadingHeight(for: index),
                sut.cascadingHeight(for: index + 1),
                "bar \(index) should be shorter than bar \(index + 1)"
            )
        }
    }
}
