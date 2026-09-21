import UIKit

private let logger = AppLogger.logger(category: "RecipeImageStore")

/// Persists user-picked recipe photos to disk and resolves which image
/// reference a saved recipe should point at.
///
/// Extracted from `RecipeWizardView` so the file I/O can be exercised against a
/// temporary directory in tests. The documents directory and `FileManager` are
/// injectable for exactly that reason; production uses the app's real documents
/// directory by default.
struct RecipeImageStore {
    private let fileManager: FileManager
    private let documentsDirectory: URL?

    init(
        fileManager: FileManager = .default,
        documentsDirectory: URL? = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    ) {
        self.fileManager = fileManager
        self.documentsDirectory = documentsDirectory
    }

    /// Decides the image reference for a recipe being saved: a freshly picked
    /// image is persisted; otherwise an existing reference is kept; otherwise a
    /// stale local file is cleaned up and `nil` is returned.
    func resolveReference(
        recipeId: UUID,
        selectedImage: UIImage?,
        existingReference: String?,
        previousReference: String?
    ) -> String? {
        if let selectedImage {
            return persist(selectedImage, recipeId: recipeId) ?? previousReference
        }

        if existingReference?.isEmpty == false {
            return existingReference
        }

        if let previousReference, isLocalReference(previousReference),
           let path = absolutePath(for: previousReference) {
            try? fileManager.removeItem(atPath: path)
        }

        return nil
    }

    /// Writes `image` as JPEG under `RecipeImages/<id>.jpg`, returning a relative
    /// path (`RecipeImages/<id>.jpg`) so stored references survive app container
    /// changes (simulator rebuilds, OS updates, reinstalls).
    func persist(_ image: UIImage, recipeId: UUID) -> String? {
        guard let imageData = image.jpegData(compressionQuality: AppTheme.jpegCompressionQuality) else {
            return nil
        }
        guard let documentsDirectory else { return nil }

        let relativePath = "RecipeImages/\(recipeId.uuidString).jpg"
        let imageURL = documentsDirectory.appendingPathComponent(relativePath)

        do {
            try fileManager.createDirectory(
                at: imageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try imageData.write(to: imageURL, options: .atomic)
            return relativePath
        } catch {
            logger.error("❌ Failed to persist recipe image for \(recipeId): \(error)")
            return nil
        }
    }

    /// Persists additional (non-hero) gallery images, naming them `<id>_g<n>.jpg`.
    /// Returns relative paths for the same container-stability reason as `persist`.
    /// `startingIndex` lets callers offset the index when combining with already-
    /// saved references so existing gallery files are never overwritten.
    func persistGallery(_ images: [UIImage], recipeId: UUID, startingIndex: Int = 0) -> [String] {
        var paths: [String] = []
        for (idx, img) in images.enumerated() {
            guard let imageData = img.jpegData(compressionQuality: AppTheme.jpegCompressionQuality),
                  let documentsDirectory else { continue }
            let relativePath = "RecipeImages/\(recipeId.uuidString)_g\(startingIndex + idx).jpg"
            let imageURL = documentsDirectory.appendingPathComponent(relativePath)
            do {
                try fileManager.createDirectory(
                    at: imageURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try imageData.write(to: imageURL, options: .atomic)
                paths.append(relativePath)
            } catch {
                logger.error("❌ Failed to persist gallery image \(idx) for \(recipeId): \(error)")
                continue
            }
        }
        return paths
    }

    /// Whether `reference` points at an on-disk file we own (not a remote URL).
    /// Accepts both legacy absolute paths and the current relative-path format.
    func isLocalReference(_ reference: String) -> Bool {
        guard !reference.isEmpty, !reference.hasPrefix("http") else { return false }
        guard let path = absolutePath(for: reference) else { return false }
        return fileManager.fileExists(atPath: path)
    }

    /// Resolves a stored reference (absolute legacy or relative new) to an
    /// absolute filesystem path. Returns `nil` if the reference is a URL.
    func absolutePath(for reference: String) -> String? {
        guard !reference.isEmpty, !reference.hasPrefix("http") else { return nil }
        if reference.hasPrefix("/") { return reference }
        return documentsDirectory?.appendingPathComponent(reference).path
    }
}
