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

    @ViewBuilder
    private var imageContent: some View {
        if let imageName = imageName, imageName.hasPrefix("http"), let url = URL(string: imageName) {
            KFImage(url)
                .placeholder { placeholder }
                .fade(duration: 0.25)
                .resizable()
                .scaledToFill()
        } else if let imageName = imageName,
                  !imageName.isEmpty,
                  FileManager.default.fileExists(atPath: imageName),
                  let uiImage = UIImage(contentsOfFile: imageName) {
            Image(uiImage: uiImage)
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
            .drawingGroup()
    }
}
