import Foundation

/// Picks a "you haven't made this in a while" recipe to nudge a comeback. Rediscovery is a proven
/// re-engagement lever and we already have the cook data — favour a loved/high-rated recipe that's
/// gone cold. Pure + testable.
enum RecipeRediscovery {
    /// The best stale recipe to resurface, or nil if nothing qualifies.
    /// "Stale" = cooked before (`cookCount > 0`) but not within `thresholdDays`.
    static func pick(
        from recipes: [RecipeModel],
        now: Date = Date(),
        calendar: Calendar = .current,
        thresholdDays: Int = 21
    ) -> RecipeModel? {
        guard let threshold = calendar.date(byAdding: .day, value: -thresholdDays, to: now) else { return nil }

        let stale = recipes.filter { recipe in
            guard recipe.cookCount > 0, let last = recipe.lastCookedAt else { return false }
            return last < threshold
        }

        // Most desirable = highest engagement score; ties broken toward the recipe cooked longest ago.
        return stale.max { a, b in
            let sa = score(a), sb = score(b)
            if sa != sb { return sa < sb }
            return (a.lastCookedAt ?? .distantPast) > (b.lastCookedAt ?? .distantPast)
        }
    }

    private static func score(_ recipe: RecipeModel) -> Int {
        (recipe.isFavorite ? 100 : 0) + recipe.rating * 10 + min(recipe.cookCount, 9)
    }
}
