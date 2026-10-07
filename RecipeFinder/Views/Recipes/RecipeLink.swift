import SwiftUI

/// Single entry point for row→detail navigation so `RecipeDetailView` is built once; edits propagate via shared `RecipeStore`.
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
        .accessibilityIdentifier("recipe.row")
    }
}
