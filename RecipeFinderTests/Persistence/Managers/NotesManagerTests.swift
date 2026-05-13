import XCTest
@testable import RecipeFinder

@MainActor
final class NotesManagerTests: XCTestCase {

    private var storage: UserScopedStorage!
    private var sut: NotesManager!

    override func setUp() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        storage = UserScopedStorage(userDefaults: defaults)
        storage.currentUserId = "test_user"
        sut = NotesManager(storage: storage)
    }

    override func tearDown() async throws {
        sut = nil
        storage = nil
    }

    // MARK: - Initial state

    func testInitialState_isEmpty() {
        XCTAssertEqual(sut.notes.count, 0)
        XCTAssertEqual(sut.totalNotes, 0)
        XCTAssertEqual(sut.pinnedNotesCount, 0)
    }

    // MARK: - addNote

    func testAddNote_insertsNote() {
        sut.addNote(makeNote(title: "Test"))
        XCTAssertEqual(sut.notes.count, 1)
        XCTAssertEqual(sut.notes[0].title, "Test")
    }

    func testAddNote_stampsBothDates() {
        let before = Date()
        sut.addNote(makeNote())
        let note = sut.notes[0]
        XCTAssertGreaterThanOrEqual(note.createdDate, before)
        XCTAssertGreaterThanOrEqual(note.modifiedDate, before)
    }

    func testAddNote_insertsAtFront() {
        sut.addNote(makeNote(title: "First"))
        sut.addNote(makeNote(title: "Second"))
        XCTAssertEqual(sut.notes[0].title, "Second")
    }

    func testAddNote_persistsAcrossReload() {
        sut.addNote(makeNote(title: "Persistent"))
        let sut2 = NotesManager(storage: storage)
        XCTAssertEqual(sut2.notes.count, 1)
        XCTAssertEqual(sut2.notes[0].title, "Persistent")
    }

    // MARK: - updateNote

    func testUpdateNote_modifiesContent() {
        let note = makeNote(title: "Original")
        sut.addNote(note)
        var updated = sut.notes[0]
        updated.title = "Updated"
        sut.updateNote(updated)
        XCTAssertEqual(sut.notes.first(where: { $0.id == updated.id })?.title, "Updated")
    }

    func testUpdateNote_stampsModifiedDate() {
        sut.addNote(makeNote())
        var note = sut.notes[0]
        let originalModified = note.modifiedDate
        Thread.sleep(forTimeInterval: 0.01)
        note.title = "Changed"
        sut.updateNote(note)
        let newModified = sut.notes.first(where: { $0.id == note.id })!.modifiedDate
        XCTAssertGreaterThan(newModified, originalModified)
    }

    func testUpdateNote_unknownId_doesNothing() {
        sut.addNote(makeNote(title: "A"))
        let countBefore = sut.notes.count
        sut.updateNote(makeNote(title: "Ghost"))
        XCTAssertEqual(sut.notes.count, countBefore)
    }

    // MARK: - deleteNote

    func testDeleteNote_removesNote() {
        let note = makeNote()
        sut.addNote(note)
        sut.deleteNote(sut.notes[0])
        XCTAssertTrue(sut.notes.isEmpty)
    }

    func testDeleteNote_unknownId_doesNothing() {
        sut.addNote(makeNote())
        sut.deleteNote(makeNote())
        XCTAssertEqual(sut.notes.count, 1)
    }

    // MARK: - togglePin

    func testTogglePin_pinsThenUnpins() {
        sut.addNote(makeNote())
        let id = sut.notes[0].id
        sut.togglePin(sut.notes[0])
        XCTAssertTrue(sut.notes.first(where: { $0.id == id })!.isPinned)
        sut.togglePin(sut.notes.first(where: { $0.id == id })!)
        XCTAssertFalse(sut.notes.first(where: { $0.id == id })!.isPinned)
    }

    func testTogglePin_pinnedNoteMovesToFront() {
        sut.addNote(makeNote(title: "B"))
        sut.addNote(makeNote(title: "A"))
        // "A" is at index 0, "B" at 1
        let bNote = sut.notes.first(where: { $0.title == "B" })!
        sut.togglePin(bNote)
        XCTAssertEqual(sut.notes[0].title, "B")
    }

    // MARK: - filteredNotes (searchText)

    func testFilteredNotes_searchText_matchesTitle() {
        sut.addNote(makeNote(title: "Pasta recipe", content: "boil water"))
        sut.addNote(makeNote(title: "Salad", content: "mix greens"))
        let results = sut.filteredNotes(searchText: "pasta", category: nil, showPinnedOnly: false)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].title, "Pasta recipe")
    }

    func testFilteredNotes_searchText_matchesContent() {
        sut.addNote(makeNote(title: "Note", content: "chocolate cake"))
        let results = sut.filteredNotes(searchText: "chocolate", category: nil, showPinnedOnly: false)
        XCTAssertEqual(results.count, 1)
    }

    func testFilteredNotes_emptySearchText_returnsAll() {
        sut.addNote(makeNote(title: "A"))
        sut.addNote(makeNote(title: "B"))
        let results = sut.filteredNotes(searchText: "", category: nil, showPinnedOnly: false)
        XCTAssertEqual(results.count, 2)
    }

    // MARK: - filteredNotes (category)

    func testFilteredNotes_category_returnsCategoryMatch() {
        sut.addNote(makeNote(title: "Recipe Note", category: .recipe))
        sut.addNote(makeNote(title: "General Note", category: .general))
        let results = sut.filteredNotes(searchText: "", category: .recipe, showPinnedOnly: false)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].category, .recipe)
    }

    func testFilteredNotes_nilCategory_returnsAll() {
        sut.addNote(makeNote(category: .recipe))
        sut.addNote(makeNote(category: .general))
        let results = sut.filteredNotes(searchText: "", category: nil, showPinnedOnly: false)
        XCTAssertEqual(results.count, 2)
    }

    // MARK: - filteredNotes (showPinnedOnly)

    func testFilteredNotes_showPinnedOnly_onlyReturnsPinned() {
        sut.addNote(makeNote(title: "Pinned", isPinned: true))
        sut.addNote(makeNote(title: "Not pinned", isPinned: false))
        let results = sut.filteredNotes(searchText: "", category: nil, showPinnedOnly: true)
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results[0].isPinned)
    }

    // MARK: - Computed properties

    func testTotalNotes_countsAllNotes() {
        sut.addNote(makeNote())
        sut.addNote(makeNote())
        XCTAssertEqual(sut.totalNotes, 2)
    }

    func testPinnedNotesCount_countsPinnedOnly() {
        sut.addNote(makeNote(isPinned: true))
        sut.addNote(makeNote(isPinned: false))
        XCTAssertEqual(sut.pinnedNotesCount, 1)
    }

    func testNotesCount_forCategory() {
        sut.addNote(makeNote(category: .recipe))
        sut.addNote(makeNote(category: .recipe))
        sut.addNote(makeNote(category: .general))
        XCTAssertEqual(sut.notesCount(for: .recipe), 2)
        XCTAssertEqual(sut.notesCount(for: .general), 1)
    }

    // MARK: - Sort order

    func testSort_pinnedNotesAppearBeforeUnpinned() {
        sut.addNote(makeNote(title: "Unpinned", isPinned: false))
        sut.addNote(makeNote(title: "Pinned", isPinned: true))
        XCTAssertTrue(sut.notes[0].isPinned)
        XCTAssertFalse(sut.notes[1].isPinned)
    }

    // MARK: - Helpers

    private func makeNote(
        title: String = "Note",
        content: String = "",
        category: NoteCategory = .general,
        isPinned: Bool = false
    ) -> NoteModel {
        NoteModel(title: title, content: content, category: category, isPinned: isPinned)
    }
}
