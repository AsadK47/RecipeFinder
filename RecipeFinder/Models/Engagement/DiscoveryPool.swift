import Foundation

/// One chapter of the endless discovery feed on Recipes: a titled set of recipes with a reason line and a layout.
struct DiscoveryChapter: Identifiable, Equatable {
    enum Kind: Hashable {
        /// The row above the library (never dealt by the pager).
        case recentlyCooked
        case becauseYouLoved(String)
        case quick
        case usesWhatYouHave
        case cookAgain
        case newToYou
        case cuisine(String)
        case category(String)
    }

    /// Rotates chapter to chapter so the scroll keeps changing shape.
    enum Layout: CaseIterable {
        /// One big picture with two beside it.
        case feature
        /// A two-column picture wall.
        case wall
        /// A horizontal swipe row.
        case row

        var size: Int {
            switch self {
            case .feature: 3
            case .wall: 4
            case .row: 8
            }
        }
    }

    /// Position in the feed — unique for the life of the feed, so SwiftUI never confuses two chapters.
    let id: Int
    let kind: Kind
    let layout: Layout
    let recipes: [RecipeModel]

    var title: String {
        switch kind {
        case .recentlyCooked: "Recently cooked"
        case .becauseYouLoved(let name): "Because you loved \(name)"
        case .quick: "Under \(TodayFeed.quickLimitMinutes) minutes"
        case .usesWhatYouHave: "Uses what you have"
        case .cookAgain: "Cook it again"
        case .newToYou: "New to you"
        case .cuisine(let cuisine): Self.tripTitle(cuisine)
        case .category(let category): Self.categoryTitle(category)
        }
    }

    var reason: String {
        switch kind {
        case .recentlyCooked: "Pick up where you left off"
        case .becauseYouLoved: "Shares ingredients with a favourite of yours"
        case .quick: "On the table fast"
        case .usesWhatYouHave: "Most of it is already in your kitchen"
        case .cookAgain: "Dishes you've made and enjoyed"
        case .newToYou: "Fresh ideas to try next"
        case .cuisine(let cuisine): "Cook your way through \(cuisine) food"
        case .category(let category): Self.categoryReason(category)
        }
    }

    /// Stable test/UI hook per kind ("discovery.chapter.quick").
    var slug: String {
        switch kind {
        case .recentlyCooked: "recent"
        case .becauseYouLoved: "loved"
        case .quick: "quick"
        case .usesWhatYouHave: "kitchen"
        case .cookAgain: "again"
        case .newToYou: "new"
        case .cuisine(let cuisine): "cuisine.\(Self.slugKey(cuisine))"
        case .category(let category): "category.\(Self.slugKey(category))"
        }
    }

    private static func slugKey(_ text: String) -> String {
        text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).joined(separator: "-")
    }

    private static let places: [String: String] = [
        "american": "America", "british": "Britain", "caribbean": "the Caribbean", "chinese": "China",
        "french": "France", "greek": "Greece", "indian": "India", "italian": "Italy", "japanese": "Japan",
        "korean": "Korea", "lebanese": "Lebanon", "mediterranean": "the Mediterranean", "mexican": "Mexico",
        "middle eastern": "the Middle East", "moroccan": "Morocco", "pakistani": "Pakistan", "spanish": "Spain",
        "thai": "Thailand", "turkish": "Turkey", "vietnamese": "Vietnam"
    ]

    static func tripTitle(_ cuisine: String) -> String {
        places[cuisine.lowercased()].map { "A trip to \($0)" } ?? "A taste of \(cuisine)"
    }

    private static func categoryTitle(_ category: String) -> String {
        switch category.lowercased() {
        case "dessert": "Something sweet"
        case "soup": "Soup's on"
        case "breakfast": "Start the day well"
        case "side": "On the side"
        case "starter": "Something to start"
        case "drink": "Something to sip"
        case "main": "Dinner ideas"
        default: category
        }
    }

    private static func categoryReason(_ category: String) -> String {
        switch category.lowercased() {
        case "dessert": "Bakes and puddings worth the wait"
        case "soup": "A warm bowl of something good"
        case "breakfast": "Mornings worth getting up for"
        case "side": "The bits that make the plate"
        case "starter": "Small plates to begin with"
        case "drink": "Pour yourself something nice"
        case "main": "Mains for tonight and beyond"
        default: "More \(category.lowercased()) to explore"
        }
    }
}

