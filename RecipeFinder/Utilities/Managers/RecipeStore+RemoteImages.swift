import Foundation

/// Imported recipes arrive with the website's picture URL; these download it once and point the recipe at the
/// stored copy, in the background, never blocking the import or the launch.
extension RecipeStore {
    /// Queues a download for every recipe still showing a web picture (after launch, and after each save).
    func keepWebPictures(of library: [RecipeModel]) {
        let ids = library.filter(RecipeImageLocalizer.needsLocalizing).map(\.id)
        guard !ids.isEmpty else { return }
        let previous = imageLocalization
        imageLocalization = Task { [weak self] in
            await previous?.value
            for id in ids {
                await self?.keepWebPicture(ofRecipe: id)
            }
        }
    }

    /// Swaps the web URL for the stored copy, but only if the recipe still shows that same URL when the download
    /// finishes — a photo the cook picked meanwhile always wins. On any failure the URL stays.
    func keepWebPicture(ofRecipe id: UUID) async {
        guard let recipe = recipes.first(where: { $0.id == id }),
              RecipeImageLocalizer.needsLocalizing(recipe),
              let url = recipe.imageName else { return }
        guard let path = await imageLocalizer.localize(reference: url, recipeId: id) else { return }
        guard let index = recipes.firstIndex(where: { $0.id == id }), recipes[index].imageName == url else {
            // Picture changed or recipe deleted mid-download: drop our copy unless the recipe now uses that file.
            if recipes.first(where: { $0.id == id })?.imageName != path { imageStore.deleteIfLocal(path) }
            return
        }
        var updated = recipes[index]
        updated.imageName = path
        guard persistence.saveRecipeModel(updated) else {
            imageStore.deleteIfLocal(path)
            return
        }
        recipes[index] = updated
    }
}
