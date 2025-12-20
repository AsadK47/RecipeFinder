import SwiftUI

struct RecipeImageView: View {
    let imageName: String?
    let height: CGFloat
    
    // Cache the image check result to avoid repeated lookups
    @State private var cachedImage: UIImage?
    private let cornerRadius: CGFloat = 16
    
    init(imageName: String?, height: CGFloat = 200) {
        self.imageName = imageName
        self.height = height
    }
    
    var body: some View {
        Group {
            if let cachedImage = cachedImage {
                Image(uiImage: cachedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .clipped()
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
                // Default placeholder with SF Symbol
                ZStack {
                    Color.gray.opacity(0.2)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                .frame(height: height)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .drawingGroup() // Performance optimization for complex image rendering
    }
}
