import Testing
import Foundation
@testable import RecipeFinder

@Suite("RecipeNotesFormatter")
struct RecipeNotesFormatterTests {

    @Test("Plain notes carry no links")
    func plainNotesHaveNoLinks() {
        let result = RecipeNotesFormatter.attributedString(from: "Just some notes")
        #expect(String(result.characters) == "Just some notes")
        for run in result.runs {
            #expect(run.link == nil)
        }
    }

    @Test("A URL in the notes becomes a styled link")
    func urlBecomesLink() throws {
        let result = RecipeNotesFormatter.attributedString(from: "See https://example.com for more")

        let linkedRun = try #require(result.runs.first { $0.link != nil })
        #expect(linkedRun.link == URL(string: "https://example.com"))
        #expect(linkedRun.underlineStyle == .single)
    }

    @Test("The full text is preserved regardless of links")
    func textPreserved() {
        let notes = "Visit https://example.com now"
        let result = RecipeNotesFormatter.attributedString(from: notes)
        #expect(String(result.characters) == notes)
    }
}
