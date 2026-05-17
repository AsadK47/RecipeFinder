import SwiftUI

struct RecipeImageView: View {
    let imageName: String?
    let height: CGFloat

    @State private var cachedImage: UIImage?

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

    var body: some View {
        Group {
            if let cachedImage = cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .clipped()
            } else if let imageName = imageName, imageName.hasPrefix("http"), let url = URL(string: imageName) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: height)
                            .clipped()
                    case .failure:
                        placeholder
                    case .empty:
                        Color.gray.opacity(Layout.placeholderBackgroundOpacity)
                            .frame(height: height)
                            .overlay(ProgressView())
                    @unknown default:
                        placeholder
                    }
                }
            } else if let imageName = imageName, !imageName.isEmpty, let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .clipped()
                    .onAppear {
                        cachedImage = uiImage
                    }
            } else {
                placeholder
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius16))
        .drawingGroup()
    }
}