/// Every chapter the library can fill, each with its candidates best first. Built once per library change (pure, so
/// the ranking is testable); `DiscoveryPager` then deals chapters from it without repeats.
struct DiscoveryPool: Equatable {
    struct Source: Equatable {
        let kind: DiscoveryChapter.Kind
        let candidates: [RecipeModel]
        /// Ranked sources keep their order (best first); the rest are dealt in a fresh seeded order each cycle.
        let isRanked: Bool
    }

    let sources: [Source]

    static let lovedAnchorLimit = 3
    static let similarLimit = 24
    static let recentlyCookedLimit = 5

    static func make(
        recipes: [RecipeModel],
        kitchenItemNames: [String],
        now: Date = Date(),
        calendar: Calendar = .current,
        cookAgainDays: Int = 21
    ) -> DiscoveryPool {
        let sorted = recipes.sorted { $0.name < $1.name }
        var loved: [Source] = []
        let words = Dictionary(sorted.map { ($0.id, keyWords($0)) }, uniquingKeysWith: { first, _ in first })
        for anchor in lovedAnchors(sorted) {
            let similar = similarRecipes(to: anchor, in: sorted, words: words)
            if !similar.isEmpty {
                loved.append(Source(kind: .becauseYouLoved(anchor.name), candidates: similar, isRanked: true))
            }
        }

        let quick = sorted
            .compactMap { recipe in TodayFeed.quickMinutes(of: recipe).map { (recipe, $0) } }
            .sorted { $0.1 != $1.1 ? $0.1 < $1.1 : $0.0.name < $1.0.name }
            .map(\.0)
        let kitchen = TodayFeed.kitchenMatches(recipes: sorted, kitchenItemNames: kitchenItemNames).map(\.recipe)
        let fixed = [
            Source(kind: .quick, candidates: quick, isRanked: false),
            Source(kind: .usesWhatYouHave, candidates: kitchen, isRanked: true),
            Source(kind: .cookAgain, candidates: cookAgain(sorted, now: now, calendar: calendar, days: cookAgainDays),
                   isRanked: true),
            Source(kind: .newToYou, candidates: sorted.filter { $0.cookCount == 0 }, isRanked: false)
        ]

        let cuisines = grouped(sorted, by: { $0.cuisine?.trimmingCharacters(in: .whitespaces) })
            .map { Source(kind: .cuisine($0.key), candidates: $0.recipes, isRanked: false) }
        let categories = grouped(sorted, by: { $0.category.trimmingCharacters(in: .whitespaces) })
            .map { Source(kind: .category($0.key), candidates: $0.recipes, isRanked: false) }

        // Interleave the families so the feed opens personal ("Because you loved…", "Under 30 minutes") and no two
        // chapters of one family sit together while others are left.
        let families = [loved, fixed, cuisines, categories].map { $0.filter { !$0.candidates.isEmpty } }
        var interleaved: [Source] = []
        for index in 0..<(families.map(\.count).max() ?? 0) {
            for family in families where index < family.count {
                interleaved.append(family[index])
            }
        }
        return DiscoveryPool(sources: interleaved)
    }

    /// The last few recipes cooked, newest first (the "Recently cooked" row above the library); empty when none.
    static func recentlyCooked(_ recipes: [RecipeModel], limit: Int = recentlyCookedLimit) -> [RecipeModel] {
        Array(recipes
            .filter { $0.lastCookedAt != nil }
            .sorted { ($0.lastCookedAt ?? .distantPast) > ($1.lastCookedAt ?? .distantPast) }
            .prefix(limit))
    }

    /// Favourites, recipes rated 4+ and ones cooked more than once — most loved first.
    static func lovedAnchors(_ recipes: [RecipeModel]) -> [RecipeModel] {
        let score = { (r: RecipeModel) in (r.isFavorite ? 100 : 0) + r.rating * 10 + min(r.cookCount, 9) }
        return Array(recipes
            .filter { $0.isFavorite || $0.rating >= 4 || $0.cookCount >= 2 }
            .sorted { score($0) != score($1) ? score($0) > score($1) : $0.name < $1.name }
            .prefix(lovedAnchorLimit))
    }

