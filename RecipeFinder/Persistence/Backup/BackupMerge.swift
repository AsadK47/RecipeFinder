import Foundation

/// Pure, non-destructive merge rules for restoring a `BackupArchive`: keeps everything present, adds only genuinely new items. Store-independent so the dedupe logic is unit-tested in isolation.
enum BackupMerge {

    /// Union by identity: keep `existing`, then append `incoming` with unseen ids, preserving order.
    static func merged<T: Identifiable>(existing: [T], incoming: [T]) -> [T] {
        mergedWithAdditions(existing: existing, incoming: incoming).merged
    }

    /// `merged(existing:incoming:)` plus the items it appended, so callers can act on just the new ones.
    static func mergedWithAdditions<T: Identifiable>(existing: [T], incoming: [T]) -> (merged: [T], added: [T]) {
        var seen = Set(existing.map(\.id))
        var added: [T] = []
        for item in incoming where !seen.contains(item.id) {
            added.append(item)
            seen.insert(item.id)
        }
        return (existing + added, added)
    }

    /// Dedupe by id AND normalized name — re-imports often get a fresh UUID, so id-only would create visible duplicates.
    static func mergedRecipes(existing: [RecipeModel], incoming: [RecipeModel]) -> [RecipeModel] {
        mergedRecipesWithAdditions(existing: existing, incoming: incoming).merged
    }

    static func mergedRecipesWithAdditions(
        existing: [RecipeModel],
        incoming: [RecipeModel]
    ) -> (merged: [RecipeModel], added: [RecipeModel]) {
        var seenIDs = Set(existing.map(\.id))
        var seenNames = Set(existing.map { $0.name.nameKey })
        var added: [RecipeModel] = []
        for recipe in incoming {
            let name = recipe.name.nameKey
            guard !seenIDs.contains(recipe.id), !seenNames.contains(name) else { continue }
            added.append(recipe)
            seenIDs.insert(recipe.id)
            seenNames.insert(name)
        }
        return (existing + added, added)
    }

    /// Restoring onto recipes already here (same id). Samples are re-seeded with fixed ids before a restore, so a
    /// plain union kept the fresh copy and dropped the user's cooks, favourite, rating, tags and edits. Returns the
    /// stored recipes that change: state is merged (most cooks, latest cook, favourite if either, the stored rating
    /// unless unrated, tags unioned); the backup's text replaces a stored copy only when that copy is an untouched
    /// sample. Photos stay as stored — backups don't carry the image files.
    static func restoredUserState(
        existing: [RecipeModel],
        incoming: [RecipeModel],
        isPristineSample: (RecipeModel) -> Bool
    ) -> [RecipeModel] {
        let incomingByID = Dictionary(incoming.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return existing.compactMap { stored in
            guard let backup = incomingByID[stored.id] else { return nil }
            let takeText = isPristineSample(stored) && !BundledRecipeCatalog.hasSameContent(stored, backup)
            var merged = takeText ? backup : stored
            merged.id = stored.id
            merged.imageName = stored.imageName
            merged.photoNames = stored.photoNames
            merged.isSampleRecipe = stored.isSampleRecipe
            merged.cookCount = max(stored.cookCount, backup.cookCount)
            merged.lastCookedAt = [stored.lastCookedAt, backup.lastCookedAt].compactMap { $0 }.max()
            merged.isFavorite = stored.isFavorite || backup.isFavorite
            merged.rating = stored.rating > 0 ? stored.rating : backup.rating
            merged.tags = stored.tags + backup.tags.filter { !stored.tags.contains($0) }
            let stateChanged = merged.cookCount != stored.cookCount || merged.lastCookedAt != stored.lastCookedAt
                || merged.isFavorite != stored.isFavorite || merged.rating != stored.rating || merged.tags != stored.tags
            return takeText || stateChanged ? merged : nil
        }
    }

    /// Ids of exact duplicate recipes to remove: same name, ingredients and steps but different ids — left behind by
    /// older builds that re-seeded samples with random ids. In each group the copy the user has invested in most
    /// (cooked, favourited, rated, photographed, their own over a sample) is kept. Only sample copies are ever
    /// returned: the content key ignores amounts, notes and tags, so a user's own copy may be a deliberate variant.
    static func duplicateRecipeIDs(in recipes: [RecipeModel]) -> Set<UUID> {
        func contentKey(_ r: RecipeModel) -> String {
            ([r.name.nameKey] + r.ingredients.map { $0.name.nameKey } + r.instructions).joined(separator: "\u{1F}")
        }
        func investment(_ r: RecipeModel) -> [Int] {
            [r.cookCount, r.isFavorite ? 1 : 0, r.rating, r.photoNames.count, r.isSampleRecipe ? 0 : 1]
        }
        var remove = Set<UUID>()
        for group in Dictionary(grouping: recipes, by: contentKey).values where group.count > 1 {
            // max(by:) keeps the first of equal maxima, so ties keep the earliest copy.
            guard let keep = group.max(by: { investment($0).lexicographicallyPrecedes(investment($1)) }) else { continue }
            remove.formUnion(group.filter { $0.id != keep.id && $0.isSampleRecipe }.map(\.id))
        }
        return remove
    }

    /// On id collision keep the held badge — its `dateEarned` reflects this device's history.
    static func mergedBadges(existing: [String: Badge], incoming: [String: Badge]) -> [String: Badge] {
        mergedBadgesWithAdditions(existing: existing, incoming: incoming).merged
    }

    static func mergedBadgesWithAdditions(
        existing: [String: Badge],
        incoming: [String: Badge]
    ) -> (merged: [String: Badge], addedIDs: Set<String>) {
        let addedIDs = Set(incoming.keys).subtracting(existing.keys)
        return (existing.merging(incoming) { current, _ in current }, addedIDs)
    }
}
