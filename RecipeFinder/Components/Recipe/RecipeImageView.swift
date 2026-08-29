import SwiftUI
import Kingfisher

struct RecipeImageView: View {
    let imageName: String?
    let height: CGFloat

    private enum Layout {
        static let defaultHeight: CGFloat = 200
        static let placeholderBackgroundOpacity: Double = 0.2
        static let placeholderIconOpacity: Double = 0.5
    }

    init(imageName: String?, height: CGFloat = Layout.defaultHeight) {
        self.imageName = imageName
        self.height = height
    }

    private var placeholder: some View {
        ZStack {
            Color.gray.opacity(Layout.placeholderBackgroundOpacity)
            Image(systemName: "photo")
                .font(.system(size: AppTheme.fontSize42))
                .foregroundColor(.gray.opacity(Layout.placeholderIconOpacity))
        }
        .frame(height: height)
    }

    /// Kingfisher source for remote URLs and locally-saved photos. Both are loaded
    /// and decoded off the main thread and cached, so evaluating a card's `body`
    /// never blocks on disk I/O or image decoding. Asset-catalog names (e.g. the
    /// bundled sample images) fall through to `UIImage(named:)`, which UIKit caches.
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
        if let source = kfSource {
            KFImage(source: source)
                .placeholder { placeholder }
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
            placeholder
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
