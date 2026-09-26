import SwiftUI

/// The single entry point for navigating from a recipe row to its detail.
///
/// Every list that shows recipes (main search results, collections, smart
/// collections) routes through this wrapper so `RecipeDetailView` is constructed
/// in exactly one place. Detail edits propagate to every list automatically via
/// the shared `RecipeStore`, so no per-screen refresh callback is needed.
struct RecipeLink<Label: View>: View {
    let recipe: RecipeModel
    @ViewBuilder let label: () -> Label

    var body: some View {
        NavigationLink {
            RecipeDetailView(recipe: recipe)
        } label: {
            label()
        }
        .buttonStyle(.plain)
    }
}
