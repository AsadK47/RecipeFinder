import Foundation

/// Merge rules for lists the store shares with the cook's other devices (Data safety 2/4). Once iCloud sync is on,
/// the store can hold rows this device never saw, so "replace the store with my list" would delete them everywhere.
/// Rows are matched by `id`; within one list the first row with an id wins.
enum SyncMerge {
    /// Applies this device's edits (`base` → `local`) to the current `store`, keeping everything else:
    /// - rows deleted here (in `base`, not in `local`) are deleted;
    /// - rows added or changed here win;
    /// - rows left unchanged here take the store's version (another device may have edited them);
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
            if let before = baseByID[rowID], before == row, let current = storeByID[rowID] {
                merged.append(current)
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
