import Foundation

enum MirroredSnapshotError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed: "The database didn't hold what was just saved."
        }
    }
}

/// A store that can name the database file it reads (`NSPersistentStore.identifier`, new for every fresh file).
@MainActor
protocol StoreFileIdentifying: AnyObject {
    var storeFileID: String? { get }
}

extension StoreFileIdentifying {
    /// Unknown: an empty store at launch is treated as recovery and gets the kept copy back.
    var storeFileID: String? { nil }
}

/// Keeps a whole-list `LocalStore` blob (collections, meal plans, shopping list…) in Core Data entities (Data safety
/// 1/4), with the blob kept current for one release as a fallback.
///
/// - First load copies the blob in, re-reads it and checks it matches before marking the key migrated.
/// - The blob is always written first, so it's never behind the store. That makes it safe to copy it in again
///   whenever the key is unmarked: any launch where the store can't be read or written runs on the blob and unmarks,
///   so the next launch replaces the store with the blob (edits, renames and deletes all carry over, no duplicates).
/// - A store that differs from the blob (save cut short, a blob-only build ran in between, recovery emptied the store)
///   is replaced by the blob.
/// - With `SyncRules` on (iCloud, Data safety 2/4) the store can hold other devices' rows, so it wins instead: the
///   kept copy follows the store, saves apply this device's edits on top of what the store holds now
///   (`SyncMerge.applyEdits`), and a kept copy is only ever added to the store, never replaces it.
/// - Reset records a pending wipe, retried each launch, so a failed delete never brings erased data back.
/// - If the store can't be read and there's no readable blob either, nothing is written this launch: replacing the
///   store from a blob that doesn't hold its contents would erase them.
@MainActor
final class MirroredSnapshot<Value: Codable & Equatable> {
    /// When the store is shared through iCloud. `isOn` is read on each `load()`; `id` matches rows across devices.
    struct SyncRules {
        let isOn: () -> Bool
        let id: (Value) -> AnyHashable
        /// Names the store file (`StoreFileIdentifying`); nil when unknown. An empty store in the same file this
        /// device last loaded was emptied on another device, so launch follows it instead of adding the kept copy.
        var storeFile: () -> String? = { nil }
        /// Rows with different ids that mean one thing (the same item added on two devices) are folded into one on
        /// load (`SyncMerge.foldSameThing`). Nil: rows are only matched by id.
        var sameThing: SameThing? = nil

        struct SameThing {
            let key: (Value) -> AnyHashable
            /// Fixed and identical on every device (the id as text): the lowest is the row every device keeps.
            let rank: (Value) -> String
            /// What the kept row takes from the others; must not depend on their order.
            let fold: (_ kept: Value, _ others: [Value]) -> Value
        }

        /// The rules every manager uses: on while the cook's iCloud sync switch (`SyncPreference`) is on.
        @MainActor
        static func iCloudRules<ID: Hashable>(
            storage: LocalStore,
            store: any StoreFileIdentifying,
            id: @escaping (Value) -> ID,
            sameThing: SameThing? = nil
        ) -> SyncRules {
            SyncRules(
                isOn: { SyncPreference.isOn(in: storage) },
                id: { AnyHashable(id($0)) },
                storeFile: { [weak store] in store?.storeFileID },
                sameThing: sameThing
            )
        }
    }

    private let blobKey: String
    private let storage: LocalStore
    private let readBlob: () -> [Value]?
    private let writeBlob: ([Value]) -> Void
    private let removeBlob: () -> Void
    private let fetch: () throws -> [Value]
    private let replace: ([Value]) throws -> Void
    private let sync: SyncRules?
    private let logger = AppLogger.logger(category: "MirroredSnapshot")

    /// False when the store can't be used this launch: the blob is read and written instead.
    private var usesEntities = false
    /// Store unreadable and no blob to stand in for it: edits stay in memory only this launch.
    private var savesDisabled = false
    /// Sync rules apply until the next `load()`.
    private var syncActive = false
    /// The list as this device last loaded or saved it: the base `SyncMerge.applyEdits` diffs edits against.
    private var lastKnown: [Value] = []
    /// Set once a shared-store load succeeds. After that an empty store was emptied on another device (recovery and
    /// a first import only happen at launch), so a reload follows it instead of adding the kept copy back.
    private var hasLoadedSharedStore = false

