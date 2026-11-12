import Foundation

private let logger = AppLogger.logger(category: "RecipeImageLocalizer")

/// Turns a recipe's web picture (the site's image URL) into a photo stored on the phone, so imported recipes keep
/// their picture offline and when the site changes. Every failure returns nil: the recipe keeps its URL.
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

    /// Whether this recipe's picture is still a web link worth downloading. Built-in samples keep their URLs.
    static func needsLocalizing(_ recipe: RecipeModel) -> Bool {
        !recipe.isSampleRecipe && RemoteRecipeImage.downloadableURL(from: recipe.imageName) != nil
    }

    /// Downloads, validates and stores the picture; returns the new relative path, or nil (logged) on any failure.
    func localize(reference: String, recipeId: UUID) async -> String? {
        guard let url = RemoteRecipeImage.downloadableURL(from: reference) else { return nil }
        let fetcher = fetcher
        let documentsDirectory = documentsDirectory
        // Detached so download, decode and file write stay off the main actor whatever the caller's isolation.
        return await Task.detached(priority: .utility) { () -> String? in
            do {
                let data = try await fetcher.fetchImageData(from: url, maxBytes: RemoteRecipeImage.maxBytes)
                let jpeg = try RemoteRecipeImage.normalisedJPEG(from: data)
                return RecipeImageStore(documentsDirectory: documentsDirectory)
                    .persistDownloaded(jpeg, recipeId: recipeId)
            } catch {
                logger.error("Couldn't keep picture for \(recipeId): \(error.localizedDescription)")
                return nil
            }
        }.value
    }
}
