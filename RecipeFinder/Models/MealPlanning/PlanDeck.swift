import Foundation

/// "Plan my week": one card per empty dinner, drawn by the Fill-my-week rules — quick on weeknights, longer ones at
/// weekends, not the same cuisine two nights running, kitchen items that are expiring first, then favourites and
/// well-rated dishes. ♥ plans the card for its night; ✕ shows another dish for the same night. A dish already on the
/// week or picked here is never dealt again; one passed on comes back on a later night only once the fresh ones are
/// gone, so a small library still fills the week; one passed in an earlier deck (`PlanDeckMemory`, 30 days) starts out
/// passed. A night marked busy deals quick dishes first (the shortest cook
/// when nothing is quick), whatever the day. Pure value type, seeded, so the deck is testable.
struct PlanDeck {
    struct Card: Equatable, Identifiable {
        let day: Date
        let recipe: RecipeModel
        let reason: String
        var id: String { "\(day.timeIntervalSinceReferenceDate)-\(recipe.id)" }
    }

    struct Pick: Equatable {
        let day: Date
        let recipe: RecipeModel
    }

    /// One dish the deck can deal, with what the rules need worked out once.
    private struct Candidate {
        let recipe: RecipeModel
        let minutes: Int
        let cuisine: String?
        /// Expiring kitchen items this dish uses, in kitchen order.
        let expiring: [String]
    }

    /// Longer than this on a weeknight counts against a dish.
    static let longWeeknightMinutes = 45

    /// The empty dinners being planned, in order.
    let days: [Date]
    private(set) var dayIndex = 0
    private(set) var current: Card?
    private(set) var picks: [Pick] = []
    private let candidates: [Candidate]
    /// On the week already or picked here: never dealt again.
    private var taken: Set<UUID>
    /// Passed on for some night (here or in a recent deck): dealt again only behind every fresh dish.
    private var passed: Set<UUID>
    /// Already shown for the night being planned.
    private var shownTonight: Set<UUID> = []
    /// Nights the cook marked busy in this deck: quick dishes first.
    private var busyDays: Set<Date> = []
    /// Cuisine of each dinner already on the plan (or picked here), by start of day.
    private var cuisineByDay: [Date: String]
    private let calendar: Calendar

