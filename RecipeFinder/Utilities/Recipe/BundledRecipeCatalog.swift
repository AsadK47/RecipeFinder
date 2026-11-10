import Foundation

private let logger = AppLogger.logger(category: "BundledRecipes")

/// The bundled recipe collection (`RecipeSeed/recipes_seed.json`), pre-parsed off-device from the raw
/// `recipes_source.json` by `BundledRecipeCatalogTests` — first launch only decodes, never runs the text parser.
enum BundledRecipeCatalog {

    /// Decodes the bundled collection; empty (logged) if the resource is missing or corrupt so seeding never blocks launch.
    static func load(bundle: Bundle = .main) -> [RecipeModel] {
        decode(resource: "recipes_seed", bundle: bundle)
    }

    /// Every earlier shipped version of a bundled recipe that differs from today's (`recipes_seed_history.json`,
    /// generated from git history). Lets the refresh tell an untouched old copy from one the user edited.
    static func loadHistory(bundle: Bundle = .main) -> [RecipeModel] {
        decode(resource: "recipes_seed_history", bundle: bundle)
    }

    private static func decode(resource: String, bundle: Bundle) -> [RecipeModel] {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            logger.error("❌ \(resource).json not found in bundle")
            return []
        }
        do {
            return try JSONDecoder().decode([RecipeModel].self, from: Data(contentsOf: url))
        } catch {
            logger.error("❌ Failed to decode \(resource).json: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Stale-sample refresh

    /// Bump when `recipes_seed.json` gains fixes that existing installs should pick up (and regenerate the history).
    static let sampleRefreshVersion = 4

    /// The refresh can only judge "untouched" against real data: an empty bundle or history (missing/corrupt JSON)
    /// must not mark the version done, or it would never retry.
    static func canCompleteSampleRefresh(current: [RecipeModel], history: [RecipeModel]) -> Bool {
        !current.isEmpty && !history.isEmpty
    }

    static func needsSampleRefresh(lastRunVersion: Int, currentVersion: Int = sampleRefreshVersion) -> Bool {
        lastRunVersion < currentVersion
    }

    /// Every change the versioned sample pass makes: stale untouched copies rebuilt from today's bundle, then any
    /// sample still showing a hotlinked third-party photo cleared (those leaked the user's IP to recipe sites).
    static func sampleUpdates(library: [RecipeModel], current: [RecipeModel], history: [RecipeModel]) -> [RecipeModel] {
        var updates = Dictionary(
            staleSampleRefreshes(library: library, current: current, history: history).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let merged = library.map { updates[$0.id] ?? $0 }
        for cleared in remoteImageRemovals(library: merged) { updates[cleared.id] = cleared }
        return library.compactMap { updates[$0.id] }
    }

    /// Samples whose hero is a remote URL, with it removed so the placeholder shows. A photo the user chose is a
    /// local file and is kept; the user's own recipes are never touched.
    static func remoteImageRemovals(library: [RecipeModel]) -> [RecipeModel] {
        library.compactMap { recipe in
            guard recipe.isSampleRecipe, let image = recipe.imageName,
                  image.hasPrefix("https://") || image.hasPrefix("http://") else { return nil }
            var cleared = recipe
            cleared.imageName = nil
            return cleared
        }
    }

    /// The library's sample recipes that are an untouched earlier shipped version, rebuilt from the current
    /// bundled content with the user's own state (favourite, rating, cooks, photos, tags, chosen hero) kept.
    /// A copy matching no shipped version was edited by the user and is left alone — a miss is always safe.
    static func staleSampleRefreshes(
        library: [RecipeModel], current: [RecipeModel], history: [RecipeModel]
    ) -> [RecipeModel] {
        let currentByID = Dictionary(current.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let historyByID = Dictionary(grouping: history, by: \.id)
        return library.compactMap { stored in
            guard stored.isSampleRecipe,
                  let fresh = currentByID[stored.id],
                  let shipped = historyByID[stored.id],
                  ContentKey(stored) != ContentKey(fresh),
                  shipped.contains(where: { ContentKey($0) == ContentKey(stored) }) else { return nil }
            let bundledImages = Set(shipped.compactMap(\.imageName))
            var refreshed = fresh
            refreshed.isSampleRecipe = true
            refreshed.isFavorite = stored.isFavorite
            refreshed.rating = stored.rating
            refreshed.cookCount = stored.cookCount
            refreshed.lastCookedAt = stored.lastCookedAt
            refreshed.photoNames = stored.photoNames
            refreshed.tags = stored.tags
            if let image = stored.imageName, !image.isEmpty, !bundledImages.contains(image) { refreshed.imageName = image }
            if stored.baseServings == fresh.baseServings { refreshed.currentServings = stored.currentServings }
            return refreshed
        }
    }

    /// Whether two copies have the same user-editable text (ingredient ids and hero image ignored).
    static func hasSameContent(_ a: RecipeModel, _ b: RecipeModel) -> Bool {
        ContentKey(a) == ContentKey(b)
    }

    /// The recipe text a user can edit. Ingredient ids are ignored (an edit may re-mint them) and the hero image
    /// is handled separately, so swapping the photo alone doesn't count as an edit.
    private struct ContentKey: Equatable {
        struct Line: Equatable { let name: String; let quantity: Double; let unit: String }
        let name, category, difficulty, prepTime, cookingTime, notes: String
        let baseServings: Int
        let ingredients: [Line]
        let prePrep, instructions: [String]
        let cuisine: String?
        let dietaryInfo: DietaryInfo

        init(_ r: RecipeModel) {
            name = r.name; category = r.category; difficulty = r.difficulty
            prepTime = r.prepTime; cookingTime = r.cookingTime; notes = r.notes
            baseServings = r.baseServings
            ingredients = r.ingredients.map { Line(name: $0.name, quantity: $0.baseQuantity, unit: $0.unit) }
            prePrep = r.prePrepInstructions; instructions = r.instructions
            cuisine = r.cuisine; dietaryInfo = r.dietaryInfo
        }
    }
}
