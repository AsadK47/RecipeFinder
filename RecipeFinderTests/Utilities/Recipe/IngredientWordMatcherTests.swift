import Testing
@testable import RecipeFinder

@Suite("IngredientWordMatcher")
struct IngredientWordMatcherTests {

    // MARK: - Whole-word matching (the bug class)

    @Test(
        "A keyword hidden inside a longer word does not match",
        arguments: [
            ("graham cracker", "ham"),   // not Meat
            ("popcorn", "corn"),         // not Produce
            ("salted butter", "salt"),   // not salt density
            ("ginger", "gin"),
            ("rice", "ice")
        ]
    )
    func substringInsideWordDoesNotMatch(text: String, keyword: String) {
        #expect(!IngredientWordMatcher.matches(text: text, keyword: keyword))
    }

    @Test(
        "A whole word matches",
        arguments: [
            ("sweet corn", "corn"),
            ("ground beef", "beef"),
            ("olive oil", "oil"),
            ("salt", "salt")
        ]
    )
    func wholeWordMatches(text: String, keyword: String) {
        #expect(IngredientWordMatcher.matches(text: text, keyword: keyword))
    }

    // MARK: - Multi-word keywords

    @Test("A multi-word keyword matches a contiguous run of words")
    func multiWordKeywordMatches() {
        #expect(IngredientWordMatcher.matches(text: "ice cream sundae", keyword: "ice cream"))
        #expect(IngredientWordMatcher.matches(text: "extra virgin olive oil", keyword: "olive oil"))
    }

    @Test("A multi-word keyword does not match when the words are not contiguous")
    func multiWordKeywordRequiresContiguity() {
        #expect(!IngredientWordMatcher.matches(text: "oil in olive tapenade", keyword: "olive oil"))
    }

    // MARK: - Simple plurals

    @Test(
        "Simple English plurals match in either direction",
        arguments: [
            ("onions", "onion"),
            ("onion", "onions"),
            ("tomatoes", "tomato"),
            ("green beans", "green bean")
        ]
    )
    func pluralsMatch(text: String, keyword: String) {
        #expect(IngredientWordMatcher.matches(text: text, keyword: keyword))
    }

    // MARK: - Tokenisation edge cases

    @Test("Punctuation is treated as a word boundary")
    func punctuationSplitsWords() {
        #expect(IngredientWordMatcher.matches(text: "onion, diced", keyword: "onion"))
        #expect(IngredientWordMatcher.matches(text: "extra-virgin olive oil", keyword: "olive oil"))
    }

    @Test("An empty keyword never matches")
    func emptyKeyword() {
        #expect(!IngredientWordMatcher.matches(text: "anything", keyword: ""))
    }
}
