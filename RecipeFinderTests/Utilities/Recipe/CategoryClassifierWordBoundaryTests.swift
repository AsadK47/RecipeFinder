import Testing
@testable import RecipeFinder

/// Regression coverage for the substring-conflation bug class in `categorize`:
/// a keyword must match a whole word, not hide inside a longer one.
@Suite("CategoryClassifier word-boundary")
struct CategoryClassifierWordBoundaryTests {

    @Test("'graham' is not classified as Meat via the substring 'ham'")
    func grahamIsNotMeat() {
        #expect(CategoryClassifier.categorize("graham cracker") != "Meat")
    }

    @Test("'popcorn' is not classified as Produce via the substring 'corn'")
    func popcornIsNotProduce() {
        #expect(CategoryClassifier.categorize("popcorn") != "Produce")
    }

    // MARK: - Whole words still classify correctly

    @Test(
        "Whole-word keywords still categorise",
        arguments: [
            ("sweet corn", "Produce"),
            ("ground beef", "Meat"),
            ("olive oil", "Oils & Fats"),
            ("ice cream", "Frozen")
        ]
    )
    func wholeWordsStillCategorise(input: String, expected: String) {
        #expect(CategoryClassifier.categorize(input) == expected)
    }
}
