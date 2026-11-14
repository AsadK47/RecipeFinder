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
    /// (`RecipePhotoSync`) after every load (launch, iCloud change) and save. Passes run one at a time.
    func syncPhotosWithICloud() {
        guard persistence.isSyncing else { return }
        let paths = RecipePhotoSync.referencedPaths(in: recipes)
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let previous = photoSync
        let persistence = self.persistence
        photoSync = Task {
            await previous?.value
            guard let outcome = await persistence.mirrorRecipePhotos(referencedPaths: paths, documentsDirectory: documents),
                  outcome != RecipePhotoSync.Outcome() else { return }
            Self.logger.info("iCloud photos: \(outcome.uploaded) sent, \(outcome.downloaded) received")
            // Pictures resolve their file when drawn; re-publishing the library redraws the ones that just arrived.
            if outcome.downloaded > 0 { recipes = recipes }
        }
    }
}
