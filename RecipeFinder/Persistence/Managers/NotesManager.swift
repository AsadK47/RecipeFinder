import Foundation
import Combine

@MainActor
class NotesManager: ObservableObject {
    static let shared = NotesManager()

    @Published var notes: [NoteModel] = []
    
    private let notesKey = "saved_notes"
    private let storage: UserScopedStorage

    private init() {
        self.storage = .shared
        loadNotes()
    }

    init(storage: UserScopedStorage) {
        self.storage = storage
        loadNotes()
    }
    
    func reloadForCurrentUser() {
        loadNotes()
    }
    
    func addNote(_ note: NoteModel) {
        var newNote = note
        newNote.createdDate = Date()
        newNote.modifiedDate = Date()
        notes.insert(newNote, at: 0)
        saveNotes()
    }
    
    func updateNote(_ note: NoteModel) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.modifiedDate = Date()
            notes[index] = updatedNote
            saveNotes()
        }
    }
    
    func deleteNote(_ note: NoteModel) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    func deleteNotes(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        saveNotes()
    }
    
    /// Faithful, non-destructive restore of notes from a backup: unions by id and
    /// persists without re-stamping `createdDate`/`modifiedDate` the way `addNote`
    /// does (that re-stamping was what mangled restored notes in the old export).
    /// Re-sorts so in-memory order matches a fresh load.
    func merge(_ incoming: [NoteModel]) {
        notes = BackupMerge.merged(existing: notes, incoming: incoming)
        sortNotes()
        saveNotes()
    }

    func togglePin(_ note: NoteModel) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isPinned.toggle()
            saveNotes()
            sortNotes()
        }
    }
    
    func filteredNotes(searchText: String, category: NoteCategory?, showPinnedOnly: Bool) -> [NoteModel] {
        var filtered = notes
        
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.matches(searchText: searchText) }
        }
        
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        if showPinnedOnly {
            filtered = filtered.filter { $0.isPinned }
        }
        
        return filtered
    }
    
    func notesByCategory(_ category: NoteCategory) -> [NoteModel] {
        notes.filter { $0.category == category }
    }
    
    func notesLinkedToRecipe(_ recipeID: UUID) -> [NoteModel] {
        notes.filter { $0.linkedRecipeID == recipeID }
    }
    
    private func sortNotes() {
        notes.sort { note1, note2 in
            if note1.isPinned != note2.isPinned {
                return note1.isPinned
            }
            return note1.modifiedDate > note2.modifiedDate
        }
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            storage.set(encoded, forKey: notesKey)
        }
    }
    
    private func loadNotes() {
        if let data = storage.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([NoteModel].self, from: data) {
            notes = decoded
            sortNotes()
        } else {
            notes = []
        }
    }
    
    var totalNotes: Int {
        notes.count
    }
    
    var pinnedNotesCount: Int {
        notes.filter { $0.isPinned }.count
    }
    
    func notesCount(for category: NoteCategory) -> Int {
        notes.filter { $0.category == category }.count
    }
}
