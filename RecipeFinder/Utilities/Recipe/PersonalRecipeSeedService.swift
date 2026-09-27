import Foundation

private let logger = AppLogger.logger(category: "PersonalRecipeSeed")

/// Bulk-imports the bundled personal collection (recipes_seed.json) into Core Data, skipping names already in the current scope.
struct PersonalRecipeSeedService {

    private let persistence: PersistenceController

    @MainActor
    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    struct SeedResult {
        let imported: Int
        let skipped: Int
        let failed: Int

        var summary: String {
            if imported == 0 && skipped > 0 && failed == 0 {
                return "All \(skipped) recipes are already in your library."
            }
            var parts: [String] = []
            if imported > 0 { parts.append("\(imported) recipe\(imported == 1 ? "" : "s") imported") }
            if skipped  > 0 { parts.append("\(skipped) already existed") }
            if failed   > 0 { parts.append("\(failed) couldn't be parsed") }
            return parts.isEmpty ? "Nothing to import." : parts.joined(separator: ", ") + "."
        }

        var isError: Bool { imported == 0 && failed > 0 }
    }

    // MARK: - Public API

    /// Parses and saves every bundled recipe, skipping existing names; yields first so a pending spinner renders.
    @MainActor
    func seed() async -> SeedResult {
        await Task.yield()

        guard let entries = loadSeedEntries() else {
            logger.error("❌ recipes_seed.json not found in bundle")
            return SeedResult(imported: 0, skipped: 0, failed: 1)
        }

        let existingNames = Set(
            persistence.fetchRecipes()
                .map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() }
        )

        var imported = 0
        var skipped  = 0
        var failed   = 0

        // Suppress badge celebrations during bulk import; still persisted, and one silent pass at the end catches new milestones without a parade of sheets.
        BadgeManager.shared.isBulkImporting = true
        defer { BadgeManager.shared.isBulkImporting = false }

        for entry in entries {
            let normalised = entry.name.trimmingCharacters(in: .whitespaces).lowercased()
            guard !existingNames.contains(normalised) else {
                skipped += 1
                continue
            }

            guard let prefill = TextRecipeParser.parse(entry.rawText) else {
                failed += 1
                logger.debug("Could not parse '\(entry.name)'")
                continue
            }

            let recipe = makeModel(from: prefill, fallbackName: entry.name)
            if persistence.saveRecipeModel(recipe) {
                imported += 1
            } else {
                failed += 1
                logger.error("❌ Failed to save '\(entry.name)'")
            }
        }

        if imported > 0 {
            let finalCount = persistence.fetchRecipeCount()
            BadgeManager.shared.checkAndUnlockBadges(recipeCount: finalCount, silent: true)
        }

        logger.info("Seed complete: \(imported) imported, \(skipped) skipped, \(failed) failed")
        return SeedResult(imported: imported, skipped: skipped, failed: failed)
    }

    // MARK: - Private

    private struct SeedEntry: Decodable {
        let name: String
        let rawText: String
    }

    private func loadSeedEntries() -> [SeedEntry]? {
        guard let url = Bundle.main.url(forResource: "recipes_seed", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([SeedEntry].self, from: data)
    }

    private func makeModel(
        from prefill: RecipeWizardView.PrefilledRecipeData,
        fallbackName: String
    ) -> RecipeModel {
        let name = prefill.name
            .flatMap { $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 }
            ?? fallbackName

        let ingredients = (prefill.ingredients ?? [])
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { line -> Ingredient in
                let p = IngredientLineParser.parse(line)
                return Ingredient(baseQuantity: p.quantity, unit: p.unit, name: p.name)
            }

        return RecipeModel(
            name: name,
            category: prefill.category ?? "Main",
            difficulty: prefill.difficulty ?? "Medium",
            prepTime: prefill.prepTime.map { "\($0) minutes" } ?? "10 minutes",
            cookingTime: prefill.cookTime.map { "\($0) minutes" } ?? "30 minutes",
            baseServings: prefill.servings ?? 4,
            ingredients: ingredients.isEmpty
                ? [Ingredient(baseQuantity: 1, unit: "", name: "See recipe")]
                : ingredients,
            prePrepInstructions: prefill.prePrepInstructions ?? [],
            instructions: prefill.instructions ?? [],
            notes: prefill.notes ?? "",
            cuisine: prefill.cuisine
        )
    }
}
