import SwiftUI

/// Tappable profile avatar (photo or initials) plus chef-type caption on the Profile screen.
struct ProfileAvatar: View {
    let image: UIImage?
    let initials: String
    let chefType: ChefType
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            Button(action: onTap) {
                ZStack(alignment: .bottomTrailing) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: AppTheme.width100, height: AppTheme.width100)
                            .clipShape(Circle())
                    } else {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentColor)
                                .frame(width: AppTheme.width100, height: AppTheme.width100)
                            
                            Text(initials)
                                .font(.system(size: AppTheme.fontSize42, weight: .bold))
                                .adaptiveForegroundColor()
                        }
                    }
                    
                    ZStack {
                        Circle()
                            .fill(AppTheme.adaptive(light: Color.white, dark: Color(white: AppTheme.cardDarkOpacity)))
                            .frame(width: AppTheme.iconSize28, height: AppTheme.iconSize28)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: AppTheme.fontSize12, weight: .semibold))
                            .foregroundStyle(AppTheme.accentColor)
                    }
                }
            }
            
            HStack(spacing: AppTheme.spacing6) {
                Image(systemName: chefType.icon)
                    .font(.caption)
                Text(chefType.rawValue)
                    .font(.subheadline)
            }
            .adaptiveForegroundColor()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.spacing20)
    }
}
