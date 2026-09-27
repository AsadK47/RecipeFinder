import SwiftUI

/// Compact recipe row (image, name, category · difficulty, tags, favourite heart); one shared row so collection screens don't drift apart.
struct RecipeRow: View {
    let recipe: RecipeModel

    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            RecipeImageView(
                imageName: recipe.imageName,
                height: Constants.Sizes.recipeImageSize,
                recipeName: recipe.name
            )
            .frame(width: Constants.Sizes.recipeImageSize, height: Constants.Sizes.recipeImageSize)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius8))

            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(recipe.name)
                    .font(.subheadline.weight(.semibold))
                    .adaptiveForegroundColor()
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: AppTheme.spacing6) {
                    if !recipe.category.isEmpty {
                        Text(recipe.category)
                    }
                    if !recipe.category.isEmpty && !recipe.difficulty.isEmpty {
                        Text("\u{2022}")
                    }
                    if !recipe.difficulty.isEmpty {
                        Text(recipe.difficulty)
                    }
                }
                .font(.caption)
                .adaptiveSecondaryForeground()

                if !recipe.tags.isEmpty {
                    TagRowView(tags: recipe.tags)
                }
            }

            Spacer(minLength: 0)

            if recipe.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(AppTheme.spacing12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
    }
}
