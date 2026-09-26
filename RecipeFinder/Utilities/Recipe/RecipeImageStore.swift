import UIKit

private let logger = AppLogger.logger(category: "RecipeImageStore")

/// Persists recipe photos to disk and resolves a saved recipe's image reference; FileManager/dir injectable for tests.
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

    /// Picks the save-time image ref: persist a new image, else keep existing ref, else clean up stale local file and return nil.
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

    /// Writes JPEG under `RecipeImages/<id>.jpg`; returns a relative path so refs survive container changes (rebuilds, OS updates, reinstalls).
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

    /// Persists non-hero gallery images as `<id>_g<n>.jpg`; `startingIndex` offsets the index so existing gallery files aren't overwritten.
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

    /// Deletes the owned on-disk file (no-op for remote/missing), so removed photos don't leak orphaned files.
    func deleteIfLocal(_ reference: String) {
        guard isLocalReference(reference), let path = absolutePath(for: reference) else { return }
        try? fileManager.removeItem(atPath: path)
    }

    /// Whether `reference` is an owned on-disk file (not a URL); accepts legacy absolute and current relative formats.
    func isLocalReference(_ reference: String) -> Bool {
        guard !reference.isEmpty, !reference.hasPrefix("http") else { return false }
        guard let path = absolutePath(for: reference) else { return false }
        return fileManager.fileExists(atPath: path)
    }

    /// Resolves a stored reference (legacy absolute or new relative) to an absolute path; nil if it's a URL.
    func absolutePath(for reference: String) -> String? {
        guard !reference.isEmpty, !reference.hasPrefix("http") else { return nil }
        if reference.hasPrefix("/") { return reference }
        return documentsDirectory?.appendingPathComponent(reference).path
    }
}