    /// - Parameters:
    ///   - days: the empty dinners to plan (see `emptyDinnerDays`).
    ///   - plannedThisWeek: the week's existing plans — their dishes aren't dealt again and their cuisines count for
    ///     variety.
    ///   - expiringItemNames: kitchen items expiring soon, most urgent first.
    ///   - recentlyPassed: dishes passed on in a recent deck (`PlanDeckMemory`): dealt behind fresh ones.
    init(
        days: [Date],
        recipes: [RecipeModel],
        plannedThisWeek: [MealPlanModel],
        expiringItemNames: [String],
        recentlyPassed: Set<UUID> = [],
        seed: UInt64,
        calendar: Calendar = .current
    ) {
        self.calendar = calendar
        self.days = days.map { calendar.startOfDay(for: $0) }
        let byID = Dictionary(recipes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        taken = Set(plannedThisWeek.map(\.recipeId))
        passed = recentlyPassed
        var cuisines: [Date: String] = [:]
        for plan in plannedThisWeek where plan.mealTime == .dinner {
            if let cuisine = byID[plan.recipeId].flatMap(Self.cuisineKey) {
                cuisines[calendar.startOfDay(for: plan.date)] = cuisine
            }
        }
        cuisineByDay = cuisines

        let expiringTerms = expiringItemNames.compactMap { name in
            KitchenRecipeMatcher.matchTerm(name).map { (name, $0) }
        }
        var generator = SeededGenerator(seed: seed)
        candidates = Self.dinnerRecipes(recipes)
            .sorted { $0.name < $1.name }
            .shuffled(using: &generator)
            .map { recipe in
                // Normalising is regex work: skip it for the whole library when nothing is expiring.
                let terms: [KitchenRecipeMatcher.MatchTerm] = expiringTerms.isEmpty
                    ? [] : recipe.ingredients.compactMap { KitchenRecipeMatcher.matchTerm($0.name) }
                let uses = expiringTerms.filter { item in
                    terms.contains { KitchenRecipeMatcher.ingredientMatches($0, item.1) }
                }.map(\.0)
                return Candidate(recipe: recipe, minutes: recipe.totalMinutes,
                                 cuisine: Self.cuisineKey(recipe), expiring: uses)
            }
        current = deal()
    }

    /// Days from today to the end of `week` with no dinner planned.
    static func emptyDinnerDays(
        week: [Date], plans: [MealPlanModel], today: Date, calendar: Calendar = .current
    ) -> [Date] {
        let start = calendar.startOfDay(for: today)
        return week
            .map { calendar.startOfDay(for: $0) }
            .filter { $0 >= start }
            .filter { day in !plans.contains { $0.isSlot(day, .dinner, calendar: calendar) } }
    }

    /// The week Plan my week deals for: the shown week while it has an empty dinner from today, else the first week
    /// after it (and after this one) that does, within `weeksAhead`. Nil when every dinner that far is planned.
    /// Owner 2026-11-20: once the shown week was full the button vanished, so the deck "worked once, then never again".
    static func weekToPlan(
        showing shown: Date, plans: [MealPlanModel], today: Date, weeksAhead: Int = 4,
        calendar: Calendar = .current
    ) -> Date? {
        let planner = MealPlanCalendar(calendar: calendar)
        guard let shownStart = planner.weekRange(containing: shown)?.start,
              let thisWeek = planner.weekRange(containing: today)?.start else { return nil }
        var week = max(shownStart, thisWeek)
        for _ in 0...weeksAhead {
            if !emptyDinnerDays(week: planner.daysInWeek(containing: week), plans: plans, today: today,
                                calendar: calendar).isEmpty {
                return week
            }
            guard let next = calendar.date(byAdding: .weekOfYear, value: 1, to: week) else { return nil }
            week = next
        }
        return nil
    }

    /// Mains and soups; a library with neither offers everything (same rule as Today's dinner pick).
    static func dinnerRecipes(_ recipes: [RecipeModel]) -> [RecipeModel] {
        let dinner: Set<String> = ["main", "soup"]
        let mains = recipes.filter { dinner.contains($0.category.trimmingCharacters(in: .whitespaces).lowercased()) }
        return mains.isEmpty ? recipes : mains
    }

    var isFinished: Bool { current == nil }

    /// "2 of 5" — the night being planned, counted from 1.
    var position: (night: Int, of: Int) {
        (min(dayIndex + 1, days.count), days.count)
    }

    /// The closing card's heading and line once every night has been dealt.
    var finishedCopy: (title: String, message: String) {
        if !picks.isEmpty {
            let dinners = picks.count == 1 ? "1 dinner" : "\(picks.count) dinners"
            return ("\(dinners) planned", "They're on your week. Tap one there to cook it.")
        }
        if days.isEmpty {
            return ("Your week is planned", "Every dinner from today has a dish.")
        }
        return ("That's every dish for now", "Plan the rest from your week, or add recipes on Recipes for more to choose from.")
    }

    /// Plans the current card's dish for its night and moves to the next night.
    mutating func plan() {
        guard let card = current else { return }
        picks.append(Pick(day: card.day, recipe: card.recipe))
        taken.insert(card.recipe.id)
        if let cuisine = Self.cuisineKey(card.recipe) { cuisineByDay[card.day] = cuisine }
        nextNight()
    }

    /// Passes on the current dish and deals another for the same night (or moves on when none is left).
    mutating func skip() {
        guard let card = current else { return }
        passed.insert(card.recipe.id)
        current = deal()
    }

    var isCurrentNightBusy: Bool {
        current.map { busyDays.contains($0.day) } ?? false
    }

    /// Marks the current night busy (or not) and deals the best dish for it again. The card on screen can come back;
    /// others already shown for this night don't (the cook said no to them for it).
    mutating func setBusy(_ busy: Bool) {
        guard let card = current, busy != busyDays.contains(card.day) else { return }
        if busy { busyDays.insert(card.day) } else { busyDays.remove(card.day) }
        shownTonight.remove(card.recipe.id)
        current = deal()
    }

    /// Leaves the current night empty and moves to the next one; its dish stays fresh for the nights after.
    mutating func skipNight() {
        guard current != nil else { return }
        nextNight()
    }

    private mutating func nextNight() {
        dayIndex += 1
        shownTonight = []
        current = deal()
    }

    /// The best dish not yet shown for the current night, fresh ones before passed ones; a night with nothing left
    /// is left empty.
    private mutating func deal() -> Card? {
        while dayIndex < days.count {
            let day = days[dayIndex]
            // A busy night ranks by time first: a quick dish passed on earlier beats a fresh long cook, but among
            // equally quick ones fresh still comes first.
            let busy = busyDays.contains(day)
            var best: (candidate: Candidate, rank: (Int, Int, Int))?  // (time, fresh, score)
            for candidate in candidates {
                let id = candidate.recipe.id
                guard !taken.contains(id), !shownTonight.contains(id) else { continue }
                let rank = (busy ? busyTimeRank(candidate) : 0, passed.contains(id) ? 0 : 1, score(candidate, on: day))
                if best.map({ rank > $0.rank }) ?? true { best = (candidate, rank) }
            }
            if let best {
                shownTonight.insert(best.candidate.recipe.id)
                return Card(day: day, recipe: best.candidate.recipe, reason: reason(best.candidate, on: day))
            }
            dayIndex += 1
            shownTonight = []
        }
        return nil
    }

    private func isWeekend(_ day: Date) -> Bool { calendar.isDateInWeekend(day) }

    private func neighbourCuisines(of day: Date) -> [String] {
        [-1, 1].compactMap { offset in
            // Re-anchored: where DST starts at midnight, day + 1 isn't that day's start.
            calendar.date(byAdding: .day, value: offset, to: day).flatMap { cuisineByDay[calendar.startOfDay(for: $0)] }
        }
    }

    /// Busy nights: every quick dish ranks equal and above the rest, then the shorter cook; untimed counts as an hour.
    private func busyTimeRank(_ candidate: Candidate) -> Int {
        guard TodayFeed.quickMinutes(of: candidate.recipe) == nil else { return 0 }
        return -(candidate.minutes > 0 ? candidate.minutes : 60)
    }

    private func score(_ candidate: Candidate, on day: Date) -> Int {
        var total = 0
        let quick = TodayFeed.quickMinutes(of: candidate.recipe) != nil
        if busyDays.contains(day) {
            // Time already ranked first (busyTimeRank); the rules below only break ties.
        } else if isWeekend(day) {
            if candidate.minutes > TodayFeed.quickLimitMinutes { total += 1 }
        } else if quick {
            total += 3
        } else if candidate.minutes > Self.longWeeknightMinutes {
            total -= 3
        }
        if let cuisine = candidate.cuisine, neighbourCuisines(of: day).contains(cuisine) { total -= 4 }
        total += min(candidate.expiring.count, 2) * 2
        if candidate.recipe.isFavorite { total += 1 }
        if candidate.recipe.rating >= 4 { total += 1 }
        return total
    }

    /// Why this dish, for this night — the strongest rule that picked it.
    private func reason(_ candidate: Candidate, on day: Date) -> String {
        if busyDays.contains(day) {
            guard candidate.minutes > 0 else { return "Check the cook time suits a busy night" }
            let time = DurationFormatter.label(minutes: candidate.minutes)
            return TodayFeed.quickMinutes(of: candidate.recipe) != nil
                ? "Quick for a busy night · \(time)" : "Shortest cook left for a busy night · \(time)"
        }
        if let item = candidate.expiring.first {
            return "Uses your \(item.lowercased()) while it's fresh"
        }
        let minutes = candidate.minutes
        if !isWeekend(day), TodayFeed.quickMinutes(of: candidate.recipe) != nil {
            return "Quick for a weeknight · \(DurationFormatter.label(minutes: minutes))"
        }
        if isWeekend(day), minutes > TodayFeed.quickLimitMinutes {
            return "A weekend cook · \(DurationFormatter.label(minutes: minutes))"
        }
        if candidate.recipe.isFavorite { return "One of your favourites" }
        if candidate.recipe.rating >= 4 { return "You rated it \(candidate.recipe.rating) stars" }
        if let cuisine = candidate.recipe.cuisine?.trimmingCharacters(in: .whitespaces), !cuisine.isEmpty {
            return "A night of \(cuisine) food"
        }
        return "Something new for the week"
    }

    private static func cuisineKey(_ recipe: RecipeModel) -> String? {
        let key = recipe.cuisine?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        return key.isEmpty ? nil : key
    }
}
