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
