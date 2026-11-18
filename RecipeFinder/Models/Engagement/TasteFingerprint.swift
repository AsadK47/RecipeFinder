import Foundation

/// One flavour of cooking on Me's taste fingerprint. Fixed order so the shape keeps its axes from visit to visit.
enum TasteTrait: String, CaseIterable, Identifiable, Hashable, Sendable {
    case spicy, comforting, quick, baking, fresh

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spicy: "Spicy"
        case .comforting: "Comforting"
        case .quick: "Quick"
        case .baking: "Baking"
        case .fresh: "Fresh"
        }
    }

    var icon: String {
        switch self {
        case .spicy: "flame.fill"
        case .comforting: "cup.and.saucer.fill"
        case .quick: "bolt.fill"
        case .baking: "birthday.cake.fill"
        case .fresh: "leaf.fill"
        }
    }

    /// The headline's phrase: "You lean towards spicy food".
    var headlinePhrase: String {
        switch self {
        case .spicy: "spicy food"
        case .comforting: "comfort food"
        case .quick: "quick cooking"
        case .baking: "baking"
        case .fresh: "fresh, bright food"
        }
    }
}

/// How much of the cook's cooking one trait covers: cooks of recipes with that trait over all cooks.
struct TasteShare: Identifiable, Equatable, Sendable {
    let trait: TasteTrait
    /// Cooks (repeats count) of recipes with this trait.
    let cooks: Int
    /// `cooks` over every cook, 0...1. A recipe can have several traits, so shares don't add up to 1.
    let share: Double
    /// The cooked recipes behind this trait, most cooked first — what tapping the trait opens.
    let recipeIDs: [UUID]

    var id: TasteTrait { trait }
    var percent: Int { Int((share * 100).rounded()) }
}

/// Me's taste fingerprint: what the cook actually makes, read from cooked recipes (each weighted by how often it was
/// made). Rules are visible and simple — tags first, then the name, method, ingredients and time — so a trait never
/// appears for a reason the cook couldn't guess. Pure so the scoring is pinned by tests.
struct TasteFingerprint: Equatable, Sendable {
    /// One per trait, in `TasteTrait.allCases` order.
    let shares: [TasteShare]
    let totalCooks: Int

    static let empty = TasteFingerprint(
        shares: TasteTrait.allCases.map { TasteShare(trait: $0, cooks: 0, share: 0, recipeIDs: []) }, totalCooks: 0
    )

    /// Nothing cooked yet → Me hides the card (the hero and cookbook carry the first-cook invitation).
    var isEmpty: Bool { totalCooks == 0 }

    /// The biggest share; ties go to the earlier trait so the headline doesn't flicker.
    var strongest: TasteShare? {
        shares.filter { $0.cooks > 0 }.max { lhs, rhs in
            lhs.cooks == rhs.cooks ? order(lhs.trait) > order(rhs.trait) : lhs.cooks < rhs.cooks
        }
    }

    /// "You lean towards spicy food — 6 of 10 meals". A cook with no trait yet gets an invitation instead.
    var headline: String {
        guard let top = strongest else {
            return totalCooks == 0 ? "Cook a few meals and your taste takes shape"
                : "Your taste takes shape as you cook more"
        }
        let meals = totalCooks == 1 ? "meal" : "meals"
        return "You lean towards \(top.trait.headlinePhrase) — \(top.cooks) of \(totalCooks) \(meals)"
    }

    func share(_ trait: TasteTrait) -> TasteShare? {
        shares.first { $0.trait == trait }
    }

    private func order(_ trait: TasteTrait) -> Int {
        TasteTrait.allCases.firstIndex(of: trait) ?? 0
    }

    static func from(recipes: [RecipeModel]) -> TasteFingerprint {
        let cooked = recipes.filter { $0.cookCount > 0 }
        let total = cooked.reduce(0) { $0 + $1.cookCount }
        guard total > 0 else { return .empty }

        var cooks: [TasteTrait: Int] = [:]
        var ids: [TasteTrait: [RecipeModel]] = [:]
        for recipe in cooked {
            for trait in traits(of: recipe) {
                cooks[trait, default: 0] += recipe.cookCount
                ids[trait, default: []].append(recipe)
            }
        }
        let shares = TasteTrait.allCases.map { trait in
            let count = cooks[trait] ?? 0
            let recipes = (ids[trait] ?? []).sorted {
                $0.cookCount == $1.cookCount
                    ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    : $0.cookCount > $1.cookCount
            }
            return TasteShare(trait: trait, cooks: count, share: Double(count) / Double(total),
                              recipeIDs: recipes.map(\.id))
        }
        return TasteFingerprint(shares: shares, totalCooks: total)
    }

    // MARK: - Rules

