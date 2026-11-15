import SwiftUI

/// Single entry point for row→detail navigation so `RecipeDetailView` is built once; edits propagate via shared `RecipeStore`.
struct RecipeLink<Label: View>: View {
    let recipe: RecipeModel
    /// UI-test hook; discovery tiles use their own so "the first library row" stays unambiguous.
    var identifier = "recipe.row"
    @ViewBuilder let label: () -> Label

    var body: some View {
        NavigationLink {
            RecipeDetailView(recipe: recipe)
        } label: {
            label()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
