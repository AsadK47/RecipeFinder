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
            } else if let imageName = imageName, let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .clipped()
                    .onAppear {
                        cachedImage = uiImage
                    }
            } else {
                // Default placeholder image
                Image("food_icon")
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .clipped()
                    .overlay(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                            )
                    )
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .drawingGroup() // Performance optimization for complex image rendering
    }
}
