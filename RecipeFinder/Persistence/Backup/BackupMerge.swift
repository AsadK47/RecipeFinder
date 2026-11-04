import Foundation

/// Pure, non-destructive merge rules for restoring a `BackupArchive`: keeps everything present, adds only genuinely new items. Store-independent so the dedupe logic is unit-tested in isolation.
enum BackupMerge {

    /// Union by identity: keep `existing`, then append `incoming` with unseen ids, preserving order.
    static func merged<T: Identifiable>(existing: [T], incoming: [T]) -> [T] {
        var seen = Set(existing.map(\.id))
        var result = existing
        for item in incoming where !seen.contains(item.id) {
            result.append(item)
            seen.insert(item.id)
        }
        return result
    }

    /// Dedupe by id AND normalized name — re-imports often get a fresh UUID, so id-only would create visible duplicates.
    static func mergedRecipes(existing: [RecipeModel], incoming: [RecipeModel]) -> [RecipeModel] {
        var seenIDs = Set(existing.map(\.id))
        var seenNames = Set(existing.map { normalizedName($0.name) })
        var result = existing
        for recipe in incoming {
            let name = normalizedName(recipe.name)
            guard !seenIDs.contains(recipe.id), !seenNames.contains(name) else { continue }
            result.append(recipe)
            seenIDs.insert(recipe.id)
            seenNames.insert(name)
        }
        return result
    }

    /// On id collision keep the held badge — its `dateEarned` reflects this device's history.
    static func mergedBadges(existing: [String: Badge], incoming: [String: Badge]) -> [String: Badge] {
        existing.merging(incoming) { current, _ in current }
    }

    private static func normalizedName(_ name: String) -> String {
        name.trimmed.lowercased()
    }
}
