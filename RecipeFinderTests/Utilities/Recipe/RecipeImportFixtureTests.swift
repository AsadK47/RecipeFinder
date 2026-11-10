import Foundation
import Testing
@testable import RecipeFinder

/// Real-world import robustness driven by full-page HTML fixtures (`RecipeHTMLFixtures`) — where `RecipeParserTests` uses clean synthetic markup, these prove the parser survives how real sites structure pages.
@Suite struct RecipeImportFixtureTests {

    // MARK: - Modern WordPress blog (JSON-LD @graph, @type array, HowToSection)

    @Test func modernWordPressBlog_extractsAllCoreFields() {
        let r = RecipeParser.parse(html: RecipeHTMLFixtures.modernWordPressBlog)

        #expect(r.name == "Garlic Butter Chicken")
        #expect(r.ingredients.count == 5)
        #expect(r.ingredients.last == "Salt & pepper to taste") // entity decoded
        #expect(r.instructions.count == 3)                       // sections flattened to steps
        #expect(r.prepTime == 10)
        #expect(r.cookTime == 20)
        #expect(r.servings == 4)
        #expect(r.imageURL == "https://cdn.example.com/garlic-butter-chicken.jpg")
        #expect(r.confidence > 0.9)
    }

    // MARK: - Fully-qualified schema.org @type URL

    @Test func schemaOrgURLType_isRecognizedAsRecipe() {
        let r = RecipeParser.parse(html: RecipeHTMLFixtures.schemaOrgURLType)

        #expect(r.name == "Classic Lemonade")
        #expect(r.ingredients.count == 4)
        #expect(r.instructions.count == 2)
        #expect(r.prepTime == 5)
        #expect(r.servings == 6)
        #expect(r.confidence > 0.9) // JSON-LD path, not the free-text fallback
    }

    // MARK: - Microdata-only page (itemprop, no JSON-LD)

    @Test func microdataOnly_extractsCoreFields() {
        let r = RecipeParser.parse(html: RecipeHTMLFixtures.microdataOnly)

        #expect(r.name == "Hearty Beef Stew")
        #expect(r.ingredients.count == 5)
        #expect(r.ingredients.first == "2 lbs beef chuck, cubed")
        #expect(r.instructions.count == 3)
        #expect(r.prepTime == 20)
        #expect(r.cookTime == 120)
        #expect(r.servings == 6)
        #expect(r.imageURL == "https://cdn.example.com/beef-stew.jpg")
        #expect(r.confidence > 0.8) // structured microdata, not free-text guessing
    }

    // MARK: - RDFa-only page (vocab/typeof/property, no JSON-LD or microdata)

    @Test func rdfaOnly_extractsCoreFields() {
        let r = RecipeParser.parse(html: RecipeHTMLFixtures.rdfaOnly)

        #expect(r.name == "Roasted Tomato Soup")
        #expect(r.ingredients.count == 5)
        #expect(r.ingredients.first == "2 lbs ripe tomatoes, halved")
        #expect(r.instructions.count == 3)
        #expect(r.prepTime == 15)
        #expect(r.cookTime == 40)
        #expect(r.servings == 4)
        #expect(r.imageURL == "https://cdn.example.com/tomato-soup.jpg")
        #expect(r.confidence > 0.8) // structured RDFa, not the free-text fallback
    }

    // MARK: - Plain blog, no structured data (free-text fallback)

    @Test func plainBlogNoStructuredData_extractsNameAndFullLists() {
        let r = RecipeParser.parse(html: RecipeHTMLFixtures.plainBlogNoStructuredData)

        #expect(r.name == "Fluffy Pancakes")      // site-name suffix stripped
        #expect(r.ingredients.count == 7)          // heading not merged with first item
        #expect(r.ingredients.first == "2 cups all-purpose flour")
        #expect(r.instructions.count == 4)
    }

    // MARK: - JSON-LD single-value fields (not arrays)

    @Test func jsonLDSingleValues_handlesStringIngredientAndObjectInstruction() {
        let r = RecipeParser.parse(html: RecipeHTMLFixtures.jsonLDSingleValues)

        #expect(r.name == "One-Ingredient Wonder")
        #expect(r.ingredients == ["1 cup magic"])
        #expect(r.instructions == ["Stir the magic until it shimmers, then serve."])
        #expect(r.confidence > 0.9) // still the JSON-LD path
    }

    // MARK: - Microdata container instructions