    /// The kept copy is a JSON `[Value]` under `blobKey`.
    convenience init(
        blobKey: String,
        storage: LocalStore,
        fetch: @escaping () throws -> [Value],
        replace: @escaping ([Value]) throws -> Void,
        sync: SyncRules? = nil
    ) {
        self.init(
            blobKey: blobKey,
            storage: storage,
            // `LocalStore` keeps an undecodable blob aside as `<key>.corrupt`, so nil means missing or corrupt.
            readBlob: { storage.decodable([Value].self, forKey: blobKey) },
            writeBlob: { storage.setEncodable($0, forKey: blobKey) },
            removeBlob: { storage.removeObject(forKey: blobKey) },
            fetch: fetch,
            replace: replace,
            sync: sync
        )
    }

    /// For a kept copy in an older shape (badges: a dictionary plus a list of shown ids). `readBlob` returns nil
    /// when the copy is missing or unreadable; `blobKey` names the flags and logs.
    init(
        blobKey: String,
        storage: LocalStore,
        readBlob: @escaping () -> [Value]?,
        writeBlob: @escaping ([Value]) -> Void,
        removeBlob: @escaping () -> Void,
        fetch: @escaping () throws -> [Value],
        replace: @escaping ([Value]) throws -> Void,
        sync: SyncRules? = nil
    ) {
        self.blobKey = blobKey
        self.storage = storage
        self.readBlob = readBlob
        self.writeBlob = writeBlob
        self.removeBlob = removeBlob
        self.fetch = fetch
        self.replace = replace
        self.sync = sync
    }

    /// Own namespace: `LegacyBlobMigration`'s flag means "added what was missing", this one "store mirrors the blob".
    static func flagKey(for blobKey: String) -> String { "mirroredToCoreData.\(blobKey)" }

    private var flagKey: String { Self.flagKey(for: blobKey) }
    private var wipePendingKey: String { "wipePending.\(blobKey)" }
    /// Set while syncing when a save reached only the kept copy; the next load adds the copy to the store.
    private var keptCopyAheadKey: String { "keptCopyAhead.\(blobKey)" }
    /// The store file of this device's last shared-store load.
    private var loadedStoreFileKey: String { "syncedStoreFile.\(blobKey)" }

    private func blob() -> [Value]? {
        readBlob()
    }

    func load() -> [Value] {
        savesDisabled = false
        if let sync, sync.isOn() {
            syncActive = true
            return loadSharedStore(sync)
        }
        syncActive = false
        guard finishPendingWipe() else { return fallBackToBlob() }
        do {
            if !storage.bool(forKey: flagKey) {
                if let values = blob() {
                    try copyIn(values)
                    logger.info("✅ \(self.blobKey, privacy: .public): moved \(values.count) values to Core Data")
                }
                storage.set(true, forKey: flagKey)
            }
            var values = try fetch()
            if let kept = blob(), kept != values {
                // The kept copy is written first, so it's never behind: a save cut short by the app being killed, an
                // older build that only wrote the blob, or recovery replacing the store with an empty one.
                logger.error("⚠️ \(self.blobKey, privacy: .public): store differs from the kept copy; copying the kept copy in")
                try copyIn(kept)
                values = kept
            }
            usesEntities = true
            return values
        } catch {
            logger.error("❌ \(self.blobKey, privacy: .public): store unusable, using the kept copy: \(error.localizedDescription)")
            return fallBackToBlob()
        }
    }

    func save(_ values: [Value]) {
        guard !savesDisabled else {
            logger.error("❌ \(self.blobKey, privacy: .public): not saved, store and kept copy both unreadable")
            return
        }
        if syncActive, let sync {
            saveToSharedStore(values, sync)
            return
        }
        writeBlob(values)
        guard usesEntities else { return }
        do {
            try replace(values)
        } catch {
            logger.error("❌ \(self.blobKey, privacy: .public): failed to save, kept in the old copy: \(error.localizedDescription)")
            usesEntities = false
            storage.removeObject(forKey: flagKey)
        }
    }

    /// Erase & Reset. Call `load()` afterwards.
    func removeAll() {
        removeBlob()
        storage.set(true, forKey: wipePendingKey)
    }

    // MARK: - Sync rules

