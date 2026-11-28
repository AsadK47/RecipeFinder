import Testing
import Foundation
@testable import RecipeFinder

/// Which link a shared caption or pasted text hands to the importer: the first web page link, never an email.
@Suite struct RecipeLinkTests {

    @Test(arguments: [
        ("https://www.bbcgoodfood.com/recipes/lemon-drizzle", "https://www.bbcgoodfood.com/recipes/lemon-drizzle"),
        ("Questions? cook@example.com — recipe: https://cooking.test/stew", "https://cooking.test/stew"),
        ("mailto:cook@example.com then http://example.com/soup", "http://example.com/soup"),
        ("Try it (https://example.com/curry).", "https://example.com/curry"),
        ("https://a.example.com/1 https://b.example.com/2", "https://a.example.com/1"),
    ])
    func findsTheFirstWebLink(text: String, expected: String) {
        #expect(RecipeLink.first(in: text)?.absoluteString == expected)
    }

    @Test(arguments: [
        "",
        "just some text about dinner",
        "Send your version to cook@example.com",
        "mailto:cook@example.com",
        "ftp://example.com/recipe",
        "file:///Users/me/recipe.txt",
        "bbcgoodfood.com/recipes/lemon-drizzle",
        "www.example.com/stew",
    ])
    func ignoresTextWithoutAWebLink(text: String) {
        #expect(RecipeLink.first(in: text) == nil)
    }
}
