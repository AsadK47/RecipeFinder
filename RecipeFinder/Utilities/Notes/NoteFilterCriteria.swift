import Foundation

/// The full set of notes-list filters as a plain value.
///
/// Extracted from `NotesListView` so the filtering is pure and unit testable, and
/// so the work no longer lives inline in a SwiftUI `body`. The view builds one of
/// these from its `@State` and calls `apply(to:)`. Mirrors `RecipeFilterCriteria`.
struct NoteFilterCriteria: Hashable {
    var searchText: String = ""
    var selectedCategory: NoteCategory?
    var selectedTag: String?
    var showPinnedOnly: Bool = false

    /// Number of *chips* the UI shows as active. Deliberately excludes free-text
    /// `searchText` (which has its own field), matching the existing badge count.
    var activeCount: Int {
        (selectedCategory != nil ? 1 : 0) +
        (selectedTag != nil ? 1 : 0) +
        (showPinnedOnly ? 1 : 0)
    }

    /// Applies every active filter. Order is irrelevant to the result; it mirrors
    /// the original view code to stay behavior-preserving.
    func apply(to notes: [NoteModel]) -> [NoteModel] {
        var results = notes

        if !searchText.isEmpty {
            results = results.filter { $0.matches(searchText: searchText) }
        }

        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }

        if let tag = selectedTag {
            results = results.filter { $0.tags.contains(tag) }
        }

        if showPinnedOnly {
            results = results.filter { $0.isPinned }
        }

        return results
    }
}
