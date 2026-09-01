import Foundation

/// Pure, non-destructive merge rules for restoring a `BackupArchive` into a user's
/// current library. Kept separate from any store so the dedupe logic — the part
/// most likely to silently lose or duplicate data — is unit-tested in isolation.
///
/// Non-destructive means: everything currently present is kept; only genuinely new
/// items from the backup are added.
enum BackupMerge {

    /// Union by identity: keep all `existing`, then append `incoming` whose id isn't
    /// already present. Existing order is preserved; new items append in order.
    static func merged<T: Identifiable>(existing: [T], incoming: [T]) -> [T] {
        var seen = Set(existing.map(\.id))
        var result = existing
        for item in incoming where !seen.contains(item.id) {
            result.append(item)
            seen.insert(item.id)
        }
        return result
    }

    /// Recipes dedupe by id AND by normalized name — re-imports of the same recipe
    /// often get a fresh UUID, so an id-only merge would create visible duplicates.
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

    /// Badges keyed by id; on a key collision keep the currently-held badge (its
    /// `dateEarned` reflects this device's history).
    static func mergedBadges(existing: [String: Badge], incoming: [String: Badge]) -> [String: Badge] {
        existing.merging(incoming) { current, _ in current }
    }

    private static func normalizedName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
