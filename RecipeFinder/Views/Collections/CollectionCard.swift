import SwiftUI

/// A grid card representing a single collection in `CollectionsInlineView`.
struct CollectionCard: View {
    let collection: RecipeCollection
    let recipeCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            HStack {
                CollectionDot(color: collection.colorName.swiftUIColor)
                Spacer()
            }

            Text(collection.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .adaptiveForegroundColor()

            Text(recipeCount == 1 ? "1 recipe" : "\(recipeCount) recipes")
                .font(.caption)
                .adaptiveSecondaryForeground()
        }
        .padding(AppTheme.spacing12)
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                .strokeBorder(collection.colorName.swiftUIColor.opacity(0.3), lineWidth: 1)
        )
    }
}
