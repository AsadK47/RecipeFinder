import Foundation

/// Imported recipes arrive with the website's picture URL; this keeps a phone copy of it in the background (after
/// launch and after each save), never blocking the import or the launch. The recipe itself is never rewritten.
extension RecipeStore {
    /// Queues a download for each web picture in `library` that has no phone copy yet. Each URL is tried once per
    /// launch, so a dead link doesn't refetch on every save; downloads run one at a time.
    func keepWebPictures(of library: [RecipeModel]) {
        var references: [String] = []
        for recipe in library {
            guard let reference = imageLocalizer.pictureToKeep(for: recipe),
                  !attemptedPictures.contains(reference) else { continue }
            attemptedPictures.insert(reference)
            references.append(reference)
        }
        guard !references.isEmpty else { return }
        let previous = imageLocalization
        let localizer = imageLocalizer
        imageLocalization = Task {
            await previous?.value
            for reference in references {
                _ = await localizer.keep(reference: reference)
            }
        }
    }

    /// Drops the phone copy of a deleted recipe's web picture unless another recipe still shows it.
    func removeKeptPicture(of deleted: RecipeModel) {
        guard let reference = deleted.imageName, RemoteRecipeImage.storedPath(for: reference) != nil,
              !recipes.contains(where: { $0.id != deleted.id && $0.imageName == reference }) else { return }
        imageLocalizer.removeCopy(of: reference)
    }

    /// With iCloud sync on, copies new photos into the store and writes other devices' photos to disk
    /// (`RecipePhotoSync`) after every load (launch, iCloud change) and save, and removes the iCloud copy of each photo
    /// in `removed` (`RecipePhotoSync.removedPaths`, from an edit or delete on this device). Passes run one at a time.
    /// With sync off, only the removals run (rows deleted in the store, sent to iCloud when sync resumes).
    func syncPhotosWithICloud(removing removed: Set<String> = []) {
        let paths = RecipePhotoSync.referencedPaths(in: recipes)
        guard persistence.isSyncing else {
            removePhotoRowsWhileSyncIsOff(removed, keeping: paths)
            return
        }
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let previous = photoSync
        let persistence = self.persistence
        photoSync = Task {
            await previous?.value
            let outcome = await persistence.mirrorRecipePhotos(
                referencedPaths: paths, removedPaths: removed, documentsDirectory: documents
            )
            guard let outcome, outcome != RecipePhotoSync.Outcome() else { return }
            Self.logger.info(
                "iCloud photos: \(outcome.uploaded) sent, \(outcome.downloaded) received, \(outcome.removed) removed"
            )
            // Pictures resolve their file when drawn; re-publishing the library redraws the ones that just arrived.
            if outcome.downloaded > 0 {
                let library = recipes
                recipes = library
            }
        }
    }

    /// With sync on, deletes the cook's photo files once the library they belonged to was erased on another device
    /// (`ErasedPhotoCleanup`). Queued with the photo passes so an earlier pass can't write a file back after it.
    func clearPhotosErasedElsewhere(storage: LocalStore = .shared) {
        guard persistence.isSyncing,
              let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let previous = photoSync
        let persistence = self.persistence
        photoSync = Task {
            await previous?.value
            let cutoff = Date()
            let store = await persistence.photoUseInSyncedStore()
            let step = ErasedPhotoCleanup.step(
                store: store, storeFile: persistence.storeFileID,
                remembered: storage.string(forKey: ErasedPhotoCleanup.rememberedFileKey)
            )
            switch step {
            case .remember(let storeFile):
                storage.set(storeFile, forKey: ErasedPhotoCleanup.rememberedFileKey)
            case .clear:
                storage.removeObject(forKey: ErasedPhotoCleanup.rememberedFileKey)
                do {
                    let removed = try ErasedPhotoCleanup.removeFiles(
                        in: documents, keeping: store?.referencedPaths ?? [], modifiedBefore: cutoff
                    )
                    Self.logger.info("iCloud photos: library erased on another device, \(removed) photo files removed")
                } catch {
                    Self.logger.error("❌ Couldn't remove photos erased on another device: \(error.localizedDescription)")
                }
            case .nothing:
                break
            }
        }
    }

    private func removePhotoRowsWhileSyncIsOff(_ removed: Set<String>, keeping paths: Set<String>) {
        guard !removed.isEmpty else { return }
        let previous = photoSync
        let persistence = self.persistence
        photoSync = Task {
            await previous?.value
            let count = await persistence.removeRecipePhotoRows(removed, keeping: paths)
            if count > 0 {
                Self.logger.info("iCloud photos: \(count) removed with sync off; sent when sync is back on")
            }
        }
    }
}
