import SwiftUI
import Kingfisher

struct MealTimeCard: View {
    let mealTime: MealTime
    let recipe: RecipeModel?
    var isRecurring: Bool = false
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: AppTheme.spacing16) {
            MealThumbnail(
                imageName: recipe?.imageName ?? "",
                recipeName: recipe?.name,
                category: recipe?.category,
                cuisine: recipe?.cuisine,
                fallbackIcon: mealTime.icon
            )

            VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                Text(mealTime.rawValue)
                    .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                    .adaptiveForegroundColor()

                HStack(spacing: AppTheme.spacing4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(mealTime.timeRange)
                        .font(.caption)
                }
                .foregroundStyle(AppTheme.adaptiveMediumEmphasis)

                if let recipe = recipe {
                    HStack(spacing: AppTheme.spacing6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text(recipe.name)
                            .font(.caption)
                            .lineLimit(1)
                        if isRecurring {
                            Image(systemName: "repeat")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.orange)
                        }
                    }
                    .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                } else {
                    HStack(spacing: AppTheme.spacing6) {
                        Image(systemName: "fork.knife")
                            .font(.caption2)
                        Text("Tap to add recipe")
                            .font(.caption)
                    }
                    .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                }
            }

            Spacer()

            HStack(spacing: AppTheme.spacing8) {
                if let onRemove, recipe != nil {
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                            .foregroundStyle(AppTheme.error.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                if recipe == nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                        .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
                }
            }
        }
        .padding(AppTheme.spacing16)
        .appCard()
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                .stroke(recipe != nil ? AppTheme.success.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

/// 52×52 recipe photo thumbnail (Kingfisher for URLs/local paths, UIImage for named assets) falling back to a meal-time icon circle.
private struct MealThumbnail: View {
    let imageName: String
    /// Non-nil = recipe assigned (drives the coloured placeholder when it has no photo); nil = empty slot keeping the "tap to add" icon.
    let recipeName: String?
    let category: String?
    let cuisine: String?
    let fallbackIcon: String

    private static let size: CGFloat = 52
    @State private var loadFailed = false

    // Shared resolver: handles http/legacy-absolute/relative paths and versions the cache key so a replaced photo never serves stale.
    private var kfSource: Source? {
        RecipeImageView.resolvedSource(for: imageName)
    }

    var body: some View {
        if let source = kfSource, !loadFailed {
            KFImage(source: source)
                .onFailure { _ in loadFailed = true }
                .setProcessor(DownsamplingImageProcessor(size: CGSize(
                    width: Self.size * UIScreen.main.scale,
                    height: Self.size * UIScreen.main.scale
                )))
                .scaleFactor(UIScreen.main.scale)
                .cacheOriginalImage()
                .resizable()
                .scaledToFill()
                .frame(width: Self.size, height: Self.size)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
        } else if !imageName.isEmpty, let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: Self.size, height: Self.size)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
        } else if let recipeName {
            // Recipe assigned but no photo → per-recipe coloured placeholder.
            RecipePlaceholderView(recipeName: recipeName, category: category, cuisine: cuisine)
                .frame(width: Self.size, height: Self.size)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
        } else {
            // Empty slot → meal-time icon as the "tap to add" affordance.
            ZStack {
                Circle()
                    .fill(AppTheme.textColor(opacity: AppTheme.cardDarkOpacity))
                Image(systemName: fallbackIcon)
                    .font(.system(size: AppTheme.fontSize22, weight: .semibold))
                    .foregroundStyle(AppTheme.adaptive(light: Color.black.opacity(0.9), dark: Color.white.opacity(AppTheme.cardLightOpacity)))
            }
            .frame(width: Self.size, height: Self.size)
        }
    }
}
