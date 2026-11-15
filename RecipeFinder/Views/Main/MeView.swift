import SwiftUI

/// Me tab: My Cookbook, profile, badges and chef type, with Settings behind the gear.
struct MeView: View {
    @Environment(\.recipeStore) private var recipeStore

    var body: some View {
        NavigationStack {
            ProfileView(title: "Me", showsSettingsLink: true)
                // A cookbook page opens its recipe, to cook it again.
                .navigationDestination(for: UUID.self) { id in
                    if let recipe = recipeStore.recipes.first(where: { $0.id == id }) {
                        RecipeDetailView(recipe: recipe)
                    }
                }
        }
    }
}

#Preview {
    MeView()
}
