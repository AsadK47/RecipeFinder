import Foundation

/// Merge rules for lists the store shares with the cook's other devices (Data safety 2/4). Once iCloud sync is on,
/// the store can hold rows this device never saw, so "replace the store with my list" would delete them everywhere.
/// Rows are matched by `id`; within one list the first row with an id wins.
enum SyncMerge {
    /// Applies this device's edits (`base` → `local`) to the current `store`, keeping everything else:
    /// - rows deleted here (in `base`, not in `local`) are deleted;
    /// - rows added or changed here win;
    /// - rows left unchanged here take the store's version (another device may have edited them), or are dropped
    ///   when the store no longer has them (deleted on another device or by Reset there);
    /// - rows only the store has (added elsewhere) are kept, after this device's rows, in store order.
    static func applyEdits<Value: Equatable, ID: Hashable>(
        base: [Value],
        local: [Value],
        store: [Value],
        id: (Value) -> ID
    ) -> [Value] {
        let baseByID = firstByID(base, id: id)
        let storeByID = firstByID(store, id: id)
        let localIDs = Set(local.map(id))
        let deletedHere = Set(baseByID.keys).subtracting(localIDs)

        var seen = Set<ID>()
        var merged: [Value] = []
        for row in local where seen.insert(id(row)).inserted {
            let rowID = id(row)
            if let before = baseByID[rowID], before == row {
                if let current = storeByID[rowID] { merged.append(current) }
            } else {
                merged.append(row)
            }
        }
        for row in store where !deletedHere.contains(id(row)) && seen.insert(id(row)).inserted {
            merged.append(row)
        }
        return merged
    }

    /// Adds a kept copy to the store without deleting anything: the copy's rows win (they hold edits the store
    /// missed), rows only the store has are kept after them. Used when a device first moves its blob into a
    /// store that may already hold another device's rows, and after a save that only reached the kept copy.
    static func addKeptCopy<Value, ID: Hashable>(_ kept: [Value], to store: [Value], id: (Value) -> ID) -> [Value] {
        var seen = Set<ID>()
        return (kept + store).filter { seen.insert(id($0)).inserted }
    }

    private static func firstByID<Value, ID: Hashable>(_ rows: [Value], id: (Value) -> ID) -> [ID: Value] {
        var byID: [ID: Value] = [:]
        for row in rows where byID[id(row)] == nil { byID[id(row)] = row }
        return byID
    }
}

/// Built-in recipes are added on every device with the same ids, so once iCloud sync brings two devices together
/// the store holds two rows per recipe (Data safety 2/4). This folds them into one, keeping what the cook did to
/// either copy (cooks, favourite, rating, photos).
///
/// Every device must delete the *same* copies, or two devices could each delete the other's and leave none. So the
/// kept copy is the one with the lowest iCloud record name — fixed once uploaded and identical on every device.
/// The copy every device keeps is never deleted, even by a device that hasn't received every copy yet. A copy not
/// uploaded yet has no record name, so its recipe waits for a later pass.
enum RecipeCopyMerge {
    struct Copy {
        let recordName: String?
        let recipe: RecipeModel
    }

    struct Plan: Equatable {
        /// Record name of a kept copy → its merged content, only where that differs from what it holds.
        var update: [String: RecipeModel] = [:]
        /// Record names of the copies to delete.
        var delete: Set<String> = []

        var isEmpty: Bool { update.isEmpty && delete.isEmpty }
    }

    static func plan(_ copies: [Copy]) -> Plan {
        var plan = Plan()
        for group in Dictionary(grouping: copies, by: \.recipe.id).values where group.count > 1 {
            let named = group.compactMap { copy in copy.recordName.map { (name: $0, recipe: copy.recipe) } }
            guard named.count == group.count,
                  let keep = named.min(by: { $0.name < $1.name }) else { continue }
            let others = named.filter { $0.name != keep.name }
            let merged = merging(others.map(\.recipe), into: keep.recipe)
            if merged != keep.recipe { plan.update[keep.name] = merged }
            plan.delete.formUnion(others.map(\.name))
        }
        return plan
    }

    /// The list shows each recipe once while copies wait to be merged; the first copy of each id stays.
    static func oneCopyEach(_ recipes: [RecipeModel]) -> [RecipeModel] {
        var seen = Set<UUID>()
        return recipes.filter { seen.insert($0.id).inserted }
    }

    /// The kept copy's text stays; the cook's own marks from every copy are added to it.
    private static func merging(_ others: [RecipeModel], into kept: RecipeModel) -> RecipeModel {
        var merged = kept
        for other in others {
            merged.cookCount = max(merged.cookCount, other.cookCount)
            merged.lastCookedAt = [merged.lastCookedAt, other.lastCookedAt].compactMap { $0 }.max()
            merged.isFavorite = merged.isFavorite || other.isFavorite
            if kept.rating == 0 { merged.rating = max(merged.rating, other.rating) }
            merged.photoNames += other.photoNames.filter { !merged.photoNames.contains($0) }
        }
        return merged
    }
}
