import Testing
import Foundation
@testable import RecipeFinder

@Suite struct NoteFilterCriteriaTests {

    // MARK: - Fixtures

    private static func note(
        title: String = "",
        content: String = "",
        category: NoteCategory = .general,
        tags: [String] = [],
        isPinned: Bool = false
    ) -> NoteModel {
        NoteModel(title: title, content: content, category: category, tags: tags, isPinned: isPinned)
    }

    private static let sample: [NoteModel] = [
        note(title: "Sourdough starter", content: "feed daily", category: .recipe, tags: ["bread"], isPinned: true),
        note(title: "Weekly shop", content: "milk and eggs", category: .shopping, tags: ["staples"], isPinned: false),
        note(title: "Knife skills", content: "practice the claw grip", category: .techniques, tags: ["bread", "prep"], isPinned: false),
        note(title: "Ramen night", content: "broth ideas", category: .recipe, tags: ["dinner"], isPinned: true)
    ]

    // MARK: - apply(to:) — no filters

    @Test func emptyCriteria_returnsAllNotes() {
        let criteria = NoteFilterCriteria()
        #expect(criteria.apply(to: Self.sample).count == Self.sample.count)
    }

    // MARK: - apply(to:) — searchText

    @Test func searchText_matchesTitleContentOrTags_caseInsensitive() {
        var criteria = NoteFilterCriteria()
        criteria.searchText = "BREAD"
        let titles = criteria.apply(to: Self.sample).map(\.title)
        #expect(Set(titles) == ["Sourdough starter", "Knife skills"])
    }

    @Test func searchText_noMatch_returnsEmpty() {
        var criteria = NoteFilterCriteria()
        criteria.searchText = "zzz-nonexistent"
        #expect(criteria.apply(to: Self.sample).isEmpty)
    }

    // MARK: - apply(to:) — category

    @Test func selectedCategory_keepsOnlyThatCategory() {
        var criteria = NoteFilterCriteria()
        criteria.selectedCategory = .recipe
        #expect(criteria.apply(to: Self.sample).allSatisfy { $0.category == .recipe })
        #expect(criteria.apply(to: Self.sample).count == 2)
    }

    // MARK: - apply(to:) — tag

    @Test func selectedTag_keepsOnlyNotesWithExactTag() {
        var criteria = NoteFilterCriteria()
        criteria.selectedTag = "bread"
        let titles = criteria.apply(to: Self.sample).map(\.title)
        #expect(Set(titles) == ["Sourdough starter", "Knife skills"])
    }

    // MARK: - apply(to:) — pinned

    @Test func showPinnedOnly_keepsOnlyPinned() {
        var criteria = NoteFilterCriteria()
        criteria.showPinnedOnly = true
        #expect(criteria.apply(to: Self.sample).allSatisfy { $0.isPinned })
        #expect(criteria.apply(to: Self.sample).count == 2)
    }

    // MARK: - apply(to:) — combined (AND)

    @Test func filtersCombineWithAnd() {
        var criteria = NoteFilterCriteria()
        criteria.selectedCategory = .recipe
        criteria.showPinnedOnly = true
        criteria.selectedTag = "dinner"
        let titles = criteria.apply(to: Self.sample).map(\.title)
        #expect(titles == ["Ramen night"])
    }

    // MARK: - activeCount

    @Test func activeCount_isZeroForEmptyCriteria() {
        #expect(NoteFilterCriteria().activeCount == 0)
    }

    @Test func activeCount_excludesFreeTextSearch() {
        var criteria = NoteFilterCriteria()
        criteria.searchText = "anything"
        #expect(criteria.activeCount == 0)
    }

    @Test func activeCount_countsCategoryTagAndPinned() {
        var criteria = NoteFilterCriteria()
        criteria.selectedCategory = .recipe
        criteria.selectedTag = "bread"
        criteria.showPinnedOnly = true
        #expect(criteria.activeCount == 3)
    }
}
