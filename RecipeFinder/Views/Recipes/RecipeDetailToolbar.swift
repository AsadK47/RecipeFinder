import SwiftUI
import TipKit

/// The trailing toolbar controls on the recipe detail screen. Deliberately minimal:
/// a single expressive Favorite toggle plus an overflow menu for the less-frequent
/// actions (Edit, Share). Contextual actions — the cooking timer and
/// add-all-to-shopping — live in the content next to what they act on, not here.
struct RecipeDetailToolbar: View {
    let recipe: RecipeModel
    let onEdit: () -> Void
    let onToggleFavorite: () -> Void
    let onAddToCollection: () -> Void
    let onStartCooking: () -> Void
    let onPrint: () -> Void

    private let cookingModeTip = CookingModeTip()

    var body: some View {
        HStack(spacing: AppTheme.spacing16) {
            Button(action: onStartCooking) {
                Image(systemName: "frying.pan.fill")
                    .font(.title3)
                    .adaptiveForegroundColor()
            }
            .accessibilityLabel("Start Cooking Mode")
            .popoverTip(cookingModeTip, arrowEdge: .top)

            Button(action: onToggleFavorite) {
                Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(recipe.isFavorite ? .red : .primary)
            }
            .accessibilityLabel(recipe.isFavorite ? "Remove from favourites" : "Add to favourites")

            Button(action: onAddToCollection) {
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(.title3)
                    .adaptiveForegroundColor()
            }
            .accessibilityLabel("Add to Collection")

            Menu {
                Button(action: onEdit) {
                    Label("Edit Recipe", systemImage: "pencil")
                }
                ShareLink(
                    item: RecipeTransferItem(recipe: recipe),
                    preview: SharePreview(recipe.name, image: Image(systemName: "fork.knife"))
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                Button(action: onPrint) {
                    Label("Print", systemImage: "printer")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .adaptiveForegroundColor()
            }
            .accessibilityLabel("More actions")
            .accessibilityHint("Edit, share, or print this recipe")
        }
    }
}