    /// Recipes most like `anchor`: shared key ingredients first, then same cuisine, tags and category.
    static func similarRecipes(
        to anchor: RecipeModel, in recipes: [RecipeModel], words: [UUID: Set<String>]? = nil
    ) -> [RecipeModel] {
        let anchorWords = words?[anchor.id] ?? keyWords(anchor)
        let anchorTags = Set(anchor.tags.map { $0.lowercased() })
        let anchorCuisine = anchor.cuisine?.lowercased()
        let scored = recipes.compactMap { recipe -> (RecipeModel, Int)? in
            guard recipe.id != anchor.id else { return nil }
            let shared = anchorWords.intersection(words?[recipe.id] ?? keyWords(recipe)).count
            let sameCuisine = anchorCuisine != nil && recipe.cuisine?.lowercased() == anchorCuisine
            guard shared >= 2 || sameCuisine else { return nil }
            let tags = anchorTags.intersection(recipe.tags.map { $0.lowercased() }).count
            let score = shared * 2 + (sameCuisine ? 3 : 0) + tags * 2 + (recipe.category == anchor.category ? 1 : 0)
            return (recipe, score)
        }
        return Array(scored
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.name < $1.0.name }
            .prefix(similarLimit)
            .map(\.0))
    }

    /// Words worth comparing in a recipe's ingredient names — no regex, so 300+ recipes stay cheap.
    static func keyWords(_ recipe: RecipeModel) -> Set<String> {
        var result = Set<String>()
        for ingredient in recipe.ingredients {
            for word in ingredient.name.lowercased().split(whereSeparator: { !$0.isLetter }) where word.count >= 4 {
                let term = String(word)
                if !staples.contains(term) { result.insert(term) }
            }
        }
        return result
    }

    /// Ingredients and descriptors nearly every recipe shares — matching on them would make everything "similar".
    private static let staples: Set<String> = [
        "salt", "pepper", "black", "ground", "water", "sugar", "butter", "olive", "vegetable", "fresh", "large",
        "small", "medium", "chopped", "finely", "sliced", "diced", "minced", "plain", "flour", "taste", "optional",
        "white", "extra", "virgin", "unsalted", "pinch", "handful", "cups", "tbsp", "tsp", "into", "plus",
        "peeled", "powder", "dried", "leaves", "green", "garlic", "onion", "onions", "cloves", "sauce", "pieces",
        "roughly", "thinly", "grated", "about", "cold", "warm", "room", "temperature"
    ]

    /// Cooked before: recent cooks newest first, then older ones most worth resurfacing (`RecipeRediscovery`).
    private static func cookAgain(_ recipes: [RecipeModel], now: Date, calendar: Calendar, days: Int) -> [RecipeModel] {
        let cutoff = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        let recent = recipes
            .filter { ($0.lastCookedAt ?? .distantPast) >= cutoff && $0.cookCount > 0 }
            .sorted { ($0.lastCookedAt ?? .distantPast) > ($1.lastCookedAt ?? .distantPast) }
        let stale = RecipeRediscovery.ranked(from: recipes, now: now, calendar: calendar, thresholdDays: days)
        return recent + stale
    }

    /// Groups with at least two recipes, biggest first, so a lone recipe never makes a chapter of its own.
    private static func grouped(
        _ recipes: [RecipeModel], by key: (RecipeModel) -> String?
    ) -> [(key: String, recipes: [RecipeModel])] {
        var groups: [String: [RecipeModel]] = [:]
        var display: [String: String] = [:]
        for recipe in recipes {
            guard let raw = key(recipe), !raw.isEmpty else { continue }
            let normalized = raw.lowercased()
            groups[normalized, default: []].append(recipe)
            if display[normalized] == nil { display[normalized] = raw }
        }
        return groups
            .filter { $0.value.count >= 2 }
            .map { (key: display[$0.key] ?? $0.key, recipes: $0.value) }
            .sorted { $0.recipes.count != $1.recipes.count ? $0.recipes.count > $1.recipes.count : $0.key < $1.key }
    }
}
