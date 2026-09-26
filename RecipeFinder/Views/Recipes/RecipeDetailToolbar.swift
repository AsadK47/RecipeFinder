import SwiftUI
import TipKit

// Trailing detail toolbar: minimal — Favorite toggle + overflow menu; contextual actions live inline in the content.
struct RecipeDetailToolbar: View {
    let recipe: RecipeModel
    let onEdit: () -> Void
    let onToggleFavorite: () -> Void
    let onAddToCollection: () -> Void
    let onStartCooking: () -> Void
    let onManagePhotos: () -> Void
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

            AnimatedHeartButton(isFavorite: .constant(recipe.isFavorite), action: onToggleFavorite)

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
                Button(action: onManagePhotos) {
                    Label("Manage Photos", systemImage: "photo.on.rectangle")
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
