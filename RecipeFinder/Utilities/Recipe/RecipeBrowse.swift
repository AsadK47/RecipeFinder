import Foundation

/// The Recipes home while browsing (nothing typed, filtered or re-sorted): a short library preview, then discovery.
/// Pure so the browse/search switch is tested, not just eyeballed.
enum RecipeBrowse {
    /// 300+ library cards would bury the chapters, so browsing shows a few and "See all".
    static let previewLimit = 6

    /// Searching, filtering or picking a sort shows the full results list instead.
    static func isBrowsing(_ criteria: RecipeFilterCriteria) -> Bool {
        criteria.searchText.trimmingCharacters(in: .whitespaces).isEmpty
            && criteria.activeCount == 0
            && criteria.sortOrder == .nameAZ
    }

    /// The cook's own recipes and favourites first (keeping list order), then the rest — so the preview is theirs,
    /// not the first few bundled recipes A–Z.
    static func preview(_ recipes: [RecipeModel], limit: Int = previewLimit) -> [RecipeModel] {
        let mine = recipes.filter { !$0.isSampleRecipe || $0.isFavorite }
        guard mine.count < limit else { return Array(mine.prefix(limit)) }
        let mineIDs = Set(mine.map(\.id))
        return Array((mine + recipes.filter { !mineIDs.contains($0.id) }).prefix(limit))
    }

    /// Chapters only once the library outgrows the preview; a small library is all on screen already.
    static func showsDiscovery(libraryCount: Int) -> Bool {
        libraryCount > previewLimit
    }
}
