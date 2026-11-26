import Foundation

/// What the Today tab shows: a hero for the next meal by the clock (late evening → tomorrow's breakfast) plus what to
/// do now, picked from the user's recipes, that meal day's plan and their kitchen.
/// Pure so the selection rules are testable; the view computes it once per data change.
struct TodayFeed: Equatable {
    /// Why the hero recipe was chosen — drives its caption.
    enum HeroReason: Equatable {
        case planned(MealTime)
        /// Planned for tomorrow — the next meal once tonight is over (see `NextMeal`).
        case plannedTomorrow(MealTime)
        case kitchenMatch(have: Int, total: Int)
        /// A recipe that's on the table in `minutes` (≤ `TodayFeed.quickLimitMinutes`).
        case quick(minutes: Int)
        /// A longer recipe that fits the meal — Shuffle's tail after the quick ones; never leads.
        case longer(minutes: Int)

        var caption: String {
            switch self {
            case .planned(.dinner): "Planned for tonight"
            case .planned(let time): "Planned for \(time.rawValue.lowercased())"
            case .plannedTomorrow(.dinner): "Planned for tomorrow night"
            case .plannedTomorrow(let time): "Planned for tomorrow's \(time.rawValue.lowercased())"
            case .kitchenMatch(let have, let total): "You have \(have)/\(total) ingredients"
            case .quick(let minutes): "Ready in \(DurationFormatter.label(minutes: minutes))"
            case .longer(let minutes): "Takes \(DurationFormatter.label(minutes: minutes))"
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

    /// The meal the hero is for.
    let nextMeal: NextMeal
    let hero: Hero?
    /// Other picks for the next meal that Shuffle steps through after the hero (other plans, kitchen matches, quick recipes).
    let alternatives: [Hero]
    /// How many recipes are ready in `quickLimitMinutes` or less (guards the same rule the quick picks use).
    let quickCount: Int
    /// Nothing of the user's own yet (only samples, never cooked) — Today leads with importing a first recipe.
    let isNewUser: Bool
    /// Sample recipes to try, shown to new users.
    let starters: [RecipeModel]
    /// The one thing to do now: tomorrow's prep or something going off soon (see `TodayNudge.pick`).
    let nudge: TodayNudge?

    static let shelfLimit = 10
    static let quickLimitMinutes = 30

    /// What the card says about `hero`: a plan names its meal already; a suggestion says which meal it's for
    /// ("For breakfast · Ready in 10 minutes"), so a morning pick never reads as tonight's dinner.
    /// The meal `hero` is for: a plan's own meal (a dinner plan leads at 8am when it needs morning prep), else the next meal.
    func title(for hero: Hero) -> String {
        switch hero.reason {
        case .planned(let meal): NextMeal.title(meal, isTomorrow: false)
        case .plannedTomorrow(let meal): NextMeal.title(meal, isTomorrow: true)
        case .kitchenMatch, .quick, .longer: nextMeal.title
        }
    }

    func caption(for hero: Hero) -> String {
        switch hero.reason {
        case .planned, .plannedTomorrow: hero.reason.caption
        case .kitchenMatch, .quick, .longer: "\(nextMeal.forLabel) · \(hero.reason.caption)"
        }
    }

    /// Longer recipes that fit the meal, after the alternatives (Shuffle's tail; never the hero).
    var more: [Hero] = []

    /// The hero first, then its alternatives, then the longer tail — what Shuffle cycles through.
    var tonightOptions: [Hero] { (hero.map { [$0] } ?? []) + alternatives + more }

    /// Tonight's leading picks (hero + alternatives, not the longer tail) — what "Plan tomorrow" steers clear of.
    var leadIDs: Set<UUID> { Set(((hero.map { [$0] } ?? []) + alternatives).map(\.recipe.id)) }

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
        eatAt: Int = TonightTiming.defaultEatAt,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> TodayFeed {
        let matches = kitchenMatches(recipes: recipes, kitchenItemNames: kitchenItemNames)
        let isNewUser = recipes.allSatisfy { $0.isSampleRecipe && $0.cookCount == 0 }
        let nextMeal = NextMeal.at(now, todaysPlans: todaysPlans, recipes: recipes, eatAt: eatAt, calendar: calendar)
        let mealDay = nextMeal.isTomorrow ? (calendar.date(byAdding: .day, value: 1, to: now) ?? now) : now
        let options = tonightOptions(
            recipes: recipes, plans: nextMeal.isTomorrow ? tomorrowsPlans : todaysPlans, matches: matches,
            quickCanLead: !isNewUser, nextMeal: nextMeal,
            isMorning: (5 * 60..<12 * 60).contains(TonightTiming.minuteOfDay(now, calendar: calendar)),
            dayKey: dayKey(mealDay, calendar: calendar), calendar: calendar
        )

        let starters = isNewUser
            ? recipes.filter(\.isSampleRecipe).sorted { $0.name < $1.name }
            : []

        return TodayFeed(
            nextMeal: nextMeal,
            hero: options.lead.first,
            alternatives: Array(options.lead.dropFirst()),
            quickCount: recipes.filter { quickMinutes(of: $0) != nil }.count,
            isNewUser: isNewUser,
            starters: Array(starters.prefix(shelfLimit)),
            nudge: TodayNudge.pick(
                prepAhead: PrepAhead.nudges(recipes: recipes, tomorrowsPlans: tomorrowsPlans),
                useSoon: UseSoon.pairs(
                    items: inventoryItems, recipes: recipes, kitchenItemNames: kitchenItemNames, now: now, calendar: calendar
                ),
                dayIsOver: nextMeal.isTomorrow
            ),
            more: options.more
        )
    }

    /// The next meal's picks, best first: that meal's plan; at breakfast/lunch one idea for it before the day's later
    /// plans (see `ideasLead`), else the later and missed plans first; then kitchen matches and quick recipes (your own
    /// first). One entry per recipe, uncapped: Shuffle steps through every
    /// suitable pick (a cap of 4 made it loop the same few — owner 2026-11-17).
    /// Suggestions never repeat the last recipe cooked; a plan always shows (the cook chose it). A new user's Today
    /// leads with importing + Starters, so a quick pick can only follow a plan or kitchen match there, not lead.
    private static func tonightOptions(
        recipes: [RecipeModel], plans: [MealPlanModel], matches: [KitchenMatch], quickCanLead: Bool,
        nextMeal: NextMeal, isMorning: Bool, dayKey: String, calendar: Calendar
    ) -> (lead: [Hero], more: [Hero]) {
        let slot = nextMeal.slot
        let byID = Dictionary(recipes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        // Cooked without Made it (its recipe's last cook is that day) counts as done too, matching Plan.
        let open = plans.filter { !$0.wasCooked(in: recipes, calendar: calendar) }
        let next = nextMeal.mealTime.sortOrder
        let inOrder = { (picked: [MealPlanModel]) -> [Hero] in
            picked.sorted { $0.mealTime.sortOrder < $1.mealTime.sortOrder }.compactMap { plan in
                byID[plan.recipeId].map {
                    Hero(recipe: $0, reason: nextMeal.isTomorrow ? .plannedTomorrow(plan.mealTime) : .planned(plan.mealTime))
                }
            }
        }
        let current = inOrder(open.filter { $0.mealTime.sortOrder == next })
        let later = inOrder(open.filter { $0.mealTime.sortOrder > next })
        let missed = inOrder(open.filter { $0.mealTime.sortOrder < next })

        let lastCookedID = recipes
            .filter { $0.lastCookedAt != nil }
            .max { ($0.lastCookedAt ?? .distantPast) < ($1.lastCookedAt ?? .distantPast) }?.id
        let kitchen = matches.map { Hero(recipe: $0.recipe, reason: .kitchenMatch(have: $0.have, total: $0.total)) }
        let quick = quickPicks(recipes, slot: slot, dayKey: dayKey)
        let suggested = slot.suitable(kitchen + quick).filter { $0.recipe.id != lastCookedID }

        // Breakfast or lunch today: that meal's own plan, then one idea for it, then the day's later plans, then the
        // other ideas (owner 2026-11-26: 8am offered tonight's dinner with "7 pm" and a prep line). Plans keep leading
        // tonight, tomorrow, for a new user, when no idea is actually for this meal (a main labelled "breakfast"), and
        // in the morning when tonight's dinner needs a head start ("Defrost this morning for tonight" shows on its card).
        let plannedIDs = Set((current + later + missed).map(\.recipe.id))
        let ideas = suggested.filter { !plannedIDs.contains($0.recipe.id) }
        let dinnerNeedsMorningPrep = isMorning && later.contains { hero in
            hero.reason == .planned(.dinner) && PrepAhead.cue(for: hero.recipe) != nil
        }
        let ideasLead = !nextMeal.isTonight && !nextMeal.isTomorrow && quickCanLead && !dinnerNeedsMorningPrep
            && ideas.contains { slot.categories.contains($0.recipe.category.lowercased()) }
        let ordered = ideasLead
            ? current + Array(ideas.prefix(1)) + later + missed + Array(ideas.dropFirst())
            : current + later + missed + suggested
        var seen = Set<UUID>()
        let unique = ordered.filter { seen.insert($0.recipe.id).inserted }
        if !quickCanLead, case .quick? = unique.first?.reason { return ([], []) }
        guard !unique.isEmpty else { return ([], []) }
        // Shuffle keeps going past the quick ones with longer recipes of the same kind (owner 2026-11-26: it looped
        // "6 or so"). They follow, never lead: a library of only slow recipes still gets "Plan tonight", not a stew.
        // Same categories the suggestions used (the meal's own, else mains/soups) — no further fallback, so 8am never
        // runs on into slow curries or a dinner into slow desserts.
        let used = Set(suggested.map { $0.recipe.category.lowercased() })
        let kinds = used.isDisjoint(with: slot.categories) ? MealSlot.dinner.categories : slot.categories
        let more = longerPicks(recipes, kinds: kinds, slot: slot, dayKey: dayKey)
            .filter { $0.recipe.id != lastCookedID && seen.insert($0.recipe.id).inserted }
        return (unique, more)
    }

    /// Recipes ready in `quickLimitMinutes` or less, your own before built-in samples, in an order that changes each
    /// day (and meal) but holds still within it — a fixed "favourites, most cooked, A–Z" order put the same recipe on
    /// Today every day, which the owner found jarring.
    private static func quickPicks(_ recipes: [RecipeModel], slot: MealSlot, dayKey: String) -> [Hero] {
        recipes
            .compactMap { recipe in quickMinutes(of: recipe).map { (recipe, $0) } }
            .sorted { a, b in
                if a.0.isSampleRecipe != b.0.isSampleRecipe { return !a.0.isSampleRecipe }
                let ra = dailyRank(a.0.id, slot: slot, dayKey: dayKey), rb = dailyRank(b.0.id, slot: slot, dayKey: dayKey)
                return ra != rb ? ra < rb : a.0.name < b.0.name
            }
            .map { Hero(recipe: $0.0, reason: .quick(minutes: $0.1)) }
    }

    /// Recipes of `kinds` that take longer than `quickLimitMinutes`, your own first, in the same daily-varied order.
    private static func longerPicks(
        _ recipes: [RecipeModel], kinds: Set<String>, slot: MealSlot, dayKey: String
    ) -> [Hero] {
        recipes
            .filter { $0.totalMinutes > quickLimitMinutes && kinds.contains($0.category.lowercased()) }
            .map { ($0, dailyRank($0.id, slot: slot, dayKey: dayKey)) }
            .sorted { a, b in
                if a.0.isSampleRecipe != b.0.isSampleRecipe { return !a.0.isSampleRecipe }
                return a.1 != b.1 ? a.1 < b.1 : a.0.name < b.0.name
            }
            .map { Hero(recipe: $0.0, reason: .longer(minutes: $0.0.totalMinutes)) }
    }

    /// Stable across launches (FNV-1a, not Swift's per-launch seeded `Hasher`), different per day and meal.
    static func dailyRank(_ id: UUID, slot: MealSlot, dayKey: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in "\(dayKey)|\(slot.rawValue)|\(id.uuidString)".utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }

    static func dayKey(_ date: Date, calendar: Calendar) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    /// Which meal Today is suggesting for, by the clock: breakfast 5–11am, lunch 11am–4pm, dinner 4–9pm; late
    /// evening and the small hours look ahead to breakfast (owner 2026-11-20: "Today … is not time aware").
    enum MealSlot: String {
        case breakfast, lunch, dinner

        init(at date: Date, calendar: Calendar) {
            switch calendar.component(.hour, from: date) {
            case 5..<11: self = .breakfast
            case 11..<16: self = .lunch
            case 16..<NextMeal.lateEveningHour: self = .dinner
            default: self = .breakfast
            }
        }

        var mealTime: MealTime {
            switch self {
            case .breakfast: .breakfast
            case .lunch: .lunch
            case .dinner: .dinner
            }
        }

        /// Recipe categories that make sense as this meal (no desserts, sides or drinks as the main suggestion).
        var categories: Set<String> {
            switch self {
            case .breakfast: ["breakfast"]
            case .lunch: ["main", "soup", "starter"]
            case .dinner: ["main", "soup"]
            }
        }

        /// Suggestions fitting this meal; if none do, mains/soups; if still none, everything (a sparse library still
        /// gets a suggestion). Plans aren't passed through here — the cook chose those.
        func suitable(_ heroes: [Hero]) -> [Hero] {
            let fits = { (set: Set<String>) in heroes.filter { set.contains($0.recipe.category.lowercased()) } }
            let mine = fits(categories)
            if !mine.isEmpty { return mine }
            let mains = fits(MealSlot.dinner.categories)
            return mains.isEmpty ? heroes : mains
        }
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
        let prepared = RecipeModel.normalizedPantry(pantry)

        return recipes
            .compactMap { recipe -> KitchenMatch? in
                let total = recipe.ingredients.count
                guard total > 0 else { return nil }
                let have = total - recipe.missingIngredients(fromPrepared: prepared).count
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