    @Test func microdataContainerInstructions_pullsStepsFromContainer() {
        let r = RecipeParser.parse(html: RecipeHTMLFixtures.microdataContainerInstructions)

        #expect(r.name == "Simple Omelette")
        #expect(r.ingredients.count == 3)
        #expect(r.instructions.count == 3)
        #expect(r.instructions.first == "Beat the eggs with a pinch of salt.")
    }

    // MARK: - Recipe nested under WebPage.mainEntity

    @Test func jsonLDMainEntity_extractsRecipeFromMainEntity() {
        let r = RecipeParser.parse(html: RecipeHTMLFixtures.jsonLDMainEntity)

        #expect(r.name == "Overnight Oats")
        #expect(r.ingredients.count == 4)
        #expect(r.instructions.count == 2)
        #expect(r.prepTime == 5)
        #expect(r.servings == 2)
        #expect(r.imageURL == "https://cdn.example.com/overnight-oats.jpg")
        #expect(r.confidence > 0.9) // JSON-LD path, not the free-text fallback
    }

    // MARK: - Trailing-comma JSON-LD (regression guard)

    @Test func jsonLDTrailingCommas_stillParsesViaJSONLD() {
        let r = RecipeParser.parse(html: RecipeHTMLFixtures.jsonLDTrailingCommas)

        #expect(r.name == "No-Knead Bread")
        #expect(r.ingredients.count == 4)
        #expect(r.instructions.count == 2)
        #expect(r.prepTime == 15)
        #expect(r.cookTime == 45)
        #expect(r.servings == 1)
        #expect(r.confidence > 0.9) // JSON-LD path wins (JSONSerialization tolerates trailing commas)
    }
}

/// Import 5/5: the in-app recipe browser's search URLs and its "Recipe found" badge.
@Suite struct WebRecipeSearchTests {

    @Test("Blank queries give no search page", arguments: WebRecipeSearchEngine.allCases)
    func blankQuery(engine: WebRecipeSearchEngine) {
        #expect(engine.searchURL(for: "   ") == nil)
    }

    @Test("Each engine searches its own site, query encoded", arguments: [
        (WebRecipeSearchEngine.duckDuckGo, "https://duckduckgo.com/?q=lemon%20cake%20recipe"),
        (.google, "https://www.google.com/search?q=lemon%20cake%20recipe"),
        (.bbcGoodFood, "https://www.bbcgoodfood.com/search?q=lemon%20cake"),
    ])
    func searchURL(engine: WebRecipeSearchEngine, expected: String) {
        #expect(engine.searchURL(for: " lemon cake ")?.absoluteString == expected)
    }

    @Test("DuckDuckGo is the default engine")
    func defaultEngine() {
        #expect(WebRecipeSearchEngine.default == .duckDuckGo)
    }

    @Test("Pages with schema.org Recipe data are detected; plain pages are not")
    func detectsRecipeData() {
        #expect(RecipeParser.hasRecipeData(html: RecipeHTMLFixtures.plainBlogNoStructuredData) == false)
        let page = #"<html><script type="application/ld+json">{"@type":"Recipe","name":"Soup","recipeIngredient":["1 onion"],"recipeInstructions":["Cook"]}</script></html>"#
        #expect(RecipeParser.hasRecipeData(html: page))
    }
}


/// Import from other apps: per-format parsers on hand-made samples in `Fixtures/OtherApps/` (no real user exports),
/// read from the source tree via `#filePath`.
@Suite("Import from other apps")
struct OtherAppImportTests {

    private func fixture(_ name: String) throws -> Data {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Fixtures/OtherApps/\(name)")
        return try Data(contentsOf: url)
    }

    @Test("Paprika recipe maps every field")
    func paprika() throws {
        let recipe = try #require(PaprikaRecipeParser.parse(json: try fixture("paprika-lemon-drizzle.json")))
        #expect(recipe.name == "Lemon Drizzle Cake")
        #expect(recipe.ingredients.count == 5)          // blank line dropped
        #expect(recipe.ingredients.first == "225 g unsalted butter")
        #expect(recipe.instructions.count == 3)
        #expect(recipe.servings == 10)
        #expect(recipe.prepMinutes == 15)
        #expect(recipe.cookMinutes == 45)
        #expect(recipe.notes == "Drizzle while warm.")
        #expect(recipe.sourceURL == "https://example.com/lemon-drizzle")
        #expect(recipe.category == "Baking")
        #expect(recipe.photoData == Data("hello".utf8))
    }

