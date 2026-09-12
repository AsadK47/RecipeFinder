import SwiftUI

/// The trailing toolbar controls on the recipe detail screen. Deliberately minimal:
/// a single expressive Favorite toggle plus an overflow menu for the less-frequent
/// actions (Edit, Share). Contextual actions — the cooking timer and
/// add-all-to-shopping — live in the content next to what they act on, not here.
struct RecipeDetailToolbar: View {
    let recipe: RecipeModel
    let onEdit: () -> Void
    let onToggleFavorite: () -> Void
    let onAddToCollection: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.spacing16) {
            Button(action: onToggleFavorite) {
                Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundColor(recipe.isFavorite ? .red : .white)
            }
            .accessibilityLabel(recipe.isFavorite ? "Remove from favourites" : "Add to favourites")

            Menu {
                Button(action: onEdit) {
                    Label("Edit Recipe", systemImage: "pencil")
                }
                Button(action: onAddToCollection) {
                    Label("Add to Collection", systemImage: "rectangle.stack.badge.plus")
                }
                ShareLink(item: recipe.shareText, subject: Text(recipe.name)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .adaptiveForegroundColor()
            }
            .accessibilityLabel("More actions")
            .accessibilityHint("Edit, add to collection, or share this recipe")
        }
    }
}
