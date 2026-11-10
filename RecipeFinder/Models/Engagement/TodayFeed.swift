import Foundation

/// What the Today tab shows: a "Tonight" hero plus shelves, picked from the user's recipes, today's plan and their kitchen.
/// Pure so the selection rules are testable; the view computes it once per data change.
struct TodayFeed: Equatable {
    /// Why the hero recipe was chosen — drives its caption.
    enum HeroReason: Equatable {
        case planned(MealTime)
        case kitchenMatch(have: Int, total: Int)

        var caption: String {
            switch self {
            case .planned(.dinner): "Planned for tonight"
            case .planned(let time): "Planned for \(time.rawValue.lowercased())"
            case .kitchenMatch(let have, let total): "You have \(have)/\(total) ingredients"
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

    static let shelfLimit = 10

    static func make(
        recipes: [RecipeModel],
        todaysPlans: [MealPlanModel],
        kitchenItemNames: [String],
        now: Date = Date(),
        calendar: Calendar = .current,
        thresholdDays: Int = 21
    ) -> TodayFeed {
        let matches = kitchenMatches(recipes: recipes, kitchenItemNames: kitchenItemNames)
        let hero = plannedHero(recipes: recipes, plans: todaysPlans)
            ?? matches.first.map { Hero(recipe: $0.recipe, reason: .kitchenMatch(have: $0.have, total: $0.total)) }
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

        let isNewUser = recipes.allSatisfy { $0.isSampleRecipe && $0.cookCount == 0 }
        let starters = isNewUser
            ? recipes.filter(\.isSampleRecipe).sorted { $0.name < $1.name }
            : []

        return TodayFeed(
            hero: hero,
            cookAgain: Array(cookAgain.prefix(shelfLimit)),
            fitsYourKitchen: Array(matches.filter { $0.recipe.id != heroID }.prefix(shelfLimit)),
            rediscover: Array(rediscover.prefix(shelfLimit)),
            isNewUser: isNewUser,
            starters: Array(starters.prefix(shelfLimit))
        )
    }

    /// Tonight's dinner if planned, else the next unfinished plan of the day; skips plans whose recipe was deleted.
    private static func plannedHero(recipes: [RecipeModel], plans: [MealPlanModel]) -> Hero? {
        let open = plans.filter { !$0.isCompleted }
        let ordered = open.filter { $0.mealTime == .dinner }
            + open.filter { $0.mealTime != .dinner }.sorted { $0.mealTime.sortOrder < $1.mealTime.sortOrder }
        for plan in ordered {
            if let recipe = recipes.first(where: { $0.id == plan.recipeId }) {
                return Hero(recipe: recipe, reason: .planned(plan.mealTime))
            }
        }
        return nil
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