    @Test("Mela recipe maps every field; empty strings and lists stay nil")
    func mela() throws {
        let recipe = try #require(MelaRecipeParser.parse(json: try fixture("mela-shakshuka.melarecipe")))
        #expect(recipe.name == "Shakshuka")
        #expect(recipe.ingredients == ["2 tbsp olive oil", "1 onion, sliced", "400 g chopped tomatoes", "4 eggs"])
        #expect(recipe.instructions.count == 3)
        #expect(recipe.servings == 2)
        #expect(recipe.prepMinutes == 10)
        #expect(recipe.cookMinutes == 65)
        #expect(recipe.notes == nil)
        #expect(recipe.sourceURL == nil)
        #expect(recipe.photoData == nil)
    }

    @Test("Unreadable or nameless JSON is rejected", arguments: ["not json", "{}", #"{"name": "  "}"#, "[1, 2]"])
    func rejectsBadJSON(text: String) {
        #expect(PaprikaRecipeParser.parse(json: Data(text.utf8)) == nil)
        #expect(MelaRecipeParser.parse(json: Data(text.utf8)) == nil)
    }

    @Test("CSV rows with quoted commas, quotes and newlines; nameless rows skipped")
    func csv() throws {
        let text = try #require(String(data: try fixture("recipes.csv"), encoding: .utf8))
        let recipes = CSVRecipeParser.parse(csv: text)
        #expect(recipes.map(\.name) == ["Tomato Soup", #"Fish, Chips "Deluxe""#])
        #expect(recipes[0].ingredients == ["4 tomatoes", "1 onion", "500 ml stock"])
        #expect(recipes[0].instructions.count == 2)
        #expect(recipes[0].servings == 4)
        #expect(recipes[0].prepMinutes == 10)
        #expect(recipes[0].cookMinutes == 25)
        #expect(recipes[1].prepMinutes == nil)
    }

    @Test("CSV without a name column imports nothing")
    func csvWithoutNameColumn() {
        #expect(CSVRecipeParser.parse(csv: "Ingredients,Instructions\nflour,mix\n").isEmpty)
        #expect(CSVRecipeParser.parse(csv: "").isEmpty)
    }

    @Test("CSV handles Windows line endings")
    func csvCRLF() {
        let recipes = CSVRecipeParser.parse(csv: "Title,Ingredients\r\nToast,bread\r\nTea,\"tea bag\r\nwater\"\r\n")
        #expect(recipes.map(\.name) == ["Toast", "Tea"])
        #expect(recipes[1].ingredients == ["tea bag", "water"])
    }

    private func sample(_ name: String, _ ingredients: [String] = ["1 onion"]) -> OtherAppRecipe {
        OtherAppRecipe(name: name, ingredients: ingredients, instructions: ["Cook"])
    }

    @Test("Duplicates of the library or of the same export are skipped")
    func dedupe() {
        let existing = OtherAppImportPlanner.plan([sample("Soup")], existing: [], source: "Paprika").recipes
        let plan = OtherAppImportPlanner.plan(
            [sample(" soup "), sample("Stew"), sample("STEW"), sample("Stew", ["2 carrots"])],
            existing: existing, source: "Paprika"
        )
        #expect(plan.recipes.map(\.name) == ["Stew", "Stew"])
        #expect(plan.skippedDuplicates == 2)
        #expect(plan.summary == "Imported 2 recipes, skipped 2 duplicates.")
    }

    @Test("Summary wording", arguments: [
        (1, 0, "Imported 1 recipe."), (3, 0, "Imported 3 recipes."), (0, 1, "Imported 0 recipes, skipped 1 duplicate.")
    ])
    func summary(imported: Int, skipped: Int, expected: String) {
        let recipes = (0..<imported).map { _ in
            OtherAppImportPlanner.makeModel(sample("X"), source: "CSV", builder: RecipeImportBuilder())
        }
        #expect(OtherAppImportPlanner.Plan(recipes: recipes, skippedDuplicates: skipped).summary == expected)
    }

    @Test("Imported recipe keeps amounts, times, notes, source and its text for re-import")
    func model() throws {
        let recipe = try #require(PaprikaRecipeParser.parse(json: try fixture("paprika-lemon-drizzle.json")))
        let model = OtherAppImportPlanner.makeModel(recipe, source: "Paprika", builder: RecipeImportBuilder())
        #expect(model.ingredients.first?.baseQuantity == 225)
        #expect(model.ingredients.first?.unit == "g")
        #expect(model.prepTime == "15 minutes")
        #expect(model.cookingTime == "45 minutes")
        #expect(model.baseServings == 10)
        #expect(model.category == "Baking")
        #expect(model.notes == "Drizzle while warm.\n\nImported from Paprika\nhttps://example.com/lemon-drizzle")
        #expect(model.sourceText?.hasPrefix("Lemon Drizzle Cake\n\nIngredients\n225 g unsalted butter") == true)
    }
}
