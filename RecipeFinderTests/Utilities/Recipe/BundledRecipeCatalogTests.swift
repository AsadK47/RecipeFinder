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
    /// duplicate names (the corpus has a few, and some overlap the hard-coded starters). Bundled recipes carry no
    /// photo: hotlinking source-site images leaked the user's IP and showed others' copyrighted photos.
    static func generate(from entries: [SourceEntry], curated: [String: CuratedEntry] = [:]) -> [RecipeModel] {
        var seen = Set(SeedRecipeProvider.recipes.map { normalised($0.name) })
        var recipes: [RecipeModel] = []
        for entry in entries {
            guard let prefill = TextRecipeParser.parse(entry.rawText) else { continue }
            var model = makeModel(from: prefill, entry: entry)
            // A human-reviewed version (recipes_curated.json, keyed by the stable id) replaces the raw parse.
            if let review = curated[model.id.uuidString] {
                guard review.action != "drop" else { continue }
                if let fixed = review.recipe { model = apply(fixed, to: model, sourceURL: sourceURL(in: entry.rawText)) }
            }
            guard seen.insert(normalised(model.name)).inserted else { continue }
            // So the Vegetarian / Vegan filters find bundled recipes (other flags are never guessed).
            model.dietaryInfo = DietaryInference.infer(model)
            recipes.append(model)
        }
        return recipes
    }

    // MARK: - Curated reviews

    /// One reviewed recipe from `recipes_curated.json` (see tools/recipe-review/BRIEF.md for how they're produced).
    struct CuratedEntry: Decodable {
        let action: String          // keep | fix | drop
        let recipe: CuratedRecipe?
        /// The method (pre-prep, steps, notes) is written in our own words, not the source's (BACKLOG
        /// "Recipes in our own words"); `ownWordsMethodsCopyNoSourceRun` holds it to that.
        var ownWords: Bool? = nil
    }

    struct CuratedRecipe: Decodable {
        struct Item: Decodable { let quantity: Double; let unit: String; let name: String }
        let name: String
        let category: String
        let difficulty: String
        let prepMinutes: Int
        let cookMinutes: Int
        let servings: Int
        let ingredients: [Item]
        let prePrep: [String]
        let steps: [String]
        let notes: String
    }

    /// Builds the shipped recipe from its curated version, keeping the parsed model's stable id, photo and source link.
    static func apply(_ curated: CuratedRecipe, to parsed: RecipeModel, sourceURL: String?) -> RecipeModel {
        let idKey = parsed.id.uuidString
        return RecipeModel(
            id: parsed.id,
            name: curated.name,
            category: curated.category,
            difficulty: curated.difficulty,
            prepTime: "\(curated.prepMinutes) minutes",
            cookingTime: "\(curated.cookMinutes) minutes",
            baseServings: max(1, curated.servings),
            ingredients: curated.ingredients.enumerated().map { index, item in
                Ingredient(id: stableUUID("\(idKey)#curated#\(index)"), baseQuantity: item.quantity, unit: item.unit, name: item.name)
            },
            prePrepInstructions: curated.prePrep,
            instructions: curated.steps,
            notes: notes(curated.notes, sourceURL: sourceURL),
            imageName: parsed.imageName,
            isSampleRecipe: true
        )
    }

    /// Sorted, pretty output so regenerations are deterministic and the committed diff is reviewable.
    static func encode(_ recipes: [RecipeModel]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(recipes)
    }

    private static func makeModel(from prefill: RecipeWizardView.PrefilledRecipeData, entry: SourceEntry) -> RecipeModel {
        let rawName = prefill.name
            .flatMap { $0.trimmingCharacters(in: .whitespaces).isEmpty ? nil : $0 }
            ?? entry.name
        let name = cleanTitle(rawName)
        let key = normalised(name)
        let source = sourceURL(in: entry.rawText)

        let ingredients = cleanIngredientLines(prefill.ingredients ?? [])
            .enumerated()
            .map { index, line -> Ingredient in
                let parsed = IngredientLineParser.parse(line)
                return Ingredient(id: stableUUID("\(key)#\(index)"), baseQuantity: parsed.quantity, unit: parsed.unit, name: parsed.name)
            }

        return RecipeModel(
            id: stableUUID(key),
            name: name,
            category: prefill.category ?? "Main",
            difficulty: RecipeWizardBuilder.normalizeDifficulty(prefill.difficulty ?? ""),
            prepTime: prefill.prepTime.map { "\($0) minutes" } ?? "10 minutes",
            cookingTime: prefill.cookTime.map { "\($0) minutes" } ?? "30 minutes",
            baseServings: prefill.servings ?? 4,
            ingredients: ingredients.isEmpty
                ? [Ingredient(id: stableUUID("\(key)#0"), baseQuantity: 1, unit: "", name: "See recipe")]
                : ingredients,
            prePrepInstructions: prefill.prePrepInstructions ?? [],
            instructions: cleanSteps(prefill.instructions ?? []),
            notes: notes(prefill.notes ?? "", sourceURL: source),
            imageName: nil,
            isSampleRecipe: true,
            cuisine: prefill.cuisine
        )
    }

    /// Strips paste junk from titles: URLs/domains, recipe-card labels ("PREP TIME"), serving numbers, a trailing
    /// "Video", and a description glued onto the name. A title that was only a URL becomes its slug.
    static func cleanTitle(_ raw: String) -> String {
        var title = raw
        let slug = sourceURL(in: raw).flatMap { URL(string: $0)?.pathComponents.last(where: { $0 != "/" }) }
        let patterns = [
            #"https?://\S+"#,                                        // full URLs
            #"\S+\.(com|co\.uk|net|org)\S*"#,                       // bare domains
            #"\b(PREP|COOK|ADDITIONAL|TOTAL) TIME\b"#,               // recipe-card labels
            #"\s+Serves\s+[\d.\s]+$"#,                              // "Serves 2.0 0.71…"
            #"\s+[\d.]+\s+bites?\s+serving$"#,                      // "18.0 bites serving"
            #"\s+Video$"#,
            #"[\u0E00-\u0E7F]+"#,                                    // garbled Thai combining glyphs from the paste
        ]
        for pattern in patterns {
            title = title.replacingOccurrences(of: pattern, with: " ", options: [.regularExpression, .caseInsensitive])
        }
        // A description glued on ("Apam Balik A delicious Malaysian…"): cut at the sentence start.
        if title.count > 60, let cut = title.range(of: #"\s(A|An|This)\s[a-z]"#, options: .regularExpression),
           title.distance(from: title.startIndex, to: cut.lowerBound) >= 10 {
            title = String(title[..<cut.lowerBound])
        }
        title = title.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "-–|")))
        if title.isEmpty, let slug {
            title = slug.replacingOccurrences(of: "-", with: " ").capitalized
        }
        return title.isEmpty ? raw : title
    }

    /// Drops pasted section headers ("Optional:", "For Serving:") and the equipment/notes list that some recipe cards
    /// append after the ingredients — they showed up as tickable, add-to-cart ingredients.
    static func cleanIngredientLines(_ lines: [String]) -> [String] {
        var kept: [String] = []
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            if line.range(of: #"^(equipment|notes?)\b"#, options: [.regularExpression, .caseInsensitive]) != nil { break }
            if line.hasSuffix(":") { continue }
            kept.append(line)
        }
        return kept
    }

    /// Cuts the recipe card's trailing Notes / Video / Nutrition blocks, which the paste turned into cooking steps.
    static func cleanSteps(_ steps: [String]) -> [String] {
        let tail = #"^(notes?|video|nutrition|calories)\b"#
        guard let cut = steps.firstIndex(where: {
            $0.trimmingCharacters(in: .whitespaces).range(of: tail, options: [.regularExpression, .caseInsensitive]) != nil
        }) else { return steps }
        // Keep at least one step — a recipe whose first "step" is a note still needs something to cook from.
        return cut == 0 ? steps : Array(steps[..<cut])
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
    private static func loadCurated() throws -> [String: CuratedEntry] {
        let dir = try #require(seedDirectory())
        let data = try Data(contentsOf: dir.appendingPathComponent("recipes_curated.json"))
        return try JSONDecoder().decode([String: CuratedEntry].self, from: data)
    }

    // MARK: - Drift gate

    @Test("committed recipes_seed.json matches the generator (rewrites it when stale)")
    func committedCatalogMatchesGenerator() throws {
        let dir = try #require(Self.seedDirectory())
        let fresh = try Self.encode(Self.generate(from: Self.loadSource(), curated: Self.loadCurated()))
        let outputURL = dir.appendingPathComponent("recipes_seed.json")
        guard (try? Data(contentsOf: outputURL)) != fresh else { return }
        try fresh.write(to: outputURL)
        Issue.record("recipes_seed.json was stale and has been regenerated — review the diff, rebuild, and re-run.")
    }

    @Test("generation is deterministic")
    func generationIsDeterministic() throws {
        let source = try Self.loadSource()
        let curated = try Self.loadCurated()
        #expect(try Self.encode(Self.generate(from: source, curated: curated))
                == Self.encode(Self.generate(from: source, curated: curated)))
    }

    @Test("every bundled recipe has a human review — new source recipes can't ship unreviewed")
    func everyRecipeIsCurated() throws {
        let curated = try Self.loadCurated()
        let unreviewed = Self.generate(from: try Self.loadSource())
            .filter { curated[$0.id.uuidString] == nil }
            .map(\.name)
        #expect(unreviewed.isEmpty, "Review these (tools/recipe-review/BRIEF.md) and add them to recipes_curated.json: \(unreviewed)")
    }

    // MARK: - Own words

    /// Lower-cased runs of `length` consecutive words, URLs ignored (the source link is credit, not method text).
    /// Seven words is a copied clause; at six the hits are stock kitchen phrases and ingredient lists ("oven to
    /// 180C 160C fan gas"), facts nobody owns. A pass is a floor, not proof: a reviewer still reads each batch.
    static func wordRuns(_ text: String, length: Int = 7) -> Set<String> {
        let words = text.replacingOccurrences(of: #"https?://\S+"#, with: " ", options: .regularExpression)
            .lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
        guard words.count >= length else { return [] }
        return Set((0...(words.count - length)).map { words[$0..<($0 + length)].joined(separator: " ") })
    }

    @Test("a 7-word run matches across case and punctuation; a reworded sentence shares none")
    func wordRunsFindCopiedClauses() {
        let source = Self.wordRuns("Heat the oil in a large pan over a medium heat. https://example.com/a/b/c/d/e/f")
        #expect(!Self.wordRuns("HEAT the oil, in a large pan;").isDisjoint(with: source))
        #expect(Self.wordRuns("Warm the oil in a big pan on a medium heat.").isDisjoint(with: source))
        #expect(Self.wordRuns("example com a b c d e").isDisjoint(with: source))
        #expect(Self.wordRuns("Too short to count.").isEmpty)
    }

    @Test("a method rewritten in our own words shares no 7-word run with any of its source texts")
    func ownWordsMethodsCopyNoSourceRun() throws {
        let curated = try Self.loadCurated()
        // A duplicated name has several source texts (often different sites); the method must copy none of them.
        var sourceRuns: [String: Set<String>] = [:]
        for entry in try Self.loadSource() {
            guard let prefill = TextRecipeParser.parse(entry.rawText) else { continue }
            let id = Self.makeModel(from: prefill, entry: entry).id.uuidString
            guard curated[id]?.ownWords == true else { continue }
            sourceRuns[id, default: []].formUnion(Self.wordRuns(entry.rawText))
        }
        for (id, source) in sourceRuns {
            let recipe = try #require(curated[id]?.recipe)
            let copied = (recipe.prePrep + recipe.steps + [recipe.notes])
                .flatMap { Self.wordRuns($0).intersection(source) }
            #expect(copied.isEmpty, "\(recipe.name) still repeats its source: \(copied.sorted().prefix(3))")
        }
        // Batches 1–2 (25 each) + the two renamed in 513679a; raise this with each batch so a lost flag can't shrink it.
        #expect(sourceRuns.count >= 52, "only \(sourceRuns.count) recipes are marked ownWords")
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

    @Test("generated recipes never carry a photo, even when the source page had one")
    func generatedRecipesHaveNoImage() {
        let raw = "Ingredients\n200g rice\n1 onion\nMethod\nCook the rice."
        let recipes = Self.generate(from: [SourceEntry(name: "Rice", rawText: "Rice\nhttps://example.com/rice\n" + raw)])
        #expect(recipes.first?.imageName == nil)
        #expect(recipes.first?.importedFromURL?.absoluteString == "https://example.com/rice")
    }

    @Test("generated recipes are tagged vegetarian / vegan from their ingredients")
    func generatedRecipesAreDietTagged() {
        let veg = Self.generate(from: [SourceEntry(name: "Dal", rawText: "Dal\nIngredients\n200g lentils\n1 onion\nMethod\nCook.")])
        let meat = Self.generate(from: [SourceEntry(name: "Stew", rawText: "Stew\nIngredients\n500g beef\n1 onion\nMethod\nCook.")])
        #expect(veg.first?.dietaryInfo.isVegan == true)
        #expect(meat.first?.dietaryInfo.isVegetarian == false)
    }

    @Test("the shipped collection answers the Vegetarian and Vegan filters; no meat or fish dish is vegetarian")
    func shippedCollectionIsDietTagged() {
        let recipes = BundledRecipeCatalog.load()
        #expect(recipes.contains { $0.dietaryInfo.isVegetarian })
        #expect(recipes.contains { $0.dietaryInfo.isVegan })
        for meat in ["chicken", "beef", "pork", "lamb", "fish", "prawn", "shrimp", "anchovy", "gelatin"] {
            #expect(!recipes.contains { $0.dietaryInfo.isVegetarian && $0.ingredients.contains { $0.name.localizedCaseInsensitiveContains(meat) } }, "\(meat)")
        }
        // Whole words, written out here rather than read from DietaryInference, so a word dropped from its lists
        // can't pass ("grana" sits inside "pomegranate", "liver" inside "slivered").
        let meatWords = ["lardons", "guanciale", "speck", "nduja", "liver", "livers", "trout", "monkfish", "clam", "clams",
                         "herring", "marshmallow", "marshmallows", "parmigiano", "grana"]
        let dairyWords = ["ricotta", "feta", "halloumi", "brie", "gruyère", "gruyere", "crème", "creme", "labneh", "kefir"]
        for recipe in recipes {
            let words = Set(recipe.ingredients.flatMap { DietaryInference.words(in: $0.name) })
            if recipe.dietaryInfo.isVegetarian {
                #expect(words.isDisjoint(with: meatWords), "\(recipe.name) is tagged Vegetarian")
            }
            if recipe.dietaryInfo.isVegan {
                #expect(words.isDisjoint(with: dairyWords), "\(recipe.name) is tagged Vegan")
            }
        }
        let untaggedVegan = recipes.filter { $0.name.localizedCaseInsensitiveContains("vegan") && !$0.dietaryInfo.isVegan }
        #expect(untaggedVegan.isEmpty, "Titled Vegan but not tagged: \(untaggedVegan.map(\.name))")
        #expect(!recipes.contains { $0.dietaryInfo.isGlutenFree || $0.dietaryInfo.isNutFree || $0.dietaryInfo.isDairyFree })
    }

    @Test("no bundled title claims a diet its tags never carry (gluten-free, dairy-free, lactose-free, nut-free, keto, low-carb)")
    func titlesClaimNoUntaggedDiet() {
        // Bundled recipes are tagged Vegetarian / Vegan only, so a title promising any other diet is a claim the
        // recipe's own tags contradict — an allergen promise nobody checked.
        let claims = ["gluten-free", "gluten free", "dairy-free", "dairy free", "lactose-free", "lactose free", "nut-free", "nut free",
                      "keto", "low-carb", "low carb"]
        let claiming = BundledRecipeCatalog.load().filter { recipe in
            claims.contains { recipe.name.localizedCaseInsensitiveContains($0) }
        }
        #expect(claiming.isEmpty, "Titles claim an untagged diet: \(claiming.map(\.name))")
    }

    @Test("a note offering a vegan or vegetarian swap names every ingredient it has to swap",
          arguments: [("vegan", true), ("vegetarian", false)])
    func swapNotesNameEveryIngredientToSwap(diet: String, vegan: Bool) throws {
        // "Use vegetarian oyster sauce to make it vegan" on a recipe with egg noodles sends a vegan cook wrong
        // (reviewer 2026-11-25). Each line the diet rules out must be named by one of its words in the note.
        let offer = try Regex("(?i)\\b(make (it|this)( \\w+)? \(diet)|\(diet) version|keep it \(diet)|for a \(diet))")
        var swapWords = DietaryInference.meatWords.union(DietaryInference.stockWords)
        if vegan { swapWords.formUnion(DietaryInference.animalProductWords) }
        let unnamed = BundledRecipeCatalog.load().compactMap { recipe -> String? in
            // The source URL's slug ("…/vegetable-lo-mein") isn't advice the cook reads.
            let note = recipe.notes.components(separatedBy: "http").first ?? ""
            guard note.contains(offer) else { return nil }
            let noteWords = Set(DietaryInference.words(in: note))
            let missed = recipe.ingredients.map(\.name).filter { name in
                let words = DietaryInference.words(in: name)
                let ruledOut = DietaryInference.containsMeat(words)
                    || (vegan && DietaryInference.containsAnimalProduct(words))
                return ruledOut && !words.contains { swapWords.contains($0) && noteWords.contains($0) }
            }
            return missed.isEmpty ? nil : "\(recipe.name): \(missed)"
        }
        #expect(unnamed.isEmpty, "\(diet) swap notes miss ingredients: \(unnamed)")
    }

    @Test("no bundled title names a person or brand with a possessive (Mary Berry's, Pret's)")
    func titlesNameNoPersonOrBrand() throws {
        // A person's or shop's name in a title implies their endorsement (owner 2026-11-26). Family words are fine.
        // Brand names without a possessive (appliances, products) are audited by hand — see BACKLOG Inbox.
        let possessive = try Regex(#"\b([A-Z][a-z]+)['’]s\b"#)
        let allowed: Set<String> = ["Shepherd", "Mum", "Mom", "Grandma", "Nan", "Granny", "Nana"]
        let named = BundledRecipeCatalog.load().filter { recipe in
            recipe.name.matches(of: possessive).contains { match in
                !allowed.contains(String(recipe.name[match.range].dropLast(2)))
            }
        }
        #expect(named.isEmpty, "Titles name a person or brand: \(named.map(\.name))")
    }

    @Test("Junk pasted into titles is cleaned", arguments: [
        ("Chapati PREP TIME COOK TIME ADDITIONAL TIME TOTAL TIME", "Chapati"),
        ("Seafood paella recipe Serves 2.0 0.7111111111 0.5555555556", "Seafood paella recipe"),
        ("Chocolate cornflake clusters 18.0 bites serving", "Chocolate cornflake clusters"),
        ("Red Velvet Cupcakes https://www.nigella.com/recipes/red-velvet-cupcakes", "Red Velvet Cupcakes"),
        ("https://www.japanesecooking101.com/matcha-pound-cake-recipe/", "Matcha Pound Cake Recipe"),
        ("Easy & Simple Apam Balik A delicious Malaysian street food pancake filled with sweet creamed corn", "Easy & Simple Apam Balik"),
        ("Tarka Dhal", "Tarka Dhal"),
    ])
    func cleansTitles(raw: String, expected: String) {
        #expect(Self.cleanTitle(raw) == expected)
    }

    @Test("Section headers are dropped and the trailing equipment list is cut from ingredients")
    func cleansIngredientLines() {
        let lines = ["Tandoori Marinade:", "500 g chicken", "1 tbsp oil", "For Serving:", "1 lemon",
                     "Equipment", "Baking Rack", "Instant Pot"]
        #expect(Self.cleanIngredientLines(lines) == ["500 g chicken", "1 tbsp oil", "1 lemon"])
    }

    @Test("Trailing Notes / Video / Nutrition blocks are cut from the steps")
    func cleansSteps() {
        let steps = ["Marinate the chicken.", "Grill for 10 minutes.", "Notes Note 1: use thighs",
                     "Nutrition Serving: 1 serving | Calories: 439kcal"]
        #expect(Self.cleanSteps(steps) == ["Marinate the chicken.", "Grill for 10 minutes."])
        #expect(Self.cleanSteps(["Notes: only a note"]) == ["Notes: only a note"])
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
        // No third-party photos: nothing is fetched from recipe sites while browsing.
        #expect(recipes.allSatisfy { $0.imageName == nil })
    }

    @Test("seeding starters + bundled catalog persists every recipe without counting toward badges")
    @MainActor
    func seedingPersistsAll() async {
        let persistence = PersistenceController(inMemory: true)
        let all = SeedRecipeProvider.recipes + BundledRecipeCatalog.load()
        #expect(await persistence.seedRecipes(all))
        #expect(persistence.fetchRecipeCount() == all.count)
        #expect(persistence.fetchCollectedRecipeCount() == 0)
    }

    // MARK: - Stale-sample refresh (devices seeded before curation keep old copies)

    private static let sampleID = UUID()

    private static func sample(
        name: String = "Chicken Chow Mein",
        ingredients: [String] = ["noodles", "chicken"],
        instructions: [String] = ["Fry.", "Serve."],
        imageName: String? = "https://example.com/old.jpg",
        isSampleRecipe: Bool = true
    ) -> RecipeModel {
        RecipeModel(
            id: sampleID, name: name, category: "Main", difficulty: "Basic", prepTime: "10 minutes",
            cookingTime: "10 minutes", baseServings: 2,
            ingredients: ingredients.map { Ingredient(baseQuantity: 1, unit: "", name: $0) },
            prePrepInstructions: [], instructions: instructions, notes: "", imageName: imageName,
            isSampleRecipe: isSampleRecipe
        )
    }

    private static let oldVersion = sample(ingredients: ["Fry the noodles", "Serve hot"], instructions: [])
    private static let currentVersion = sample(imageName: "https://example.com/new.jpg")

    private static func refreshed(_ stored: RecipeModel) -> [RecipeModel] {
        BundledRecipeCatalog.staleSampleRefreshes(
            library: [stored], current: [currentVersion], history: [oldVersion]
        )
    }

    @Test("an unedited pre-curation copy is replaced with the current bundled content")
    func unedited_isRefreshed() {
        let result = Self.refreshed(Self.oldVersion)
        #expect(result.count == 1)
        #expect(result.first?.ingredients.map(\.name) == Self.currentVersion.ingredients.map(\.name))
        #expect(result.first?.instructions == Self.currentVersion.instructions)
        #expect(result.first?.imageName == Self.currentVersion.imageName)
        #expect(result.first?.isSampleRecipe == true)
    }

    @Test("an untouched copy from before diet tagging picks up its Vegetarian / Vegan tags")
    func untagged_isRefreshedWithTags() {
        let untagged = Self.sample(name: "Dal", ingredients: ["lentils", "onion"])
        var tagged = untagged
        tagged.dietaryInfo = DietaryInfo(isVegetarian: true, isVegan: true)
        let result = BundledRecipeCatalog.staleSampleRefreshes(library: [untagged], current: [tagged], history: [untagged])
        #expect(result.first?.dietaryInfo.isVegan == true)
    }

    @Test("refresh keeps favourite, rating, cook history, photos and tags")
    func refresh_preservesUserState() {
        var stored = Self.oldVersion
        let cookedAt = Date(timeIntervalSince1970: 1_000_000)
        stored.isFavorite = true
        stored.rating = 4
        stored.cookCount = 3
        stored.lastCookedAt = cookedAt
        stored.photoNames = ["dish.jpg"]
        stored.tags = ["weeknight"]
        let result = Self.refreshed(stored).first
        #expect(result?.isFavorite == true)
        #expect(result?.rating == 4)
        #expect(result?.cookCount == 3)
        #expect(result?.lastCookedAt == cookedAt)
        #expect(result?.photoNames == ["dish.jpg"])
        #expect(result?.tags == ["weeknight"])
    }

    @Test("a hero photo the user chose survives the refresh")
    func refresh_keepsUserHeroPhoto() {
        var stored = Self.oldVersion
        stored.imageName = "local-hero.jpg"
        #expect(Self.refreshed(stored).first?.imageName == "local-hero.jpg")
    }

    @Test("a copy the user edited is left alone")
    func edited_isUntouched() {
        let edited = Self.sample(ingredients: ["Fry the noodles", "Serve hot", "My extra chilli"], instructions: [])
        #expect(Self.refreshed(edited).isEmpty)
    }

    @Test("a copy already matching the current bundle needs no write")
    func current_isUntouched() {
        #expect(Self.refreshed(Self.currentVersion).isEmpty)
    }

    @Test("a user recipe that shares the id but isn't a sample is left alone")
    func nonSample_isUntouched() {
        let mine = Self.sample(ingredients: ["Fry the noodles", "Serve hot"], instructions: [], isSampleRecipe: false)
        #expect(Self.refreshed(mine).isEmpty)
    }

    @Test("refresh runs once per version, and again when the version is bumped", arguments: [
        (0, 1, true), (1, 1, false), (1, 2, true), (2, 1, false),
    ])
    func refresh_runsOncePerVersion(lastRun: Int, current: Int, expected: Bool) {
        #expect(BundledRecipeCatalog.needsSampleRefresh(lastRunVersion: lastRun, currentVersion: current) == expected)
    }

    @Test("shipped history decodes and only holds versions of recipes still in the bundle")
    func bundledHistoryLoads() {
        let history = BundledRecipeCatalog.loadHistory()
        let currentIDs = Set(BundledRecipeCatalog.load().map(\.id))
        #expect(history.count > 100)
        #expect(history.allSatisfy { currentIDs.contains($0.id) })
    }

    /// The history file only changes when shipped recipes do, and those fixes reach installs only through a
    /// `sampleRefreshVersion` bump. Regenerated the history? Bump the version, then update both pins here.
    @Test("the shipped history file never changes without a sampleRefreshVersion bump")
    func historyChangeBumpsRefreshVersion() throws {
        let url = try #require(Bundle.main.url(forResource: "recipes_seed_history", withExtension: "json"))
        let digest = SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined()
        #expect(BundledRecipeCatalog.sampleRefreshVersion == 13)
        #expect(digest == "ff5f9cf3030a67456b18dca93c9ca63a7b99081610a2f4cfd4ed9b066ea5780a",
                "recipes_seed_history.json changed: bump sampleRefreshVersion and update both pins")
    }

    @Test("an untouched copy titled with an untagged diet claim refreshes to today's title",
          arguments: ["Apple Jalebi (Gluten-Free, Vegan)", "Dairy-Free Tangzhong Bread", "Lactose-Free Meat Lasagne"])
    func claimTitledCopyRefreshes(oldName: String) throws {
        let history = BundledRecipeCatalog.loadHistory()
        let current = BundledRecipeCatalog.load()
        var old = try #require(history.first { $0.name == oldName }, "history should hold \(oldName)")
        old.isSampleRecipe = true
        let result = BundledRecipeCatalog.staleSampleRefreshes(library: [old], current: current, history: history)
        let refreshed = try #require(result.first)
        #expect(refreshed.id == old.id)
        #expect(refreshed.name != oldName)
        #expect(!refreshed.name.localizedCaseInsensitiveContains("free"))
    }

    @Test("an untouched copy titled with a person's or brand's name refreshes to today's title and method",
          arguments: ["Mary Berry's Fish Pie", "Pret's Dark Chocolate and Almond Butter Vegan Cookies"])
    func namedTitleCopyRefreshes(oldName: String) throws {
        let history = BundledRecipeCatalog.loadHistory()
        let current = BundledRecipeCatalog.load()
        var old = try #require(history.first { $0.name == oldName }, "history should hold \(oldName)")
        old.isSampleRecipe = true
        let result = BundledRecipeCatalog.staleSampleRefreshes(library: [old], current: current, history: history)
        let refreshed = try #require(result.first)
        let today = try #require(current.first { $0.id == old.id })
        #expect(refreshed.id == old.id)
        #expect(refreshed.name == today.name)
        #expect(!refreshed.name.contains("'s"))
        #expect(refreshed.instructions == today.instructions)
        #expect(refreshed.instructions != old.instructions)
    }

    /// The two renamed in 513679a, then one from batch 2 (Chicken Chow Mein) so a history built from the wrong lineage fails.
    @Test("an untouched copy of a recipe rewritten in our own words refreshes to the new method",
          arguments: ["A7171E82-38B8-5C8D-91F6-8F004D896647", "3F5C06D9-1262-54CD-A359-6D37A3FD3BCE",
                      "6A2A2B42-B113-5303-A512-E1C97CD1E9A1"])
    func ownWordsCopyRefreshes(id: String) throws {
        let history = BundledRecipeCatalog.loadHistory()
        let current = BundledRecipeCatalog.load()
        let today = try #require(current.first { $0.id.uuidString == id })
        // The newest shipped version is the one most installs hold: history is written oldest first.
        var old = try #require(history.last { $0.id == today.id }, "history should hold \(today.name)'s copied method")
        old.isSampleRecipe = true
        let refreshed = try #require(BundledRecipeCatalog.staleSampleRefreshes(library: [old], current: current, history: history).first)
        #expect(refreshed.id == today.id)
        #expect(refreshed.instructions == today.instructions)
        #expect(refreshed.instructions != old.instructions)
    }

    @Test("an old copy seeded through the store still matches its shipped version after the round trip")
    @MainActor
    func roundTrippedOldCopy_isRecognisedAsUnedited() async {
        let persistence = PersistenceController(inMemory: true)
        let history = BundledRecipeCatalog.loadHistory()
        let current = BundledRecipeCatalog.load()
        guard let old = history.first(where: { $0.name == "鷄肉炒麵" }) else {
            Issue.record("history should hold the pre-curation 鷄肉炒麵")
            return
        }
        var seeded = old
        seeded.isSampleRecipe = true
        #expect(await persistence.seedRecipes([seeded]))
        let stored = await persistence.fetchRecipesAsync()
        let result = BundledRecipeCatalog.staleSampleRefreshes(library: stored, current: current, history: history)
        let fresh = current.first { $0.id == old.id }
        #expect(result.count == 1)
        #expect(result.first?.instructions == fresh?.instructions)
    }

    @Test func sampleRefresh_onlyCompletesWithBothBundleAndHistory() {
        let r = RecipeModel(name: "Dal", category: "Main", difficulty: "Easy", prepTime: "", cookingTime: "",
                            baseServings: 2, ingredients: [], prePrepInstructions: [], instructions: [], notes: "")
        #expect(BundledRecipeCatalog.canCompleteSampleRefresh(current: [r], history: [r]))
        #expect(!BundledRecipeCatalog.canCompleteSampleRefresh(current: [], history: [r]))
        #expect(!BundledRecipeCatalog.canCompleteSampleRefresh(current: [r], history: []))
    }

    @Test("refresh keeps the user's servings when the base is unchanged")
    func refresh_keepsServingsWhenBaseUnchanged() {
        var stored = Self.oldVersion
        stored.currentServings = 6
        #expect(Self.refreshed(stored).first?.currentServings == 6)
    }

    @Test("refresh resets servings to the new base when the recipe's base servings changed")
    func refresh_resetsServingsWhenBaseChanged() {
        var stored = Self.oldVersion
        stored.currentServings = 6
        let current = RecipeModel(
            id: Self.sampleID, name: "Chicken Chow Mein", category: "Main", difficulty: "Basic",
            prepTime: "10 minutes", cookingTime: "10 minutes", baseServings: 4,
            ingredients: [Ingredient(baseQuantity: 1, unit: "", name: "noodles")],
            prePrepInstructions: [], instructions: ["Fry."], notes: "", isSampleRecipe: true
        )
        let result = BundledRecipeCatalog.staleSampleRefreshes(library: [stored], current: [current], history: [Self.oldVersion])
        #expect(result.first?.currentServings == 4)
    }

    @Test("a copy matching any of several shipped versions of the same recipe is refreshed")
    func refresh_matchesAnyHistoryVersion() {
        let older = Self.sample(ingredients: ["noodles"], instructions: ["Cook."])
        let result = BundledRecipeCatalog.staleSampleRefreshes(
            library: [older], current: [Self.currentVersion], history: [Self.oldVersion, older]
        )
        #expect(result.count == 1)
        #expect(result.first?.instructions == Self.currentVersion.instructions)
    }

    @Test("an empty stored image name doesn't override the current bundled image")
    func refresh_emptyImageNameTakesBundledImage() {
        var stored = Self.oldVersion
        stored.imageName = ""
        #expect(Self.refreshed(stored).first?.imageName == Self.currentVersion.imageName)
    }

    @Test("existing installs drop hotlinked sample photos but keep the user's own photo and recipes")
    func remoteSamplePhotosAreCleared() {
        var hotlinked = Self.currentVersion
        hotlinked.imageName = "https://example.com/new.jpg"
        var ownPhoto = Self.currentVersion
        ownPhoto.imageName = "RecipeImages/mine.jpg"
        var userRecipe = Self.currentVersion
        userRecipe.isSampleRecipe = false
        let cleared = BundledRecipeCatalog.remoteImageRemovals(library: [hotlinked, ownPhoto, userRecipe])
        #expect(cleared.count == 1)
        #expect(cleared.first?.imageName == nil)
    }

    @Test("sample updates refresh stale copies and clear their remote photo in one pass")
    func sampleUpdates_refreshAndClear() {
        var current = Self.currentVersion
        current.imageName = nil
        let updates = BundledRecipeCatalog.sampleUpdates(library: [Self.oldVersion], current: [current], history: [Self.oldVersion])
        #expect(updates.count == 1)
        #expect(updates.first?.instructions == current.instructions)
        #expect(updates.first?.imageName == nil)
    }

    @Test("a copy is unchanged since its snapshot only if its text and carried-over user state match")
    func isUnchangedSinceSnapshot() throws {
        let snapshot = try #require(SeedRecipeProvider.recipes.first)
        #expect(BundledRecipeCatalog.isUnchanged(snapshot, since: snapshot))
        let changes: [(inout RecipeModel) -> Void] = [
            { $0.ingredients = [] }, { $0.isFavorite.toggle() }, { $0.rating = 3 }, { $0.photoNames.append("p.jpg") },
            { $0.tags.append("weeknight") }, { $0.imageName = "mine.jpg" }, { $0.currentServings += 1 },
            { $0.isSampleRecipe.toggle() }
        ]
        for change in changes {
            var stored = snapshot
            change(&stored)
            #expect(!BundledRecipeCatalog.isUnchanged(stored, since: snapshot))
        }
        var cooked = snapshot
        cooked.cookCount += 1
        #expect(BundledRecipeCatalog.isUnchanged(cooked, since: snapshot))
    }
}
