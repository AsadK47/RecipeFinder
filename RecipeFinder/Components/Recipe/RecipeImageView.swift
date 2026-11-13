import SwiftUI
import Kingfisher

struct RecipeImageView: View {
    let imageName: String?
    let height: CGFloat
    var recipeName: String? = nil
    var category: String? = nil
    var cuisine: String? = nil

    @State private var loadFailed = false

    private enum Layout {
        static let defaultHeight: CGFloat = 200
    }

    init(imageName: String?, height: CGFloat = Layout.defaultHeight, recipeName: String? = nil,
         category: String? = nil, cuisine: String? = nil) {
        self.imageName = imageName
        self.height = height
        self.recipeName = recipeName
        self.category = category
        self.cuisine = cuisine
    }

    /// Picture (or illustrated placeholder) for a recipe — passes name, category and cuisine so the art fits the dish.
    init(recipe: RecipeModel, imageName: String?, height: CGFloat = Layout.defaultHeight) {
        self.init(imageName: imageName, height: height, recipeName: recipe.name,
                  category: recipe.category, cuisine: recipe.cuisine)
    }

    private var kfSource: Source? { Self.resolvedSource(for: imageName) }

    /// Resolves `imageName` to a Kingfisher source, or `nil` if undisplayable (empty or missing local file); shared with `hasDisplayableImage`.
    static func resolvedSource(for imageName: String?) -> Source? {
        guard let imageName = imageName, !imageName.isEmpty else { return nil }
        if imageName.hasPrefix(BundledRecipeArt.referencePrefix) {
            return BundledRecipeArt.fileURL(for: imageName).map { .provider(localProvider(for: $0)) }
        }
        if imageName.hasPrefix("http"), let url = URL(string: imageName) {
            // Prefer the phone copy kept by RecipeStore+RemoteImages so the picture shows offline.
            if let stored = RemoteRecipeImage.storedPath(for: imageName),
               let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let file = docs.appendingPathComponent(stored)
                if FileManager.default.fileExists(atPath: file.path) {
                    return .provider(localProvider(for: file))
                }
            }
            return .network(url)
        }
        // Legacy absolute path (pre relative-path migration); container path changes on reinstall, so fall back to looking up by filename.
        if imageName.hasPrefix("/") {
            if FileManager.default.fileExists(atPath: imageName) {
                return .provider(localProvider(for: URL(fileURLWithPath: imageName)))
            }
            let filename = URL(fileURLWithPath: imageName).lastPathComponent
            if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let resolved = docs.appendingPathComponent("RecipeImages").appendingPathComponent(filename)
                if FileManager.default.fileExists(atPath: resolved.path) {
                    return .provider(localProvider(for: resolved))
                }
            }
            return nil
        }
        // Current format: path relative to documents dir; stale references resolve to nil.
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let resolved = docs.appendingPathComponent(imageName)
            return FileManager.default.fileExists(atPath: resolved.path)
                ? .provider(localProvider(for: resolved))
                : nil
        }
        return nil
    }

    /// Provider whose cache key is versioned by mtime + size: photos live at a stable path, so without this Kingfisher would keep serving the old image after a replace.
    private static func localProvider(for fileURL: URL) -> LocalFileImageDataProvider {
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        let key = imageCacheKey(
            base: fileURL.absoluteString,
            modificationDate: attributes?[.modificationDate] as? Date,
            size: (attributes?[.size] as? NSNumber)?.intValue
        )
        return LocalFileImageDataProvider(fileURL: fileURL, cacheKey: key)
    }

    /// Pure cache-key builder: base URL plus a version suffix from mtime (ms) + size, so a rewritten file gets a fresh key; extracted for unit testing.
    static func imageCacheKey(base: String, modificationDate: Date?, size: Int?) -> String {
        let stamp = modificationDate.map { String(Int($0.timeIntervalSince1970 * 1000)) } ?? "0"
        return "\(base)#v=\(stamp)-\(size ?? 0)"
    }

    /// Whether `imageName` will render (network URL, existing local file, or bundled asset), so screens can use a title-only layout instead of a blank box.
    static func hasDisplayableImage(_ imageName: String?) -> Bool {
        if resolvedSource(for: imageName) != nil { return true }
        if let name = imageName, !name.isEmpty, UIImage(named: name) != nil { return true }
        return false
    }

    /// Downsample target in pixels so a full-res photo isn't decoded at native size into a small thumbnail.
    private var targetPixelSize: CGSize {
        let side = height * UIScreen.main.scale
        return CGSize(width: side, height: side)
    }

    @ViewBuilder
    private var imageContent: some View {
        if let source = kfSource, !loadFailed {
            KFImage(source: source)
                .placeholder { RecipePlaceholderView(recipeName: recipeName, category: category, cuisine: cuisine, showShimmer: true) }
                .onFailure { _ in loadFailed = true }
                .setProcessor(DownsamplingImageProcessor(size: targetPixelSize))
                .scaleFactor(UIScreen.main.scale)
                .cacheOriginalImage()
                .fade(duration: 0.25)
                .resizable()
                .scaledToFill()
        } else if let imageName = imageName, !imageName.isEmpty, let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            RecipePlaceholderView(recipeName: recipeName, category: category, cuisine: cuisine)
        }
    }

    var body: some View {
        Color.clear
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay { imageContent }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius16))
    }
}
