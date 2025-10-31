import Foundation
import Combine

class NotesManager: ObservableObject {
    @Published var notes: [NoteModel] = []
    
    private let notesKey = "saved_notes"
    
    init() {
        loadNotes()
    }
    
    // MARK: - CRUD Operations
    
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
    
    func togglePin(_ note: NoteModel) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isPinned.toggle()
            saveNotes()
            sortNotes()
        }
    }
    
    // MARK: - Filtering and Sorting
    
    func filteredNotes(searchText: String, category: NoteCategory?, showPinnedOnly: Bool) -> [NoteModel] {
        var filtered = notes
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.matches(searchText: searchText) }
        }
        
        // Filter by category
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filter by pinned
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
            // Pinned notes first
            if note1.isPinned != note2.isPinned {
                return note1.isPinned
            }
            // Then by modified date
            return note1.modifiedDate > note2.modifiedDate
        }
    }
    
    // MARK: - Persistence
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: notesKey)
        }
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([NoteModel].self, from: data) {
            notes = decoded
            sortNotes()
        }
    }
    
    // MARK: - Statistics
    
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
