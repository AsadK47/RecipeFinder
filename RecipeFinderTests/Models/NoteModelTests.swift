import XCTest
@testable import RecipeFinder

final class NoteModelTests: XCTestCase {

    // MARK: - matches(searchText:)

    func testMatches_emptySearchText_returnsTrue() {
        XCTAssertTrue(makeNote(title: "Pasta", content: "Boil water", tags: ["italian"]).matches(searchText: ""))
    }

    func testMatches_titleContainsSearchText_returnsTrue() {
        XCTAssertTrue(makeNote(title: "Pasta recipe").matches(searchText: "pasta"))
    }

    func testMatches_titleCaseInsensitive_returnsTrue() {
        XCTAssertTrue(makeNote(title: "Pasta Recipe").matches(searchText: "PASTA"))
    }

    func testMatches_contentContainsSearchText_returnsTrue() {
        XCTAssertTrue(makeNote(content: "Add olive oil to the pan").matches(searchText: "olive"))
    }

    func testMatches_tagContainsSearchText_returnsTrue() {
        XCTAssertTrue(makeNote(tags: ["italian", "quick"]).matches(searchText: "quick"))
    }

    func testMatches_partialTagMatch_returnsTrue() {
        XCTAssertTrue(makeNote(tags: ["italian"]).matches(searchText: "ital"))
    }

    func testMatches_noMatchInAnyField_returnsFalse() {
        let note = makeNote(title: "Pasta", content: "Boil water", tags: ["italian"])
        XCTAssertFalse(note.matches(searchText: "sushi"))
    }

    func testMatches_emptyNote_emptySearch_returnsTrue() {
        XCTAssertTrue(makeNote().matches(searchText: ""))
    }

    func testMatches_emptyNote_withSearch_returnsFalse() {
        XCTAssertFalse(makeNote().matches(searchText: "anything"))
    }

    // MARK: - NoteCategory.topCategories / moreCategories

    func testTopCategories_containsExpectedItems() {
        XCTAssertTrue(NoteCategory.topCategories.contains(.general))
        XCTAssertTrue(NoteCategory.topCategories.contains(.recipe))
        XCTAssertTrue(NoteCategory.topCategories.contains(.shopping))
    }

    func testTopAndMoreCategories_coverAllCases() {
        let all = Set(NoteCategory.allCases)
        let covered = Set(NoteCategory.topCategories + NoteCategory.moreCategories)
        XCTAssertEqual(all, covered)
    }

    func testTopAndMoreCategories_haveNoOverlap() {
        let top = Set(NoteCategory.topCategories)
        let more = Set(NoteCategory.moreCategories)
        XCTAssertTrue(top.isDisjoint(with: more))
    }

    // MARK: - NoteCategory.icon

    func testCategoryIcon_allCasesHaveNonEmptyIcon() {
        for category in NoteCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category) has empty icon")
        }
    }

    // MARK: - Helpers

    private func makeNote(
        title: String = "",
        content: String = "",
        tags: [String] = []
    ) -> NoteModel {
        NoteModel(title: title, content: content, tags: tags)
    }
}
