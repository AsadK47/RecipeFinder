import Foundation

struct IngredientAutocompleteSuggestion: Identifiable, Hashable {
    let name: String
    let category: String
    let source: String
    let score: Int

    var id: String { name.lowercased() }
}

enum IngredientAutocompleteEngine {

    static func suggestions(for query: String, limit: Int = 6, additionalCandidates: [String] = []) -> [IngredientAutocompleteSuggestion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return [] }

        let normalizedQuery = normalizeForMatching(trimmedQuery)
        let queryTokens = tokenize(normalizedQuery)
        let catalogFoods = Set(FoodsList.getAllFoods().map { $0.lowercased() })

        let candidatePool = uniqueCandidates(FoodsList.getAllFoods() + additionalCandidates)

        let ranked = candidatePool.compactMap { candidate -> IngredientAutocompleteSuggestion? in
            let score = score(candidate: candidate, query: trimmedQuery, normalizedQuery: normalizedQuery, queryTokens: queryTokens)
            guard score > 0 else { return nil }

            return IngredientAutocompleteSuggestion(
                name: candidate,
                category: category(for: candidate),
                source: catalogFoods.contains(candidate.lowercased()) ? "Catalog" : "Custom",
                score: score
            )
        }
        .sorted {
            if $0.score == $1.score {
                if $0.name.count == $1.name.count {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.name.count < $1.name.count
            }
            return $0.score > $1.score
        }

        return Array(ranked.prefix(limit))
    }

    static func rankedNames(for query: String, limit: Int = 6, additionalCandidates: [String] = []) -> [String] {
        suggestions(for: query, limit: limit, additionalCandidates: additionalCandidates).map { $0.name }
    }

    private static func score(candidate: String, query: String, normalizedQuery: String, queryTokens: [String]) -> Int {
        let lowerCandidate = candidate.lowercased()
        let normalizedCandidate = normalizeForMatching(candidate)
        let lowerQuery = query.lowercased()

        if lowerCandidate == lowerQuery || normalizedCandidate == normalizedQuery {
            return 1000
        }

        if lowerCandidate.hasPrefix(lowerQuery) {
            return 950
        }

        if normalizedCandidate.hasPrefix(normalizedQuery) {
            return 920
        }

        if queryTokens.count > 1, queryTokens.allSatisfy({ token in
            normalizedCandidate.contains(token) || lowerCandidate.contains(token)
        }) {
            return 800
        }

        if lowerCandidate.contains(lowerQuery) {
            return 700
        }

        if normalizedCandidate.contains(normalizedQuery) {
            return 680
        }

        if queryTokens.contains(where: { token in
            lowerCandidate.hasPrefix(token) || normalizedCandidate.hasPrefix(token)
        }) {
            return 640
        }

        return 0
    }

    private static func category(for candidate: String) -> String {
        if let foodCategory = FoodsList.getCategoryForFood(candidate) {
            return foodCategory
        }

        let suggested = CategoryClassifier.suggestCategory(for: candidate)
        return suggested.isEmpty ? "Other" : suggested
    }

    private static func normalizeForMatching(_ string: String) -> String {
        IngredientNormalizer.normalize(string)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private static func tokenize(_ string: String) -> [String] {
        string
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { String($0) }
            .filter { !$0.isEmpty }
    }

    private static func uniqueCandidates(_ candidates: [String]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []

        for candidate in candidates {
            let key = candidate.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            ordered.append(candidate)
        }

        return ordered
    }
}