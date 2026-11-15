import Foundation

/// Recently Deleted (Data safety 4/4): a deleted recipe is hidden everywhere but kept, with its photos, for
/// `RecentlyDeleted.keptFor`; then (when `RecentlyDeleted.mayPurge` allows) it, or one the cook deletes from Recently
/// Deleted, goes for good with its photos — files here, and their iCloud copies through the usual photo pass
/// (`RecipePhotoSync.removedPaths`).
extension RecipeStore {
    /// Moves the recipe to Recently Deleted: hidden everywhere, photos and kept web pictures untouched (with sync on,
    /// other devices hide it too when the change arrives). A recipe held only in memory (a quick snack) has nothing to
    /// keep and just leaves the list.
    @discardableResult
    func delete(id: UUID) -> Bool {
        let deletedAt = Date()
        guard persistence.moveRecipeToRecentlyDeleted(withId: id, at: deletedAt) else {
            guard persistence.recipeRowCount(withId: id) == 0 else { return false }
            recipes.removeAll { $0.id == id }
            return true
        }
        if let recipe = recipes.first(where: { $0.id == id }) {
            recentlyDeleted.removeAll { $0.id == id }
            recentlyDeleted.insert(DeletedRecipe(recipe: recipe, deletedAt: deletedAt), at: 0)
        } else {
            // Not in the loaded library (e.g. it arrived after the last load): read the list back so it shows there.
            recentlyDeleted = persistence.fetchRecentlyDeletedRecipes()
        }
        recipes.removeAll { $0.id == id }
        return true
    }

    /// Puts the recipe back in the library, re-read from the store and in name order.
    @discardableResult
    func restore(id: UUID) -> Bool {
        guard let item = recentlyDeleted.first(where: { $0.id == id }),
              persistence.restoreRecentlyDeletedRecipe(withId: id) else { return false }
        recentlyDeleted.removeAll { $0.id == id }
        let restored = persistence.fetchRecipe(withId: id) ?? item.recipe
        recipes.removeAll { $0.id == id }
        let index = recipes.firstIndex {
            $0.name.localizedCaseInsensitiveCompare(restored.name) == .orderedDescending
        } ?? recipes.endIndex
        recipes.insert(restored, at: index)
        return true
    }

    @discardableResult
    func deleteForever(id: UUID) -> Bool {
        guard let item = recentlyDeleted.first(where: { $0.id == id }),
              persistence.deleteRecentlyDeletedRecipe(withId: id) else { return false }
        recentlyDeleted.removeAll { $0.id == id }
        // A copy of the same recipe still in the library keeps the photos.
        if persistence.recipeRowCount(withId: id) == 0 {
            syncPhotosWithICloud(removing: removePhotos(of: [item.recipe]))
        }
        return true
    }

    /// Re-reads Recently Deleted (off the main thread), first removing for good what `RecentlyDeleted.mayPurge`
    /// allows, with its photos. Returns the photo paths whose iCloud copies should go (for the next photo pass).
    func purgeExpired(now: Date = Date()) async -> Set<String> {
        let load = await persistence.loadRecentlyDeleted(now: now, purgingWith: purgeSyncState)
        recentlyDeleted = load.trash
        guard !load.purged.isEmpty else { return [] }
        return removePhotos(of: load.purged)
    }

    /// The first finished iCloud import this launch: from now on the purge may run (`RecentlyDeleted.mayPurge`), so
    /// run it once here — a launch whose import brings no outside changes triggers no further load. Returns the
    /// purge task (nil when it already ran), for tests.
    @discardableResult
    func iCloudImportFinished() -> Task<Void, Never>? {
        guard !persistence.finishedICloudImportThisLaunch else { return nil }
        persistence.finishedICloudImportThisLaunch = true
        return Task {
            let purged = await purgeExpired()
            guard !purged.isEmpty else { return }
            syncPhotosWithICloud(removing: purged)
        }
    }

    /// This device's iCloud state for the purge.
    var purgeSyncState: RecentlyDeleted.SyncState {
        RecentlyDeleted.SyncState(
            everSynced: SyncPreference.hasEverSynced(in: syncStorage),
            lastExportStart: HistoryPurgeRule.lastExportStart(in: syncStorage),
            importSeenThisLaunch: persistence.finishedICloudImportThisLaunch
        )
    }

    /// Every recipe whose photos must stay: the library and Recently Deleted.
    var libraryWithRecentlyDeleted: [RecipeModel] {
        recipes + recentlyDeleted.map(\.recipe)
    }

    /// Deletes the photo files and kept web pictures of recipes removed for good, except any a remaining recipe (in the
    /// library or Recently Deleted) still shows. Returns the own photo paths whose iCloud copies should go too.
    private func removePhotos(of gone: [RecipeModel]) -> Set<String> {
        let remaining = libraryWithRecentlyDeleted
        let shown = Set(remaining.flatMap { [$0.imageName].compactMap { $0 } + $0.photoNames })
        var removed: Set<String> = []
        for recipe in gone {
            for reference in [recipe.imageName].compactMap({ $0 }) + recipe.photoNames where !shown.contains(reference) {
                imageStore.deleteIfLocal(reference)
            }
            removeKeptPicture(of: recipe)
            removed.formUnion(RecipePhotoSync.removedPaths(before: recipe, after: nil, library: remaining))
        }
        return removed
    }

    #if DEBUG
    /// UI-test hook (`-seed-recently-deleted`): moves the first two library recipes by name to Recently Deleted (one
    /// just now, one 26 days ago) so Screenshots can capture the screen. Skipped when Recently Deleted holds some.
    func seedUITestRecentlyDeletedIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-seed-recently-deleted"),
              persistence.fetchRecentlyDeletedRecipes().isEmpty else { return }
        let sorted = recipes.sorted { $0.name < $1.name }
        for (recipe, daysAgo) in zip(sorted.prefix(2), [0.0, 26.0]) {
            _ = persistence.moveRecipeToRecentlyDeleted(withId: recipe.id, at: Date().addingTimeInterval(-daysAgo * 86_400))
        }
        let moved = Set(sorted.prefix(2).map(\.id))
        recipes.removeAll { moved.contains($0.id) }
    }
    #endif
}
