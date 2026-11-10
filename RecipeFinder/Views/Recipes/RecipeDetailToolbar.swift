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
    /// Shown only for recipes that kept their original import text.
    var onReimport: (() -> Void)? = nil
    let onDelete: () -> Void

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
                if let onReimport {
                    Button(action: onReimport) {
                        Label("Re-import from original", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .accessibilityIdentifier("recipe.reimport")
                }
                Divider()
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Recipe", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .adaptiveForegroundColor()
            }
            .accessibilityLabel("More actions")
            .accessibilityHint("Edit, share, print, or delete this recipe")
        }
    }
}
