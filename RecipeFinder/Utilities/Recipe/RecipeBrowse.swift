import Foundation

/// What the Recipes home shows. A toggle at the top picks *Discover* (endless chapters) or *My recipes* (the list) and
/// remembers the choice (tester feedback 2026-11-16); typing, filtering or re-sorting always shows results.
/// Pure so the switch is tested, not just eyeballed.
enum RecipeBrowse {
    /// The toggle's two sides; raw values are stored, so don't rename them.
    enum Mode: String, CaseIterable, Identifiable {
        case discover, myRecipes

        var id: String { rawValue }

        var title: String {
            switch self {
            case .discover: "Discover"
            case .myRecipes: "My recipes"
            }
        }
    }

    enum Content: Equatable {
        /// Recently cooked, then endless chapters.
        case discover
        /// The whole library, A–Z.
        case library
        /// What the search, filters or sort found.
        case results
    }

    /// Shared with Today's "Keep browsing →", which switches Recipes to Discover before opening it.
    static let modeKey = "recipes.mode"

    /// A library this small is all on one screen already; chapters would only repeat it.
    static let minimumDiscoverLibrary = 7

    /// Searching, filtering or picking a sort means the cook is looking for something: show results.
    static func isBrowsing(_ criteria: RecipeFilterCriteria) -> Bool {
        criteria.searchText.trimmingCharacters(in: .whitespaces).isEmpty
            && criteria.activeCount == 0
            && criteria.sortOrder == .nameAZ
    }

    static func content(mode: Mode, criteria: RecipeFilterCriteria, libraryCount: Int) -> Content {
        guard isBrowsing(criteria) else { return .results }
        guard mode == .discover, libraryCount >= minimumDiscoverLibrary else { return .library }
        return .discover
    }
}
