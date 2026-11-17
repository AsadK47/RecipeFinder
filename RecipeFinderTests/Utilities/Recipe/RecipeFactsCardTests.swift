import Testing
import SwiftUI
import ViewInspector
@testable import RecipeFinder

/// Recipe detail facts card: when values are too long for one row, they split into two balanced rows.
@Suite struct RecipeFactRowsTests {
    @Test(arguments: [
        (4, [[0, 1], [2, 3]]),
        (5, [[0, 1, 2], [3, 4]]),
        (1, [[0]]),
        (0, []),
    ])
    func factsSplitIntoTwoBalancedRows(count: Int, expected: [[Int]]) {
        #expect(RecipeDetailCopy.factRows(count: count) == expected)
    }
}

/// Characterisation (Smell Batch A slice 3): each fact keeps the tint it had before the card moved out of
/// RecipeDetailView+Content.
@MainActor @Suite struct RecipeFactTintTests {
    @Test(arguments: [(RecipeFactKind.prep, Color.orange), (.cook, .red), (.difficulty, .blue),
                      (.category, .green), (.cuisine, .teal)])
    func factTintsUnchanged(kind: RecipeFactKind, tint: Color) {
        #expect(kind.tint == tint)
    }
}

/// Notes section body: imported recipes link back to the original page; hand-written ones show no link.
@MainActor @Suite struct RecipeNotesContentTests {
    @Test func importedRecipeShowsViewOriginal() throws {
        let url = try #require(URL(string: "https://example.com/stew"))
        let view = try RecipeNotesContent(notes: "Serve hot.", originalURL: url).inspect()
        _ = try view.find(ViewType.Link.self)
    }

    @Test func noURLShowsNoLink() throws {
        let view = try RecipeNotesContent(notes: "Serve hot.", originalURL: nil).inspect()
        #expect(throws: (any Error).self) { try view.find(ViewType.Link.self) }
    }

    @Test func urlOnlyStillShowsTheLink() throws {
        let url = try #require(URL(string: "https://example.com/stew"))
        let view = try RecipeNotesContent(notes: "", originalURL: url).inspect()
        _ = try view.find(ViewType.Link.self)
    }
}