    private func loadSharedStore(_ sync: SyncRules) -> [Value] {
        guard finishPendingWipe() else { return fallBackKeepingStore() }
        do {
            var values = try fetch()
            let storeFile = sync.storeFile()
            // An empty store next to a non-empty kept copy is recovery (a fresh store file) or an unfinished first
            // import, unless it's the very file this device last loaded: then the rows were deleted elsewhere.
            let emptiedElsewhere = hasLoadedSharedStore
                || (storeFile != nil && storeFile == storage.string(forKey: loadedStoreFileKey))
            let keptCopyMayBeAhead = !storage.bool(forKey: flagKey) || storage.bool(forKey: keptCopyAheadKey)
                || (values.isEmpty && !emptiedElsewhere)
            if keptCopyMayBeAhead, let kept = blob() {
                let merged = SyncMerge.addKeptCopy(kept, to: values, id: sync.id)
                if merged != values {
                    values = try copyInShared(merged, sync)
                    logger.info("✅ \(self.blobKey, privacy: .public): added the kept copy to the shared store")
                }
            }
            if let same = sync.sameThing {
                let folded = SyncMerge.foldSameThing(values, key: same.key, rank: same.rank, fold: same.fold)
                if folded != values {
                    let foldedAway = values.count - folded.count
                    values = try copyInShared(folded, sync)
                    logger.info("✅ \(self.blobKey, privacy: .public): folded rows added for the same thing on another device (\(foldedAway) removed)")
                }
            }
            storage.set(true, forKey: flagKey)
            storage.removeObject(forKey: keptCopyAheadKey)
            if let storeFile { storage.set(storeFile, forKey: loadedStoreFileKey) }
            if blob() != values { writeBlob(values) }
            usesEntities = true
            lastKnown = values
            hasLoadedSharedStore = true
            return values
        } catch {
            logger.error("❌ \(self.blobKey, privacy: .public): shared store unusable, using the kept copy: \(error.localizedDescription)")
            return fallBackKeepingStore()
        }
    }

    private func saveToSharedStore(_ values: [Value], _ sync: SyncRules) {
        guard usesEntities else {
            keepAhead(values)
            return
        }
        do {
            let merged = SyncMerge.applyEdits(base: lastKnown, local: values, store: try fetch(), id: sync.id)
            try replace(merged)
            lastKnown = values
            writeBlob(merged)
        } catch {
            logger.error("❌ \(self.blobKey, privacy: .public): failed to save to the shared store, kept in the old copy: \(error.localizedDescription)")
            usesEntities = false
            keepAhead(values)
        }
    }

    /// The save reached only the kept copy: the next load adds it to the store. Add-only, so rows deleted here or
    /// elsewhere meanwhile can come back, and the copy's version wins on shared ids — accepted: nothing is lost.
    private func keepAhead(_ values: [Value]) {
        writeBlob(values)
        storage.set(true, forKey: keptCopyAheadKey)
    }

    /// Like `fallBackToBlob`, but leaves the key marked: the next load adds the kept copy rather than replacing.
    private func fallBackKeepingStore() -> [Value] {
        usesEntities = false
        let kept = blob()
        guard kept != nil || storage.bool(forKey: wipePendingKey) else {
            savesDisabled = true
            return []
        }
        return kept ?? []
    }

    private func copyIn(_ values: [Value]) throws {
        try replace(values)
        guard try fetch() == values else { throw MirroredSnapshotError.verificationFailed }
    }

    /// Like `copyIn`, but the store may list rows in its own order (badges by id): checks every row arrived and
    /// returns them as the store lists them, so the kept copy and the merge base match what later loads see.
    private func copyInShared(_ values: [Value], _ sync: SyncRules) throws -> [Value] {
        try replace(values)
        let stored = try fetch()
        var storedByID: [AnyHashable: Value] = [:]
        for row in stored where storedByID[sync.id(row)] == nil { storedByID[sync.id(row)] = row }
        guard stored.count == values.count, values.allSatisfy({ storedByID[sync.id($0)] == $0 }) else {
            throw MirroredSnapshotError.verificationFailed
        }
        return stored
    }

    /// Unmarks so the next launch replaces the store with the blob — only safe when there is a blob to replace it
    /// with, or a pending wipe will empty the store first anyway.
    private func fallBackToBlob() -> [Value] {
        usesEntities = false
        let kept = blob()
        guard kept != nil || storage.bool(forKey: wipePendingKey) else {
            savesDisabled = true
            return []
        }
        storage.removeObject(forKey: flagKey)
        return kept ?? []
    }

    /// True when no Reset wipe is outstanding.
    private func finishPendingWipe() -> Bool {
        guard storage.bool(forKey: wipePendingKey) else { return true }
        do {
            try replace([])
            storage.removeObject(forKey: wipePendingKey)
            return true
        } catch {
            logger.error("❌ \(self.blobKey, privacy: .public): failed to erase, will retry next launch: \(error.localizedDescription)")
            return false
        }
    }
}
