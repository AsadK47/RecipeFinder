import Foundation

/// Recently Deleted (Data safety 4/4): a deleted recipe is hidden everywhere but kept, with its photos, for
/// `RecentlyDeleted.keptFor`; then it (or one the cook deletes from Recently Deleted) goes for good with its photos —
/// files here, and their iCloud copies through the usual photo pass (`RecipePhotoSync.removedPaths`).
extension RecipeStore {
    /// Moves the recipe to Recently Deleted: hidden everywhere, photos and kept web pictures untouched (with sync on,
    /// other devices hide it too when the change arrives).
    @discardableResult
    func delete(id: UUID) -> Bool {
        let deletedAt = Date()
        guard persistence.moveRecipeToRecentlyDeleted(withId: id, at: deletedAt) else { return false }
        if let recipe = recipes.first(where: { $0.id == id }) {
            recentlyDeleted.removeAll { $0.id == id }
            recentlyDeleted.insert(DeletedRecipe(recipe: recipe, deletedAt: deletedAt), at: 0)
        }
        recipes.removeAll { $0.id == id }
        return true
    }

    @discardableResult
    func restore(id: UUID) -> Bool {
        guard let item = recentlyDeleted.first(where: { $0.id == id }),
              persistence.restoreRecentlyDeletedRecipe(withId: id) else { return false }
        recentlyDeleted.removeAll { $0.id == id }
        if !recipes.contains(where: { $0.id == id }) {
            recipes.append(item.recipe)
        }
        return true
    }

    @discardableResult
    func deleteForever(id: UUID) -> Bool {
        guard let item = recentlyDeleted.first(where: { $0.id == id }),
              persistence.deleteRecentlyDeletedRecipe(withId: id) else { return false }
        recentlyDeleted.removeAll { $0.id == id }
        syncPhotosWithICloud(removing: removePhotos(of: [item.recipe]))
        return true
    }

    /// Removes for good every recipe that has been in Recently Deleted longer than `RecentlyDeleted.keptFor`, with its
    /// photos. Returns the photo paths whose iCloud copies should go (passed to the next photo pass).
    func purgeExpired(now: Date = Date()) -> Set<String> {
        let cutoff = RecentlyDeleted.purgeCutoff(now: now)
        let gone = recentlyDeleted
            .filter { RecentlyDeleted.isExpired($0, now: now) }
            .filter { persistence.deleteRecentlyDeletedRecipe(withId: $0.id, deletedBefore: cutoff) }
        guard !gone.isEmpty else { return [] }
        let goneIDs = Set(gone.map(\.id))
        recentlyDeleted.removeAll { goneIDs.contains($0.id) }
        Self.logger.info("Removed \(gone.count) recipes deleted over 30 days ago")
        return removePhotos(of: gone.map(\.recipe))
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
    /// just now, one 26 days ago) so Screenshots can capture the screen. Runs once per library (skipped when it holds
    /// some already).
    func seedUITestRecentlyDeletedIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-seed-recently-deleted"), recentlyDeleted.isEmpty else { return }
        let sorted = recipes.sorted { $0.name < $1.name }
        for (recipe, daysAgo) in zip(sorted.prefix(2), [0.0, 26.0]) {
            _ = persistence.moveRecipeToRecentlyDeleted(withId: recipe.id, at: Date().addingTimeInterval(-daysAgo * 86_400))
        }
        let moved = Set(sorted.prefix(2).map(\.id))
        recipes.removeAll { moved.contains($0.id) }
        recentlyDeleted = persistence.fetchRecentlyDeletedRecipes()
    }
    #endif
}
