import SwiftUI

// Trailing detail toolbar: minimal — Favorite toggle + overflow menu; Cook / Shop / Made it live in the
// action row under the title (RecipeDetailView.primaryActionsRow).
struct RecipeDetailToolbar: View {
    let recipe: RecipeModel
    let onEdit: () -> Void
    let onToggleFavorite: () -> Void
    let onAddToCollection: () -> Void
    let onManagePhotos: () -> Void
    let onPrint: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.spacing16) {
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