    static func traits(of recipe: RecipeModel) -> Set<TasteTrait> {
        let tags = Set(recipe.tags.map { $0.lowercased().trimmingCharacters(in: .whitespaces) })
        let name = Words(recipe.name)
        let ingredients = recipe.ingredients.map { $0.name.lowercased() }
        let method = Words((recipe.prePrepInstructions + recipe.instructions).joined(separator: " "))
        let category = recipe.category.lowercased()

        var traits = Set<TasteTrait>()
        if !tags.isDisjoint(with: ["spicy", "hot"]) || name.hasAny(spicyNameWords)
            || ingredients.contains(where: { line in spicyIngredients.contains { line.contains($0) } }) {
            traits.insert(.spicy)
        }
        if !tags.isDisjoint(with: ["comfort food", "comfort", "sunday roast"]) || category == "soup"
            || name.hasAny(comfortingNameWords) || name.hasAnyPhrase(comfortingNamePhrases) {
            traits.insert(.comforting)
        }
        if tags.contains("quick") || TodayFeed.quickMinutes(of: recipe) != nil {
            traits.insert(.quick)
        }
        // Baked goods by name, or a sweet/breakfast dish whose method bakes — a baked pasta is dinner, not baking.
        if !tags.isDisjoint(with: ["baking", "baked goods"]) || name.hasAny(bakedGoods)
            || (["dessert", "breakfast"].contains(category) && method.hasAny(["bake", "baked", "baking", "oven"])) {
            traits.insert(.baking)
        }
        let freshIngredients = ingredients.filter { line in freshIngredientWords.contains { line.contains($0) } }
        if !tags.isDisjoint(with: ["fresh", "healthy", "salad"]) || name.hasAny(freshNameWords)
            || freshIngredients.count >= 3 {
            traits.insert(.fresh)
        }
        return traits
    }

    /// Substrings of an ingredient line that bring heat ("green chillies", "kashmiri chilli powder").
    private static let spicyIngredients = [
        "chilli", "chili", "chile", "cayenne", "jalapeño", "jalapeno", "sriracha", "harissa", "gochujang",
        "gochugaru", "chipotle", "scotch bonnet", "habanero", "hot sauce", "red pepper flakes", "peri peri",
        "piri piri", "sambal", "wasabi", "szechuan pepper", "sichuan pepper", "bird's eye", "birds eye",
    ]
    private static let spicyNameWords: Set<String> = [
        "spicy", "chilli", "chili", "fiery", "vindaloo", "jalfrezi", "madras", "harissa", "jerk", "peri",
        "piri", "szechuan", "sichuan", "arrabbiata", "diavola", "buffalo",
    ]
    private static let comfortingNameWords: Set<String> = [
        "stew", "curry", "casserole", "lasagne", "lasagna", "pie", "risotto", "chowder", "dal", "dhal", "daal",
        "hotpot", "roast", "pudding", "crumble", "gratin", "ragu", "bolognese", "biryani", "korma", "tagine",
        "goulash", "dumpling", "soup", "congee", "macaroni", "mash", "shanks",
    ]
    private static let comfortingNamePhrases = ["mac and cheese", "mac & cheese", "pasta bake", "butter chicken",
                                                "chilli con carne", "chili con carne", "shepherd's pie"]
    private static let bakedGoods: Set<String> = [
        "cake", "cheesecake", "bread", "loaf", "muffin", "cookie", "biscuit", "brownie", "blondie", "scone", "tart",
        "pastry", "bun", "croissant", "cupcake", "flapjack", "focaccia", "banana bread", "shortbread", "babka",
        "rugelach", "traybake", "galette", "strudel", "baklava", "macaron",
    ]
    private static let freshNameWords: Set<String> = [
        "salad", "slaw", "coleslaw", "salsa", "ceviche", "poke", "gazpacho", "smoothie", "tabbouleh", "carpaccio",
        "crudo", "raita",
    ]
    private static let freshIngredientWords = [
        "lemon", "lime", "cucumber", "mint", "coriander", "cilantro", "basil", "parsley", "dill", "avocado",
        "rocket", "arugula", "spring onion", "scallion",
    ]
}

/// Lower-cased words of a text, matched whole (plurals folded: "stews", "curries"), so "dal" doesn't fire on
/// "medallions". A candidate with a space ("banana bread") is matched as a phrase.
private struct Words {
    let text: String
    let words: Set<String>

    init(_ text: String) {
        self.text = text.lowercased()
        let parts = self.text.split { !$0.isLetter && $0 != "'" }.map(String.init)
        var words = Set<String>()
        for part in parts {
            words.insert(part)
            if part.hasSuffix("ies") { words.insert(String(part.dropLast(3)) + "y") }
            if part.hasSuffix("es") { words.insert(String(part.dropLast(2))) }
            if part.hasSuffix("s") { words.insert(String(part.dropLast())) }
        }
        self.words = words
    }

    func hasAny(_ candidates: Set<String>) -> Bool {
        candidates.contains { candidate in
            candidate.contains(" ") ? text.contains(candidate) : words.contains(candidate)
        }
    }

    func hasAnyPhrase(_ phrases: [String]) -> Bool {
        phrases.contains { text.contains($0) }
    }
}
