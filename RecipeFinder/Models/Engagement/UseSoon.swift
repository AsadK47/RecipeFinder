import Foundation

/// One row of Today's "Use it up": kitchen items going off soon and one recipe that uses them.
struct UseSoonPair: Equatable {
    /// Kitchen item names as the cook entered them, soonest to go off first.
    let itemNames: [String]
    /// Days until the first item goes off: 0 = today.
    let daysLeft: Int
    /// "today", "tomorrow" or a short weekday ("Thu").
    let when: String
    let recipe: RecipeModel

    /// "Spinach goes off Thu", "Spinach and Feta go off tomorrow" (names as entered). English throughout, like the
    /// rest of the app, so a device locale can't mix languages into one sentence.
    var message: String {
        let names = itemNames.count <= 1
            ? itemNames.joined()
            : itemNames.dropLast().joined(separator: ", ") + " and " + (itemNames.last ?? "")
        return "\(names) \(itemNames.count == 1 ? "goes" : "go") off \(when)"
    }
}

/// Pairs kitchen items expiring within `windowDays` with a recipe that uses each. Pure so the pairing is testable.
enum UseSoon {
    static let windowDays = 3
    static let limit = 3

    /// Items going off today…in `windowDays` days, soonest first, each with the best recipe that uses it. A recipe
    /// shows once: an item whose recipes are all taken (or with the rows full) joins the best row already showing a
    /// recipe that uses it ("Spinach and Feta go off Thu").
    /// Items no recipe uses are left out. Best = uses more of the expiring items, then more of the kitchen overall,
    /// then favourites, your own over samples, then name.
    static func pairs(
        items: [KitchenInventoryModel],
        recipes: [RecipeModel],
        kitchenItemNames: [String] = [],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [UseSoonPair] {
        let expiring = expiringItems(items, now: now, calendar: calendar)
        guard !expiring.isEmpty else { return [] }
        let kitchen = Set((kitchenItemNames + expiring.map(\.name)).map(KitchenRecipeMatcher.normalizedTerm))

        let candidates: [Candidate] = recipes.compactMap { recipe in
            let terms = recipe.ingredients.map { KitchenRecipeMatcher.normalizedTerm($0.name) }.filter { !$0.isEmpty }
            guard !terms.isEmpty else { return nil }
            let usesExpiring = expiring.filter { item in terms.contains { KitchenRecipeMatcher.ingredientMatches($0, item.term) } }
            guard !usesExpiring.isEmpty else { return nil }
            let kitchenShare = KitchenRecipeMatcher.matchCount(recipe: recipe, kitchenIngredients: kitchen)
            return Candidate(
                recipe: recipe, terms: Set(usesExpiring.map(\.term)),
                expiringUsed: usesExpiring.count, coverage: Double(kitchenShare) / Double(terms.count)
            )
        }
        .sorted(by: Candidate.isBetter)

        var rows: [(names: [String], days: Int, date: Date, recipe: RecipeModel)] = []
        for item in expiring {
            let uses = candidates.filter { $0.terms.contains(item.term) }
            let isShown = { (candidate: Candidate) in rows.contains { $0.recipe.id == candidate.recipe.id } }
            if rows.count < limit, let fresh = uses.first(where: { !isShown($0) }) {
                rows.append(([item.name], item.daysLeft, item.day, fresh.recipe))
            } else if let shown = uses.first(where: isShown),
                      let index = rows.firstIndex(where: { $0.recipe.id == shown.recipe.id }) {
                // No room or no other recipe: mention it on the best row already showing a recipe that uses it.
                rows[index].names.append(item.name)
            }
        }
        return rows.map { row in
            UseSoonPair(
                itemNames: row.names, daysLeft: row.days,
                when: whenLabel(daysLeft: row.days, day: row.date, calendar: calendar), recipe: row.recipe
            )
        }
    }

    /// "today", "tomorrow", else the short weekday name.
    static func whenLabel(daysLeft: Int, day: Date, calendar: Calendar) -> String {
        switch daysLeft {
        case ..<1: return "today"
        case 1: return "tomorrow"
        default:
            var english = calendar
            english.locale = Locale(identifier: "en_GB")
            let symbols = english.shortWeekdaySymbols
            let index = calendar.component(.weekday, from: day) - 1
            return symbols.indices.contains(index) ? symbols[index] : "soon"
        }
    }

    private struct ExpiringItem {
        let name: String
        let term: String
        let daysLeft: Int
        let day: Date
    }

    private struct Candidate {
        let recipe: RecipeModel
        /// Expiring item terms this recipe uses.
        let terms: Set<String>
        let expiringUsed: Int
        let coverage: Double

        static func isBetter(_ a: Candidate, _ b: Candidate) -> Bool {
            if a.expiringUsed != b.expiringUsed { return a.expiringUsed > b.expiringUsed }
            if a.coverage != b.coverage { return a.coverage > b.coverage }
            if a.recipe.isFavorite != b.recipe.isFavorite { return a.recipe.isFavorite }
            if a.recipe.isSampleRecipe != b.recipe.isSampleRecipe { return !a.recipe.isSampleRecipe }
            return a.recipe.name < b.recipe.name
        }
    }

    /// In-window items (0…`windowDays` days left, counted in calendar days from `now`), one per ingredient, soonest
    /// first then by name. Already-expired items are the Kitchen's job, not a cooking idea.
    private static func expiringItems(_ items: [KitchenInventoryModel], now: Date, calendar: Calendar) -> [ExpiringItem] {
        let today = calendar.startOfDay(for: now)
        var seen = Set<String>()
        return items
            .compactMap { item -> ExpiringItem? in
                guard let expiry = item.expiryDate, item.quantity > 0 else { return nil }
                let day = calendar.startOfDay(for: expiry)
                guard let days = calendar.dateComponents([.day], from: today, to: day).day,
                      (0...windowDays).contains(days) else { return nil }
                let term = KitchenRecipeMatcher.normalizedTerm(item.name)
                guard !term.isEmpty else { return nil }
                return ExpiringItem(name: item.name.trimmingCharacters(in: .whitespaces), term: term, daysLeft: days, day: day)
            }
            .sorted { ($0.daysLeft, $0.name.lowercased()) < ($1.daysLeft, $1.name.lowercased()) }
            .filter { seen.insert($0.term).inserted }
    }
}
