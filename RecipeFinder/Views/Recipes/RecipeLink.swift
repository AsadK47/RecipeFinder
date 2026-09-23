import SwiftUI

/// The single entry point for navigating from a recipe row to its detail.
///
/// Every list that shows recipes (main search results, collections, smart
/// collections) routes through this wrapper so `RecipeDetailView(recipe:
/// onRecipeChange:)` is constructed in exactly one place. Cross-cutting detail
/// behaviour — e.g. the post-cook refresh that keeps the parent list in sync —
/// is then wired once instead of copy-pasted per screen (which is how it
/// previously drifted and skipped the collection screens).
struct RecipeLink<Label: View>: View {
    let recipe: RecipeModel
    var onRecipeChange: (() -> Void)?
    @ViewBuilder let label: () -> Label

    var body: some View {
        NavigationLink {
            RecipeDetailView(recipe: recipe, onRecipeChange: onRecipeChange)
        } label: {
            label()
        }
        .buttonStyle(.plain)
    }
}
