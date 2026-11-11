import Testing
import Foundation
@testable import RecipeFinder

/// Today's "Copied a recipe link?" card: which pasted link goes to the importer, and when the card shows.
@Suite struct ClipboardRecipeLinkTests {

    @Test(arguments: [
        ("https://www.bbcgoodfood.com/recipes/lemon-drizzle", "https://www.bbcgoodfood.com/recipes/lemon-drizzle"),
        ("  http://example.com/stew  \n", "http://example.com/stew"),
        ("Made this last night!! https://cooking.example.org/pasta?x=1 so good", "https://cooking.example.org/pasta?x=1"),
        ("Try it (https://example.com/curry).", "https://example.com/curry"),
        ("HTTPS://EXAMPLE.COM/Soup", "HTTPS://EXAMPLE.COM/Soup"),
    ])
    func findsTheWebLinkInPastedText(pasted: String, expected: String) {
        #expect(ClipboardRecipeLink.url(in: [pasted])?.absoluteString == expected)
    }

    @Test(arguments: [
        "",
        "just some text about dinner",
        "ftp://example.com/recipe",
        "mailto:someone@example.com",
        "https://",
        "file:///Users/me/recipe.txt",
    ])
    func ignoresTextWithoutAWebLink(pasted: String) {
        #expect(ClipboardRecipeLink.url(in: [pasted]) == nil)
    }

    @Test func takesTheFirstLinkAcrossPastedItems() {
        let url = ClipboardRecipeLink.url(in: ["no link here", "https://a.example.com/1 https://b.example.com/2"])
        #expect(url?.absoluteString == "https://a.example.com/1")
    }

    @Test func noPastedItemsMeansNoLink() {
        #expect(ClipboardRecipeLink.url(in: []) == nil)
    }

    @Test func offersWhenTheClipboardHasALinkNotYetHandled() {
        #expect(ClipboardRecipeLink.shouldOffer(hasWebLink: true, changeCount: 7, handledChangeCount: nil))
        #expect(ClipboardRecipeLink.shouldOffer(hasWebLink: true, changeCount: 8, handledChangeCount: 7))
    }

    @Test func hidesOnceThatCopyWasPastedOrDismissed() {
        #expect(!ClipboardRecipeLink.shouldOffer(hasWebLink: true, changeCount: 7, handledChangeCount: 7))
    }

    @Test func hidesWithoutALink() {
        #expect(!ClipboardRecipeLink.shouldOffer(hasWebLink: false, changeCount: 7, handledChangeCount: nil))
    }
}
