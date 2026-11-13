import Foundation

/// Illustrations shipped in the app for the built-in recipes (`RecipeSeed/RecipeArt/<recipe id>.jpg`, made once with
/// Image Playground by `tools/RecipeArt`). Never stored on a recipe: it's a display fallback, so the user's own photo
/// always wins, nothing is written to their data and nothing extra syncs.
enum BundledRecipeArt {
    /// `imageName`-style reference that `RecipeImageView` resolves to the bundled file.
    static let referencePrefix = "bundled-art:"
    static let folder = "RecipeArt"

    /// Recipe ids that have a bundled picture, read once from the app bundle.
    static let availableIDs: Set<String> = {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: folder) else { return [] }
        return Set(urls.map { $0.deletingPathExtension().lastPathComponent })
    }()

    static func reference(for id: UUID, available: Set<String> = availableIDs) -> String? {
        available.contains(id.uuidString) ? referencePrefix + id.uuidString : nil
    }

    /// The bundled file a reference points at, or nil for anything else (user photos, URLs, unknown ids).
    static func fileURL(for reference: String?, bundle: Bundle = .main) -> URL? {
        guard let reference, reference.hasPrefix(referencePrefix) else { return nil }
        let id = String(reference.dropFirst(referencePrefix.count))
        return bundle.url(forResource: id, withExtension: "jpg", subdirectory: folder)
    }

    /// The picture to show for a recipe: its own image, else its first photo, else the bundled illustration.
    static func heroName(imageName: String?, photoNames: [String], id: UUID, available: Set<String> = availableIDs) -> String? {
        if let imageName, !imageName.isEmpty { return imageName }
        if let first = photoNames.first { return first }
        return reference(for: id, available: available)
    }
}
