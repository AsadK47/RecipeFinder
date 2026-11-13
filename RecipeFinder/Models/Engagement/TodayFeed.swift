import Foundation

/// What the Today tab shows: a "Tonight" hero plus shelves, picked from the user's recipes, today's plan and their kitchen.
/// Pure so the selection rules are testable; the view computes it once per data change.
struct TodayFeed: Equatable {
    /// Why the hero recipe was chosen — drives its caption.
    enum HeroReason: Equatable {
        case planned(MealTime)
        case kitchenMatch(have: Int, total: Int)
        /// A recipe that's on the table in `minutes` (≤ `TodayFeed.quickLimitMinutes`).
        case quick(minutes: Int)

        var caption: String {
            switch self {
            case .planned(.dinner): "Planned for tonight"
            case .planned(let time): "Planned for \(time.rawValue.lowercased())"
            case .kitchenMatch(let have, let total): "You have \(have)/\(total) ingredients"
            case .quick(let minutes): "Ready in \(DurationFormatter.label(minutes: minutes))"
            }
        }
    }

    struct Hero: Equatable {
        let recipe: RecipeModel
        let reason: HeroReason
    }

    struct KitchenMatch: Equatable {
        let recipe: RecipeModel
        let have: Int
        let total: Int
    }

    let hero: Hero?
    /// Other picks for tonight that Shuffle steps through after the hero (other plans, kitchen matches, quick recipes).
    let alternatives: [Hero]
    /// How many recipes are ready in `quickLimitMinutes` or less (guards the same rule the quick picks use).
    let quickCount: Int
    /// Cooked recently (within `thresholdDays`), newest first.
    let cookAgain: [RecipeModel]
    /// Recipes the kitchen covers at least half of, best coverage first.
    let fitsYourKitchen: [KitchenMatch]
    /// Cooked before but gone cold, most loved first.
    let rediscover: [RecipeModel]
    /// Nothing of the user's own yet (only samples, never cooked) — Today leads with importing a first recipe.
    let isNewUser: Bool
    /// Sample recipes to try, shown to new users.
    let starters: [RecipeModel]
    /// Tomorrow's planned meals that need starting tonight (marinate, soak, defrost…).
    let prepAhead: [PrepAheadNudge]
    /// Kitchen items going off in the next few days, each with a recipe that uses them.
    let useSoon: [UseSoonPair]

    static let shelfLimit = 10
    static let alternativesLimit = 3
    static let quickLimitMinutes = 30

    /// The hero first, then its alternatives — what Shuffle cycles through.
    var tonightOptions: [Hero] { (hero.map { [$0] } ?? []) + alternatives }

    /// The pick to show for `recipeID` (Shuffle's current choice), else the hero — so a refresh that reorders or
    /// drops picks never swaps the card to a different recipe by position.
    func tonightPick(showing recipeID: UUID?) -> Hero? {
        tonightOptions.first { $0.recipe.id == recipeID } ?? hero
    }

    /// The pick after `recipeID`, wrapping round to the hero.
    func nextTonightPick(after recipeID: UUID?) -> Hero? {
        let options = tonightOptions
        guard let index = options.firstIndex(where: { $0.recipe.id == recipeID }) else {
            return options.dropFirst().first ?? options.first
        }
        return options[(index + 1) % options.count]
    }

    static func make(
        recipes: [RecipeModel],
        todaysPlans: [MealPlanModel],
        kitchenItemNames: [String],
        tomorrowsPlans: [MealPlanModel] = [],
        inventoryItems: [KitchenInventoryModel] = [],
        now: Date = Date(),
        calendar: Calendar = .current,
        thresholdDays: Int = 21
    ) -> TodayFeed {
        let matches = kitchenMatches(recipes: recipes, kitchenItemNames: kitchenItemNames)
        let isNewUser = recipes.allSatisfy { $0.isSampleRecipe && $0.cookCount == 0 }
        let options = tonightOptions(
            recipes: recipes, plans: todaysPlans, matches: matches, quickCanLead: !isNewUser
        )
        let hero = options.first
        let heroID = hero?.recipe.id

        let cutoff = calendar.date(byAdding: .day, value: -thresholdDays, to: now) ?? now
        let cookAgain = recipes
            .filter { recipe in
                guard recipe.id != heroID, let last = recipe.lastCookedAt else { return false }
                return last >= cutoff
            }
            .sorted { ($0.lastCookedAt ?? .distantPast) > ($1.lastCookedAt ?? .distantPast) }

        let rediscover = RecipeRediscovery.ranked(from: recipes, now: now, calendar: calendar, thresholdDays: thresholdDays)
            .filter { $0.id != heroID }

        let starters = isNewUser
            ? recipes.filter(\.isSampleRecipe).sorted { $0.name < $1.name }
            : []

        return TodayFeed(
            hero: hero,
            alternatives: Array(options.dropFirst()),
            quickCount: recipes.filter { quickMinutes(of: $0) != nil }.count,
            cookAgain: Array(cookAgain.prefix(shelfLimit)),
            fitsYourKitchen: Array(matches.filter { $0.recipe.id != heroID }.prefix(shelfLimit)),
            rediscover: Array(rediscover.prefix(shelfLimit)),
            isNewUser: isNewUser,
            starters: Array(starters.prefix(shelfLimit)),
            prepAhead: PrepAhead.nudges(recipes: recipes, tomorrowsPlans: tomorrowsPlans),
            useSoon: UseSoon.pairs(
                items: inventoryItems, recipes: recipes, kitchenItemNames: kitchenItemNames, now: now, calendar: calendar
            )
        )
    }

