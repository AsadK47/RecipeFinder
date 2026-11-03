import Foundation

private let logger = AppLogger.logger(category: "BundledRecipes")

/// The bundled recipe collection (`RecipeSeed/recipes_seed.json`), pre-parsed off-device from the raw
/// `recipes_source.json` by `BundledRecipeCatalogTests` — first launch only decodes, never runs the text parser.
enum BundledRecipeCatalog {

    /// Decodes the bundled collection; empty (logged) if the resource is missing or corrupt so seeding never blocks launch.
    static func load(bundle: Bundle = .main) -> [RecipeModel] {
        guard let url = bundle.url(forResource: "recipes_seed", withExtension: "json") else {
            logger.error("❌ recipes_seed.json not found in bundle")
            return []
        }
        do {
            return try JSONDecoder().decode([RecipeModel].self, from: Data(contentsOf: url))
        } catch {
            logger.error("❌ Failed to decode bundled recipes: \(error.localizedDescription)")
            return []
        }
    }
}
