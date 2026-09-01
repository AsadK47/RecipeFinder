import Testing
@testable import RecipeFinder

/// Real-world import robustness, driven by full-page HTML fixtures
/// (see `RecipeHTMLFixtures`). Where `RecipeParserTests` checks the parser on
/// clean synthetic markup, these prove it survives how real sites actually
/// structure their pages.
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
}
