import SwiftUI

struct RecipeImageView: View {
    let imageName: String?
    let height: CGFloat
    
    init(imageName: String?, height: CGFloat = 200) {
        self.imageName = imageName
        self.height = height
    }
    
    private var hasSpecificImage: Bool {
        if let imageName = imageName {
            return UIImage(named: imageName) != nil
        }
        return false
    }
    
    var body: some View {
        ZStack {
            if hasSpecificImage {
                Image(imageName!)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Image("food_icon")
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
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
    }
}
