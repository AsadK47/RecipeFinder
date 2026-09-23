import SwiftUI
import Kingfisher

struct RecipeImageView: View {
    let imageName: String?
    let height: CGFloat
    var recipeName: String? = nil

    @State private var loadFailed = false

    private enum Layout {
        static let defaultHeight: CGFloat = 200
    }

    init(imageName: String?, height: CGFloat = Layout.defaultHeight, recipeName: String? = nil) {
        self.imageName = imageName
        self.height = height
        self.recipeName = recipeName
    }

    private var kfSource: Source? { Self.resolvedSource(for: imageName) }

    /// Resolves an `imageName` to a Kingfisher source, or `nil` when it can't be
    /// displayed (empty, or a local file that no longer exists). Shared so callers
    /// can ask `hasDisplayableImage` before reserving space for an image.
    static func resolvedSource(for imageName: String?) -> Source? {
        guard let imageName = imageName, !imageName.isEmpty else { return nil }
        if imageName.hasPrefix("http"), let url = URL(string: imageName) {
            return .network(url)
        }
        // Legacy format: absolute path saved before relative-path migration.
        // The container path changes on reinstall / Simulator rebuilds, so fall
        // back to looking up the file by name in the expected directory.
        if imageName.hasPrefix("/") {
            if FileManager.default.fileExists(atPath: imageName) {
                return .provider(LocalFileImageDataProvider(fileURL: URL(fileURLWithPath: imageName)))
            }
            let filename = URL(fileURLWithPath: imageName).lastPathComponent
            if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let resolved = docs.appendingPathComponent("RecipeImages").appendingPathComponent(filename)
                if FileManager.default.fileExists(atPath: resolved.path) {
                    return .provider(LocalFileImageDataProvider(fileURL: resolved))
                }
            }
            return nil
        }
        // Current format: path relative to the documents directory. Only usable
        // if the file is actually there (stale references resolve to nil).
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let resolved = docs.appendingPathComponent(imageName)
            return FileManager.default.fileExists(atPath: resolved.path)
                ? .provider(LocalFileImageDataProvider(fileURL: resolved))
                : nil
        }
        return nil
    }

    /// Whether `imageName` will actually render an image — a network URL, an
    /// existing local file, or a bundled asset. Lets screens show a title-only
    /// layout instead of reserving space for a blank/placeholder box.
    static func hasDisplayableImage(_ imageName: String?) -> Bool {
        if resolvedSource(for: imageName) != nil { return true }
        if let name = imageName, !name.isEmpty, UIImage(named: name) != nil { return true }
        return false
    }

    /// Downsample to the display size in pixels so a full-resolution photo isn't
    /// decoded at native size into a small thumbnail.
    private var targetPixelSize: CGSize {
        let side = height * UIScreen.main.scale
        return CGSize(width: side, height: side)
    }

    @ViewBuilder
    private var imageContent: some View {
        if let source = kfSource, !loadFailed {
            KFImage(source: source)
                .placeholder { RecipePlaceholderView(recipeName: recipeName, showShimmer: true) }
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
            RecipePlaceholderView(recipeName: recipeName)
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
