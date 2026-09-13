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

    private var kfSource: Source? {
        guard let imageName = imageName, !imageName.isEmpty else { return nil }
        if imageName.hasPrefix("http"), let url = URL(string: imageName) {
            return .network(url)
        }
        // Imported / captured recipe photos are stored as absolute file paths.
        if imageName.hasPrefix("/") {
            return .provider(LocalFileImageDataProvider(fileURL: URL(fileURLWithPath: imageName)))
        }
        return nil
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
