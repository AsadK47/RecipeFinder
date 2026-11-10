import Foundation

/// What the in-app browser offers on the page it's showing.
enum WebImportOffer: Equatable {
    /// Search results, a page still loading, or nothing loaded — importing here would only fail.
    case hidden
    /// The page reads as a recipe: the prominent "Import this recipe" pill.
    case recipeFound
    /// A normal page the reader didn't recognise: a quiet "Try importing this page" link (some recipe sites hide
    /// their data), whose failure lands on the existing "Paste the recipe text instead" screen.
    case tryAnyway
}

/// Pure rules behind the browser's chrome, kept out of the view so they're tested.
enum WebSearchBrowsing {
    static func offer(for url: URL?, isLoading: Bool, recipeDetected: Bool) -> WebImportOffer {
        guard let url, !isLoading, !isSearchResultsPage(url) else { return .hidden }
        return recipeDetected ? .recipeFound : .tryAnyway
    }

    /// Pages on the search engines themselves (DuckDuckGo, Google, BBC Good Food's search) are lists of links.
    static func isSearchResultsPage(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        if host == "duckduckgo.com" || host.hasSuffix(".duckduckgo.com") { return true }
        if host == "google.com" || host.hasPrefix("www.google.") { return true }
        if host.hasSuffix("bbcgoodfood.com") { return url.path.lowercased().hasPrefix("/search") }
        return false
    }

    /// Same reader the importer uses: structured data, or a page it can pull ingredients and steps from.
    static func looksLikeRecipe(html: String) -> Bool {
        if RecipeParser.hasRecipeData(html: html) { return true }
        let parsed = RecipeParser.parse(html: html)
        return parsed.ingredients.count >= 2 && !parsed.instructions.isEmpty
    }

    /// "www.bbcgoodfood.com" → "bbcgoodfood.com", shown in the address bar instead of the full URL.
    static func siteName(for url: URL?) -> String {
        guard var host = url?.host?.lowercased(), !host.isEmpty else { return "" }
        for prefix in ["www.", "m.", "mobile."] where host.hasPrefix(prefix) {
            host.removeFirst(prefix.count)
        }
        return host
    }

    /// Start-screen ideas for a first search.
    static let suggestions = ["Chicken curry", "Banana bread", "Quick pasta", "Vegetable soup", "Chocolate cake",
                              "Stir fry"]
}

/// The last few searches, newest first, stored as one newline-separated string in `@AppStorage`.
enum RecentWebSearches {
    static let limit = 6

    static func adding(_ query: String, to recent: [String]) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return recent }
        let others = recent.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        return Array(([trimmed] + others).prefix(limit))
    }

    static func decode(_ stored: String) -> [String] {
        stored.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
    }

    static func encode(_ recent: [String]) -> String {
        recent.joined(separator: "\n")
    }
}
