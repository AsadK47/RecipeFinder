import XCTest
@testable import RecipeFinder

final class FlowLayoutTests: XCTestCase {

    private enum Fixture {
        static let maxWidth: CGFloat = 300
        static let spacing: CGFloat = 8
        static let itemWidth: CGFloat = 100
        static let itemHeight: CGFloat = 30
        static let wideItemWidth: CGFloat = 200
        static let tallItemHeight: CGFloat = 50
        static let smallItemWidth: CGFloat = 80
        static let smallItemHeight: CGFloat = 20
    }

    // MARK: - Empty

    func testEmptyItemsProducesZeroHeight() {
        let result = FlowLayout.FlowResult(in: Fixture.maxWidth, sizes: [], spacing: Fixture.spacing)
        XCTAssertEqual(result.size.height, 0)
    }

    func testEmptyItemsProducesNoPositions() {
        let result = FlowLayout.FlowResult(in: Fixture.maxWidth, sizes: [], spacing: Fixture.spacing)
        XCTAssertTrue(result.positions.isEmpty)
    }

    // MARK: - Single item

    func testSingleItemPositionIsOrigin() {
        let result = FlowLayout.FlowResult(in: Fixture.maxWidth, sizes: [CGSize(width: Fixture.itemWidth, height: Fixture.itemHeight)], spacing: Fixture.spacing)
        XCTAssertEqual(result.positions[0], CGPoint(x: 0, y: 0))
    }

    func testSingleItemHeightEqualsItemHeight() {
        let result = FlowLayout.FlowResult(in: Fixture.maxWidth, sizes: [CGSize(width: Fixture.itemWidth, height: Fixture.itemHeight)], spacing: Fixture.spacing)
        XCTAssertEqual(result.size.height, Fixture.itemHeight)
    }

    func testSingleItemSizeWidthEqualsMaxWidth() {
        let result = FlowLayout.FlowResult(in: Fixture.maxWidth, sizes: [CGSize(width: Fixture.itemWidth, height: Fixture.itemHeight)], spacing: Fixture.spacing)
        XCTAssertEqual(result.size.width, Fixture.maxWidth)
    }

    // MARK: - Same line placement

    func testTwoItemsThatFitShareTheSameLine() {
        let sizes = [CGSize(width: Fixture.itemWidth, height: Fixture.itemHeight),
                     CGSize(width: Fixture.itemWidth, height: Fixture.itemHeight)]
        let result = FlowLayout.FlowResult(in: Fixture.maxWidth, sizes: sizes, spacing: Fixture.spacing)
        XCTAssertEqual(result.positions[0].y, result.positions[1].y)
    }

    func testSecondItemXIncludesFirstWidthAndSpacing() {
        let sizes = [CGSize(width: Fixture.itemWidth, height: Fixture.itemHeight),
                     CGSize(width: Fixture.smallItemWidth, height: Fixture.itemHeight)]
        let result = FlowLayout.FlowResult(in: Fixture.maxWidth, sizes: sizes, spacing: Fixture.spacing)
        XCTAssertEqual(result.positions[1].x, Fixture.itemWidth + Fixture.spacing, accuracy: 0.001)
    }

    // MARK: - Wrapping

    func testItemThatExceedsMaxWidthWrapsToNextLine() {
        let sizes = [CGSize(width: Fixture.wideItemWidth, height: Fixture.itemHeight),
                     CGSize(width: Fixture.wideItemWidth, height: Fixture.itemHeight)]
        let result = FlowLayout.FlowResult(in: Fixture.maxWidth, sizes: sizes, spacing: Fixture.spacing)
        XCTAssertGreaterThan(result.positions[1].y, 0)
    }

    func testWrappedItemStartsAtXZero() {
        let sizes = [CGSize(width: Fixture.wideItemWidth, height: Fixture.itemHeight),
                     CGSize(width: Fixture.wideItemWidth, height: Fixture.itemHeight)]
        let result = FlowLayout.FlowResult(in: Fixture.maxWidth, sizes: sizes, spacing: Fixture.spacing)
        XCTAssertEqual(result.positions[1].x, 0)
    }

    func testWrappedItemYEqualsLineHeightPlusSpacing() {
        let sizes = [CGSize(width: Fixture.wideItemWidth, height: Fixture.itemHeight),
                     CGSize(width: Fixture.wideItemWidth, height: Fixture.itemHeight)]
        let result = FlowLayout.FlowResult(in: Fixture.maxWidth, sizes: sizes, spacing: Fixture.spacing)
        XCTAssertEqual(result.positions[1].y, Fixture.itemHeight + Fixture.spacing, accuracy: 0.001)
    }

    func testTotalHeightAfterWrapIncludesBothLines() {
        let secondItemHeight: CGFloat = 40
        let sizes = [CGSize(width: Fixture.wideItemWidth, height: Fixture.itemHeight),
                     CGSize(width: Fixture.wideItemWidth, height: secondItemHeight)]
        let result = FlowLayout.FlowResult(in: Fixture.maxWidth, sizes: sizes, spacing: Fixture.spacing)
        XCTAssertEqual(result.size.height, Fixture.itemHeight + Fixture.spacing + secondItemHeight, accuracy: 0.001)
    }

    // MARK: - Line height

    func testLineHeightUsesMaxItemHeightOnLine() {
        let sizes = [CGSize(width: Fixture.smallItemWidth, height: Fixture.smallItemHeight),
                     CGSize(width: Fixture.smallItemWidth, height: Fixture.tallItemHeight),
                     CGSize(width: Fixture.wideItemWidth, height: Fixture.itemHeight)]
        let result = FlowLayout.FlowResult(in: Fixture.maxWidth, sizes: sizes, spacing: Fixture.spacing)
        // Items 0 & 1 fit on line 1 (80+8+80=168 ≤ 300), tallest is 50 → item 2 y = 50 + 8
        XCTAssertEqual(result.positions[2].y, Fixture.tallItemHeight + Fixture.spacing, accuracy: 0.001)
    }

    // MARK: - Position count

    func testPositionCountMatchesItemCount() {
        let sizes = [CGSize(width: Fixture.smallItemWidth, height: Fixture.itemHeight),
                     CGSize(width: Fixture.smallItemWidth, height: Fixture.itemHeight),
                     CGSize(width: Fixture.smallItemWidth, height: Fixture.itemHeight)]
        let result = FlowLayout.FlowResult(in: Fixture.maxWidth, sizes: sizes, spacing: Fixture.spacing)
        XCTAssertEqual(result.positions.count, sizes.count)
    }

    // MARK: - Item exactly filling max width

    func testItemExactlyFittingMaxWidthDoesNotWrap() {
        let sizes = [CGSize(width: Fixture.maxWidth, height: Fixture.itemHeight),
                     CGSize(width: Fixture.itemWidth, height: Fixture.itemHeight)]
        let result = FlowLayout.FlowResult(in: Fixture.maxWidth, sizes: sizes, spacing: Fixture.spacing)
        XCTAssertGreaterThan(result.positions[1].y, 0)
        XCTAssertEqual(result.positions[1].x, 0)
    }
}