    /// Tonight's picks, best first: today's open plans (dinner, then the rest in meal order), then kitchen matches,
    /// then quick recipes (favourites and your own first). One entry per recipe, capped at hero + `alternativesLimit`.
    /// Suggestions never repeat the last recipe cooked; a plan always shows (the cook chose it). A new user's Today
    /// leads with importing + Starters, so a quick pick can only follow a plan or kitchen match there, not lead.
    private static func tonightOptions(
        recipes: [RecipeModel], plans: [MealPlanModel], matches: [KitchenMatch], quickCanLead: Bool
    ) -> [Hero] {
        let byID = Dictionary(recipes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let open = plans.filter { !$0.isCompleted }
        let orderedPlans = open.filter { $0.mealTime == .dinner }
            + open.filter { $0.mealTime != .dinner }.sorted { $0.mealTime.sortOrder < $1.mealTime.sortOrder }
        let planned = orderedPlans.compactMap { plan in
            byID[plan.recipeId].map { Hero(recipe: $0, reason: .planned(plan.mealTime)) }
        }

        let lastCookedID = recipes
            .filter { $0.lastCookedAt != nil }
            .max { ($0.lastCookedAt ?? .distantPast) < ($1.lastCookedAt ?? .distantPast) }?.id
        let kitchen = matches.map { Hero(recipe: $0.recipe, reason: .kitchenMatch(have: $0.have, total: $0.total)) }
        let quick = quickPicks(recipes)
        let suggested = (kitchen + quick).filter { $0.recipe.id != lastCookedID }

        var seen = Set<UUID>()
        let unique = (planned + suggested).filter { seen.insert($0.recipe.id).inserted }
        if !quickCanLead, case .quick? = unique.first?.reason { return [] }
        return Array(unique.prefix(1 + alternativesLimit))
    }

    /// Recipes ready in `quickLimitMinutes` or less: favourites, then your own over samples, then most cooked, then name.
    private static func quickPicks(_ recipes: [RecipeModel]) -> [Hero] {
        recipes
            .compactMap { recipe in quickMinutes(of: recipe).map { (recipe, $0) } }
            .sorted { a, b in
                if a.0.isFavorite != b.0.isFavorite { return a.0.isFavorite }
                if a.0.isSampleRecipe != b.0.isSampleRecipe { return !a.0.isSampleRecipe }
                if a.0.cookCount != b.0.cookCount { return a.0.cookCount > b.0.cookCount }
                return a.0.name < b.0.name
            }
            .map { Hero(recipe: $0.0, reason: .quick(minutes: $0.1)) }
    }

    /// Prep + cook minutes when known and no more than `quickLimitMinutes`, else nil.
    static func quickMinutes(of recipe: RecipeModel) -> Int? {
        let minutes = recipe.totalMinutes
        return (1...quickLimitMinutes).contains(minutes) ? minutes : nil
    }

    /// Recipes whose ingredients the kitchen covers at least half of; best coverage, then most matched, then name.
    static func kitchenMatches(recipes: [RecipeModel], kitchenItemNames: [String]) -> [KitchenMatch] {
        let pantry = Set(kitchenItemNames.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
        guard !pantry.isEmpty else { return [] }

        return recipes
            .compactMap { recipe -> KitchenMatch? in
                let total = recipe.ingredients.count
                guard total > 0 else { return nil }
                let have = total - recipe.missingIngredients(from: pantry).count
                guard have > 0, have * 2 >= total else { return nil }
                return KitchenMatch(recipe: recipe, have: have, total: total)
            }
            .sorted { a, b in
                let ra = Double(a.have) / Double(a.total), rb = Double(b.have) / Double(b.total)
                if ra != rb { return ra > rb }
                if a.have != b.have { return a.have > b.have }
                return a.recipe.name < b.recipe.name
            }
    }
}
