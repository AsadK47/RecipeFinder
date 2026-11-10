import Foundation

/// The search engine the in-app recipe browser opens (Recipes + → Search the web). Pages load straight from the chosen
/// site — no RecipeFinder server in between.
enum WebRecipeSearchEngine: String, CaseIterable, Identifiable, Sendable {
    case duckDuckGo
    case google
    case bbcGoodFood

    static let `default`: WebRecipeSearchEngine = .duckDuckGo

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .duckDuckGo: "DuckDuckGo"
        case .google: "Google"
        case .bbcGoodFood: "BBC Good Food"
        }
    }

    /// Results page for `query`, or nil when the query is blank. General engines get "recipe" appended so results
    /// lean to recipe pages; recipe sites search their own catalogue as-is.
    func searchURL(for query: String) -> URL? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "https"
        let terms: String
        switch self {
        case .duckDuckGo:
            components.host = "duckduckgo.com"
            components.path = "/"
            terms = "\(trimmed) recipe"
        case .google:
            components.host = "www.google.com"
            components.path = "/search"
            terms = "\(trimmed) recipe"
        case .bbcGoodFood:
            components.host = "www.bbcgoodfood.com"
            components.path = "/search"
            terms = trimmed
        }
        components.queryItems = [URLQueryItem(name: "q", value: terms)]
        return components.url
    }
}
