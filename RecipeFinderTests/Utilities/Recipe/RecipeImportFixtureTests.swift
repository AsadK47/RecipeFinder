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
