import Testing
import Foundation
@testable import RecipeFinder

@Suite struct BackupMergeTests {

    private static func note(_ title: String, id: UUID = UUID()) -> NoteModel {
        NoteModel(id: id, title: title, content: "", category: .general)
    }

    private static func recipe(_ name: String, id: UUID = UUID()) -> RecipeModel {
        RecipeModel(name: name, category: "Main", difficulty: "Basic", prepTime: "5 min",
                    cookingTime: "10 min", baseServings: 2, ingredients: [],
                    prePrepInstructions: [], instructions: ["step"], notes: "")
    }

    private static func badge(_ id: String, earned: Date? = nil) -> Badge {
        Badge(id: id, title: id, description: "", icon: "", color: "green", dateEarned: earned, isUnlocked: earned != nil)
    }

    // MARK: - merged(existing:incoming:) by identity

    @Test func merged_appendsOnlyNewIDs_preservingOrder() {
        let keep = Self.note("A")
        let dupeID = UUID()
        let existing = [keep, Self.note("B", id: dupeID)]
        let incoming = [Self.note("B-again", id: dupeID), Self.note("C")]

        let result = BackupMerge.merged(existing: existing, incoming: incoming)

        #expect(result.map(\.title) == ["A", "B", "C"]) // dupe id skipped; new appended in order
    }

    @Test func merged_intoEmpty_returnsIncoming() {
        let incoming = [Self.note("A"), Self.note("B")]
        #expect(BackupMerge.merged(existing: [NoteModel](), incoming: incoming).map(\.title) == ["A", "B"])
    }

    @Test func merged_noIncoming_returnsExistingUnchanged() {
        let existing = [Self.note("A")]
        #expect(BackupMerge.merged(existing: existing, incoming: []).map(\.id) == existing.map(\.id))
    }

    // MARK: - mergedRecipes: id + normalized-name dedupe

    @Test func mergedRecipes_skipsSameId() {
        let id = UUID()
        let existing = [Self.recipe("Soup", id: id)]
        let incoming = [Self.recipe("Soup", id: id)]
        #expect(BackupMerge.mergedRecipes(existing: existing, incoming: incoming).count == 1)
    }

    @Test func mergedRecipes_skipsSameName_evenWithDifferentId() {
        let existing = [Self.recipe("Chicken Soup")]
        let incoming = [Self.recipe("  chicken soup  ")] // different id, same normalized name
        let result = BackupMerge.mergedRecipes(existing: existing, incoming: incoming)
        #expect(result.count == 1)
        #expect(result.first?.name == "Chicken Soup") // existing kept
    }

    @Test func mergedRecipes_keepsGenuinelyNew() {
        let existing = [Self.recipe("Soup")]
        let incoming = [Self.recipe("Stew"), Self.recipe("Pie")]
        #expect(BackupMerge.mergedRecipes(existing: existing, incoming: incoming).map(\.name) == ["Soup", "Stew", "Pie"])
    }

    // MARK: - mergedBadges: union, existing wins

    @Test func mergedBadges_unionsAndKeepsExistingOnCollision() {
        let mine = Date(timeIntervalSince1970: 1_000)
        let existing = ["first": Self.badge("first", earned: mine)]
        let incoming = [
            "first": Self.badge("first", earned: Date(timeIntervalSince1970: 2_000)), // collision
            "second": Self.badge("second", earned: Date(timeIntervalSince1970: 3_000))
        ]
        let result = BackupMerge.mergedBadges(existing: existing, incoming: incoming)
        #expect(Set(result.keys) == ["first", "second"])
        #expect(result["first"]?.dateEarned == mine) // existing preserved
    }
}
