import Testing
import Foundation
import CryptoKit
@testable import RecipeFinder

/// Build-time generator + drift gate for the bundled recipe collection. The raw pasted corpus
/// (`RecipeSeed/recipes_source.json`, test-only) is parsed here, off-device, into structured
/// `RecipeSeed/recipes_seed.json`, which the app only decodes on first launch (`BundledRecipeCatalog`).
/// If the committed output is stale (source or parser changed), the drift test rewrites it and fails —
/// review the diff, rebuild, re-run.
@Suite("BundledRecipeCatalog")
struct BundledRecipeCatalogTests {

    struct SourceEntry: Decodable {
        let name: String
        let rawText: String
    }

    // MARK: - Generator

    /// Parses raw entries into sample recipes with name-derived stable ids. Drops unparseable entries and
    /// duplicate names (the corpus has a few, and some overlap the hard-coded starters). `images` maps a source URL
    /// to its page's hero image (`recipes_source_images.json`, from tools/seed-images) — hotlinked, never bundled.
    static func generate(from entries: [SourceEntry], images: [String: String] = [:]) -> [RecipeModel] {
        var seen = Set(SeedRecipeProvider.recipes.map { normalised($0.name) })
        var recipes: [RecipeModel] = []
        for entry in entries {
            guard let prefill = TextRecipeParser.parse(entry.rawText) else { continue }
            let model = makeModel(from: prefill, entry: entry, images: images)
            guard seen.insert(normalised(model.name)).inserted else { continue }
            recipes.append(model)
        }
        return recipes
    }

    /// Sorted, pretty output so regenerations are deterministic and the committed diff is reviewable.
    static func encode(_ recipes: [RecipeModel]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(recipes)
    }

    private static func makeModel(from prefill: RecipeWizardView.PrefilledRecipeData, entry: SourceEntry, images: [String: String]) -> RecipeModel {
        let name = prefill.name
            .flatMap { $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 }
            ?? entry.name
        let key = normalised(name)
        let source = sourceURL(in: entry.rawText)

        let ingredients = (prefill.ingredients ?? [])
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .enumerated()
            .map { index, line -> Ingredient in
                let parsed = IngredientLineParser.parse(line)
                return Ingredient(id: stableUUID("\(key)#\(index)"), baseQuantity: parsed.quantity, unit: parsed.unit, name: parsed.name)
            }

        return RecipeModel(
            id: stableUUID(key),
            name: name,
            category: prefill.category ?? "Main",
            difficulty: prefill.difficulty ?? "Medium",
            prepTime: prefill.prepTime.map { "\($0) minutes" } ?? "10 minutes",
            cookingTime: prefill.cookTime.map { "\($0) minutes" } ?? "30 minutes",
            baseServings: prefill.servings ?? 4,
            ingredients: ingredients.isEmpty
                ? [Ingredient(id: stableUUID("\(key)#0"), baseQuantity: 1, unit: "", name: "See recipe")]
                : ingredients,
            prePrepInstructions: prefill.prePrepInstructions ?? [],
            instructions: prefill.instructions ?? [],
            notes: notes(prefill.notes ?? "", sourceURL: source),
            imageName: source.flatMap { images[$0] },
            isSampleRecipe: true,
            cuisine: prefill.cuisine
        )
    }

    /// Moves the source URL to the last notes line so `RecipeModel.importedFromURL` picks it up (credit + photo).
    static func notes(_ notes: String, sourceURL: String?) -> String {
        guard let sourceURL else { return notes }
        let body = notes.components(separatedBy: "\n")
            .filter { !$0.contains(sourceURL) }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return body.isEmpty ? sourceURL : body + "\n\n" + sourceURL
    }

