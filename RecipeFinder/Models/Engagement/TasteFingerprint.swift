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

    /// No trait in anything cooked yet (or nothing cooked) → Me hides the card rather than show five empty bars; the
    /// hero and cookbook carry the first-cook invitation.
    var isEmpty: Bool { strongest == nil }

    /// The biggest share. Ties follow `headlinePriority`, so the headline is stable and the most common trait
    /// (spicy — chilli is in most curries) doesn't win every tie.
    var strongest: TasteShare? {
        shares.filter { $0.cooks > 0 }.max { lhs, rhs in
            lhs.cooks == rhs.cooks ? priority(lhs.trait) > priority(rhs.trait) : lhs.cooks < rhs.cooks
        }
    }

    /// "You lean towards comfort food — 6 of 10 meals"; nil when there's no trait to name.
    var headline: String? {
        guard let top = strongest else { return nil }
        let meals = totalCooks == 1 ? "meal" : "meals"
        return "You lean towards \(top.trait.headlinePhrase) — \(top.cooks) of \(totalCooks) \(meals)"
    }

    func share(_ trait: TasteTrait) -> TasteShare? {
        shares.first { $0.trait == trait }
    }

    /// The recipes behind a trait, in the share's order (most cooked first); ones deleted since are skipped.
    func recipes(behind trait: TasteTrait, in library: [RecipeModel]) -> [RecipeModel] {
        let byID = Dictionary(library.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return (share(trait)?.recipeIDs ?? []).compactMap { byID[$0] }
    }

    private static let headlinePriority: [TasteTrait] = [.comforting, .fresh, .baking, .quick, .spicy]

    private func priority(_ trait: TasteTrait) -> Int {
        Self.headlinePriority.firstIndex(of: trait) ?? Self.headlinePriority.count
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
        // "baking powder" / "a baking tray" are in pancakes and fried dishes — only the act of baking counts.
        var methodText = (recipe.prePrepInstructions + recipe.instructions).joined(separator: " ").lowercased()
        for phrase in notBakingPhrases { methodText = methodText.replacingOccurrences(of: phrase, with: " ") }
        let method = Words(methodText)
        let category = recipe.category.lowercased()

        var traits = Set<TasteTrait>()
        // "Sweet Chilli Chicken" isn't hot — drop the not-hot phrases before looking for heat in the name.
        // Split to words first, so "Sweet-Chilli" and "Sweet  Chilli" lose the phrase too.
        var heatNameText = recipe.name.lowercased().split { !$0.isLetter && $0 != "'" }.joined(separator: " ")
        for phrase in notHotNamePhrases { heatNameText = heatNameText.replacingOccurrences(of: phrase, with: " ") }
        if !tags.isDisjoint(with: ["spicy", "hot"]) || Words(heatNameText).hasAny(spicyNameWords)
            || ingredients.contains(where: { line in
                spicyIngredients.contains { line.contains($0) } && !notHotLineWords.contains { line.contains($0) }
            }) {
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
        let steamed = name.hasAny(steamedNameWords)
        if !tags.isDisjoint(with: ["baking", "baked goods"]) || (name.hasAny(bakedGoods) && !steamed)
            || (["dessert", "breakfast"].contains(category) && method.hasAny(["bake", "baked", "bakes"])) {
            traits.insert(.baking)
        }
        // Distinct fresh words, so "lemon juice" twice is still one.
        let freshLines = ingredients.filter { line in !notFreshLineWords.contains { line.contains($0) } }
        let freshIngredients = freshIngredientWords.filter { word in freshLines.contains { $0.contains(word) } }
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
    /// A chilli line that doesn't bring heat: optional, for colour (Kashmiri), mild or sweet, or a garnish.
    private static let notHotLineWords = ["optional", "kashmiri", "mild", "sweet chilli", "sweet chili", "to serve",
                                          "garnish", "paprika"]
    /// A chilli in a dish's name that doesn't bring heat.
    private static let notHotNamePhrases = ["sweet chilli", "sweet chili", "mild chilli", "mild chili"]
    private static let spicyNameWords: Set<String> = [
        "spicy", "chilli", "chili", "fiery", "vindaloo", "jalfrezi", "madras", "harissa", "jerk", "peri",
        "piri", "szechuan", "sichuan", "arrabbiata", "diavola", "buffalo wings", "buffalo chicken",
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
    /// Steamed or savoury "buns" and "cakes" (bao, mantou, radish cake) aren't baking.
    private static let steamedNameWords: Set<String> = ["steamed", "steam", "bao", "mantou", "radish", "fish",
                                                        "crab", "rice", "nian"]
    private static let notBakingPhrases = ["baking powder", "baking soda", "baking paper", "baking tray",
                                           "baking sheet", "baking parchment", "oven glove"]
    /// Dried, ground or bottled herbs and citrus aren't fresh ("coriander powder", "avocado oil", "mint sauce").
    private static let notFreshLineWords = ["powder", "seed", "ground", "oil", "dried", "sauce", "paste"]
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
            words.insert(EnglishPlural.singular(part))
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
