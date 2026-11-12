import Foundation

private let logger = AppLogger.logger(category: "RecipeImageLocalizer")

/// Keeps a copy of a recipe's web picture on the phone (`RemoteRecipeImage.storedPath`), so imported recipes show
/// their picture offline and after the site changes. The recipe keeps the URL as its source; every failure just
/// leaves the web picture in place.
struct RecipeImageLocalizer: Sendable {
    private let fetcher: any RemoteImageFetching
    private let documentsDirectory: URL?

    init(
        fetcher: any RemoteImageFetching = URLSessionRemoteImageFetcher(),
        documentsDirectory: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    ) {
        self.fetcher = fetcher
        self.documentsDirectory = documentsDirectory
    }

    /// The web picture this recipe still needs a phone copy of, or nil. Built-in samples are left on the web.
    func pictureToKeep(for recipe: RecipeModel) -> String? {
        guard !recipe.isSampleRecipe, let reference = recipe.imageName,
              let file = storedFile(for: reference),
              !FileManager.default.fileExists(atPath: file.path) else { return nil }
        return reference
    }

    /// Downloads, validates and stores the picture; returns its relative path, or nil (logged) on any failure.
    func keep(reference: String) async -> String? {
        guard let url = RemoteRecipeImage.downloadableURL(from: reference),
              let relativePath = RemoteRecipeImage.storedPath(for: reference),
              let file = storedFile(for: reference) else { return nil }
        let fetcher = fetcher
        // Detached so download, decode and file write stay off the main actor whatever the caller's isolation.
        return await Task.detached(priority: .utility) { () -> String? in
            do {
                let data = try await fetcher.fetchImageData(from: url, maxBytes: RemoteRecipeImage.maxBytes)
                let jpeg = try RemoteRecipeImage.normalisedJPEG(from: data)
                try FileManager.default.createDirectory(
                    at: file.deletingLastPathComponent(), withIntermediateDirectories: true
                )
                try jpeg.write(to: file, options: .atomic)
                return relativePath
            } catch {
                logger.error("Couldn't keep a recipe picture: \(error.localizedDescription)")
                return nil
            }
        }.value
    }

    /// Removes the phone copy of a web picture (when its last recipe is deleted).
    func removeCopy(of reference: String) {
        guard let file = storedFile(for: reference) else { return }
        do {
            if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
        } catch {
            logger.error("Couldn't remove a kept recipe picture: \(error.localizedDescription)")
        }
    }

    private func storedFile(for reference: String) -> URL? {
        guard let relativePath = RemoteRecipeImage.storedPath(for: reference) else { return nil }
        return documentsDirectory?.appendingPathComponent(relativePath)
    }
}