    static func sourceURL(in rawText: String) -> String? {
        guard let range = rawText.range(of: #"https?://[^\s]+"#, options: .regularExpression) else { return nil }
        return String(rawText[range])
    }

    /// Deterministic UUID (SHA-256 of the key, RFC 4122 v5-style bits) so re-seeding and regeneration are idempotent.
    static func stableUUID(_ key: String) -> UUID {
        var bytes = Array(SHA256.hash(data: Data("bundled-recipe:\(key)".utf8)).prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }

    private static func normalised(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Resolve the seed directory from the source tree (walk up from this file).
    private static func seedDirectory() -> URL? {
        var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0..<8 {
            let candidate = dir.appendingPathComponent("RecipeFinder/RecipeSeed")
            if FileManager.default.fileExists(atPath: candidate.appendingPathComponent("recipes_source.json").path) {
                return candidate
            }
            dir = dir.deletingLastPathComponent()
        }
        return nil
    }

    private static func loadSource() throws -> [SourceEntry] {
        let dir = try #require(seedDirectory(), "RecipeSeed/recipes_source.json not found from \(#filePath)")
        return try JSONDecoder().decode([SourceEntry].self, from: Data(contentsOf: dir.appendingPathComponent("recipes_source.json")))
    }

    /// Optional: a missing map just means no photos.
    private static func loadImages() throws -> [String: String] {
        let dir = try #require(seedDirectory())
        guard let data = try? Data(contentsOf: dir.appendingPathComponent("recipes_source_images.json")) else { return [:] }
        return try JSONDecoder().decode([String: String].self, from: data)
    }

    // MARK: - Drift gate

    @Test("committed recipes_seed.json matches the generator (rewrites it when stale)")
    func committedCatalogMatchesGenerator() throws {
        let dir = try #require(Self.seedDirectory())
        let fresh = try Self.encode(Self.generate(from: Self.loadSource(), images: Self.loadImages()))
        let outputURL = dir.appendingPathComponent("recipes_seed.json")
        guard (try? Data(contentsOf: outputURL)) != fresh else { return }
        try fresh.write(to: outputURL)
        Issue.record("recipes_seed.json was stale and has been regenerated — review the diff, rebuild, and re-run.")
    }

    @Test("generation is deterministic")
    func generationIsDeterministic() throws {
        let source = try Self.loadSource()
        let images = try Self.loadImages()
        #expect(try Self.encode(Self.generate(from: source, images: images)) == Self.encode(Self.generate(from: source, images: images)))
    }

    // MARK: - Generator behaviour

    @Test("source URL becomes the importedFromURL line and is hidden from displayed notes")
    func sourceURLMovesToLastNotesLine() {
        let notes = Self.notes("Lovely curry.\nhttps://example.com/curry", sourceURL: "https://example.com/curry")
        let recipe = RecipeModel(name: "Curry", category: "Main", difficulty: "Easy", prepTime: "5 minutes",
                                 cookingTime: "10 minutes", baseServings: 2, ingredients: [],
                                 prePrepInstructions: [], instructions: [], notes: notes)
        #expect(recipe.importedFromURL?.absoluteString == "https://example.com/curry")
        #expect(Self.sourceURL(in: "Curry\nhttps://example.com/curry\nIngredients") == "https://example.com/curry")
        #expect(Self.notes("", sourceURL: nil).isEmpty)
    }

    @Test("duplicate names and starter names are dropped")
    func duplicatesAreDropped() {
        let raw = "Ingredients\n200g rice\n1 onion\nMethod\nCook the rice."
        let entries = [
            SourceEntry(name: "Rice", rawText: "Rice\n" + raw),
            SourceEntry(name: "rice", rawText: "rice\n" + raw),
            SourceEntry(name: "Greek Salad", rawText: "Greek Salad\n" + raw),
        ]
        let names = Self.generate(from: entries).map { $0.name.lowercased() }
        #expect(names.filter { $0 == "rice" }.count <= 1)
        #expect(!names.contains("greek salad"))
    }

    @Test("source image is hotlinked as an https imageName; recipes without one stay image-less")
    func sourceImageBecomesImageName() {
        let raw = "Ingredients\n200g rice\n1 onion\nMethod\nCook the rice."
        let entries = [
            SourceEntry(name: "Rice", rawText: "Rice\nhttps://example.com/rice\n" + raw),
            SourceEntry(name: "Noodles", rawText: "Noodles\n" + raw),
        ]
        let recipes = Self.generate(from: entries, images: ["https://example.com/rice": "https://example.com/rice.jpg"])
        #expect(recipes.first { $0.name == "Rice" }?.imageName == "https://example.com/rice.jpg")
        #expect(recipes.first { $0.name == "Noodles" }?.imageName == nil)
    }

    // MARK: - Bundled output (what the app ships)

    @Test("bundled catalog decodes from the app bundle with unique, sample-flagged recipes")
    func bundledCatalogLoads() {
        let recipes = BundledRecipeCatalog.load()
        let ids = Set(recipes.map(\.id))
        #expect(recipes.count > 300)
        #expect(ids.count == recipes.count)
        #expect(ids.isDisjoint(with: SeedRecipeProvider.recipes.map(\.id)))
        #expect(recipes.allSatisfy { $0.isSampleRecipe })
        #expect(recipes.allSatisfy { !$0.name.isEmpty && !$0.ingredients.isEmpty })
        // Photos are hotlinked from the source site, never bundled files.
        #expect(recipes.compactMap(\.imageName).allSatisfy { $0.hasPrefix("https://") || $0.hasPrefix("http://") })
        #expect(recipes.compactMap(\.imageName).allSatisfy { URL(string: $0) != nil })
    }

    @Test("seeding starters + bundled catalog persists every recipe without counting toward badges")
    @MainActor
    func seedingPersistsAll() async {
        let persistence = PersistenceController(inMemory: true, userID: { nil })
        let all = SeedRecipeProvider.recipes + BundledRecipeCatalog.load()
        #expect(await persistence.seedRecipes(all))
        #expect(persistence.fetchRecipeCount() == all.count)
        #expect(persistence.fetchCollectedRecipeCount() == 0)
    }
}
