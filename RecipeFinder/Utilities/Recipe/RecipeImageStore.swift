import UIKit

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

        if let previousReference, isLocalReference(previousReference) {
            try? fileManager.removeItem(atPath: previousReference)
        }

        return nil
    }

    /// Writes `image` as JPEG under `RecipeImages/<id>.jpg`, returning its path.
    func persist(_ image: UIImage, recipeId: UUID) -> String? {
        guard let imageData = image.jpegData(compressionQuality: AppTheme.jpegCompressionQuality) else {
            return nil
        }
        guard let documentsDirectory else { return nil }

        let imageDirectory = documentsDirectory.appendingPathComponent("RecipeImages", isDirectory: true)
        let imageURL = imageDirectory.appendingPathComponent("\(recipeId.uuidString).jpg")

        do {
            try fileManager.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
            try imageData.write(to: imageURL, options: .atomic)
            return imageURL.path
        } catch {
            return nil
        }
    }

    /// Whether `reference` points at an on-disk file we own (not a remote URL).
    func isLocalReference(_ reference: String) -> Bool {
        guard !reference.isEmpty, !reference.hasPrefix("http") else { return false }
        return fileManager.fileExists(atPath: reference)
    }
}
