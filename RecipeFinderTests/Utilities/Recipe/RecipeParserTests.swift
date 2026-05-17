import XCTest
@testable import RecipeFinder

final class RecipeParserTests: XCTestCase {

    // MARK: - JSON-LD parsing

    func testParse_jsonLD_extractsName() {
        let html = jsonLDHTML(name: "Spaghetti Carbonara")
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.name, "Spaghetti Carbonara")
    }

    func testParse_jsonLD_extractsIngredients() {
        let html = jsonLDHTML(ingredients: ["200g spaghetti", "3 eggs", "100g pancetta"])
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.ingredients, ["200g spaghetti", "3 eggs", "100g pancetta"])
    }

    func testParse_jsonLD_extractsInstructions() {
        let instructions = ["Boil the pasta until al dente.", "Mix eggs and cheese together."]
        let html = jsonLDHTML(instructions: instructions)
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.instructions, instructions)
    }

    func testParse_jsonLD_extractsPrepTime_ISO8601() {
        let html = jsonLDHTML(prepTime: "PT15M")
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.prepTime, 15)
    }

    func testParse_jsonLD_extractsCookTime_ISO8601() {
        let html = jsonLDHTML(cookTime: "PT30M")
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.cookTime, 30)
    }

    func testParse_jsonLD_extractsCookTime_hoursAndMinutes() {
        let html = jsonLDHTML(cookTime: "PT1H30M")
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.cookTime, 90)
    }

    func testParse_jsonLD_extractsServings_fromString() {
        let html = jsonLDHTML(recipeYield: "\"4 servings\"")
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.servings, 4)
    }

    func testParse_jsonLD_extractsServings_fromInt() {
        let html = jsonLDHTML(recipeYield: "6")
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.servings, 6)
    }

    func testParse_jsonLD_highConfidence() {
        let html = jsonLDHTML(name: "Pasta")
        let result = RecipeParser.parse(html: html)
        XCTAssertGreaterThan(result.confidence, 0.9)
    }

    func testParse_jsonLD_htmlEntitiesDecoded_inName() {
        let html = jsonLDHTML(name: "Caf&eacute; Latte")
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.name, "Café Latte")
    }

    func testParse_jsonLD_htmlEntitiesDecoded_ampersand() {
        let html = jsonLDHTML(name: "Mac &amp; Cheese")
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.name, "Mac & Cheese")
    }

    // MARK: - @graph schema

    func testParse_jsonLDGraph_extractsRecipe() {
        let html = jsonLDGraphHTML(name: "Risotto")
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.name, "Risotto")
    }

    // MARK: - @type as array (e.g. Smitten Kitchen / WordPress)

    func testParse_jsonLD_typeArray_extractsName() {
        let html = jsonLDHTML_typeArray(name: "Braised Leeks")
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.name, "Braised Leeks")
    }

    func testParse_jsonLD_typeArray_extractsIngredients() {
        let html = jsonLDHTML_typeArray(ingredients: ["1 bundle leeks", "Olive oil"])
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.ingredients, ["1 bundle leeks", "Olive oil"])
    }

    func testParse_jsonLD_graphTypeArray_extractsRecipe() {
        let html = jsonLDGraphHTML_typeArray(name: "Lentil Soup")
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.name, "Lentil Soup")
    }

    // MARK: - Recipe with no instructions still succeeds

    func testParse_jsonLD_noInstructions_stillReturnsRecipe() {
        let html = jsonLDHTML_noInstructions(name: "Simple Salad", ingredients: ["Lettuce", "Dressing"])
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.name, "Simple Salad")
        XCTAssertFalse(result.ingredients.isEmpty)
        // Instructions being empty is acceptable — we don't fail the parse
    }

    // MARK: - Empty / garbage HTML

    func testParse_emptyHTML_returnsEmptyResult() {
        let result = RecipeParser.parse(html: "")
        XCTAssertNil(result.name)
        XCTAssertTrue(result.ingredients.isEmpty)
        XCTAssertTrue(result.instructions.isEmpty)
    }

    func testParse_htmlWithNoRecipe_lowConfidence() {
        let result = RecipeParser.parse(html: "<html><body><p>Hello world</p></body></html>")
        XCTAssertLessThan(result.confidence, 0.5)
    }

    // MARK: - Image URL extraction

    func testParse_jsonLD_extractsImageURL_fromStringValue() {
        let html = jsonLDHTML(image: "\"https://example.com/pasta.jpg\"")
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.imageURL, "https://example.com/pasta.jpg")
    }

    func testParse_jsonLD_extractsImageURL_fromObjectWithURL() {
        let html = jsonLDHTML(image: "{\"@type\":\"ImageObject\",\"url\":\"https://example.com/risotto.jpg\"}")
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.imageURL, "https://example.com/risotto.jpg")
    }

    func testParse_jsonLD_extractsImageURL_fromArray() {
        let html = jsonLDHTML(image: "[\"https://example.com/first.jpg\",\"https://example.com/second.jpg\"]")
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.imageURL, "https://example.com/first.jpg")
    }

    func testParse_ogImage_extractsImageURL_whenNoJSONLD() {
        let html = """
        <html><head>
        <meta property="og:image" content="https://example.com/og-image.jpg" />
        </head><body></body></html>
        """
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.imageURL, "https://example.com/og-image.jpg")
    }

    func testParse_noImage_returnsNilImageURL() {
        let html = jsonLDHTML()
        let result = RecipeParser.parse(html: html)
        XCTAssertNil(result.imageURL)
    }

    func testParse_jsonLDWinsOverOGImage_whenBothPresent() {
        let ogHTML = """
        <html><head>
        <meta property="og:image" content="https://example.com/og.jpg" />
        </head><body>
        \(jsonLDHTML(image: "\"https://example.com/jsonld.jpg\""))
        </body></html>
        """
        let result = RecipeParser.parse(html: ogHTML)
        XCTAssertEqual(result.imageURL, "https://example.com/jsonld.jpg")
    }

    // MARK: - Idempotency

    func testParse_calledTwice_returnsSameResult() {
        let html = jsonLDHTML(name: "Tacos", ingredients: ["tortilla", "beef"])
        let first = RecipeParser.parse(html: html)
        let second = RecipeParser.parse(html: html)
        XCTAssertEqual(first.name, second.name)
        XCTAssertEqual(first.ingredients, second.ingredients)
        XCTAssertEqual(first.confidence, second.confidence)
    }

    // MARK: - Helpers

    private func jsonLDHTML(
        name: String = "Test Recipe",
        ingredients: [String] = ["1 cup flour"],
        instructions: [String] = ["Mix everything together and bake for 30 minutes."],
        prepTime: String = "PT10M",
        cookTime: String = "PT20M",
        recipeYield: String = "4",
        image: String? = nil
    ) -> String {
        let ingredientsJSON = ingredients.map { "\"\($0)\"" }.joined(separator: ", ")
        let instructionsJSON = instructions.map { "{\"@type\":\"HowToStep\",\"text\":\"\($0)\"}" }.joined(separator: ", ")
        let imageJSON = image.map { ",\n          \"image\": \($0)" } ?? ""

        return """
        <html><head>
        <script type="application/ld+json">
        {
          "@context": "https://schema.org",
          "@type": "Recipe",
          "name": "\(name)",
          "recipeIngredient": [\(ingredientsJSON)],
          "recipeInstructions": [\(instructionsJSON)],
          "prepTime": "\(prepTime)",
          "cookTime": "\(cookTime)",
          "recipeYield": \(recipeYield)\(imageJSON)
        }
        </script>
        </head><body></body></html>
        """
    }

    private func jsonLDGraphHTML(name: String) -> String {
        """
        <html><head>
        <script type="application/ld+json">
        {
          "@context": "https://schema.org",
          "@graph": [
            { "@type": "WebSite", "name": "Food Blog" },
            {
              "@type": "Recipe",
              "name": "\(name)",
              "recipeIngredient": ["2 cups arborio rice"],
              "recipeInstructions": [{"@type":"HowToStep","text":"Toast the rice in butter for two minutes."}]
            }
          ]
        }
        </script>
        </head><body></body></html>
        """
    }

    /// JSON-LD where "@type" is an array — as used by Smitten Kitchen and other WordPress sites.
    private func jsonLDHTML_typeArray(
        name: String = "Test Recipe",
        ingredients: [String] = ["1 cup flour"],
        instructions: [String] = ["Mix everything together and bake for 30 minutes."]
    ) -> String {
        let ingredientsJSON = ingredients.map { "\"\($0)\"" }.joined(separator: ", ")
        let instructionsJSON = instructions.map { "{\"@type\":\"HowToStep\",\"text\":\"\($0)\"}" }.joined(separator: ", ")
        return """
        <html><head>
        <script type="application/ld+json">
        {
          "@context": "https://schema.org",
          "@type": ["Recipe"],
          "name": "\(name)",
          "recipeIngredient": [\(ingredientsJSON)],
          "recipeInstructions": [\(instructionsJSON)]
        }
        </script>
        </head><body></body></html>
        """
    }

    /// JSON-LD @graph where the Recipe node has "@type" as an array.
    private func jsonLDGraphHTML_typeArray(name: String) -> String {
        """
        <html><head>
        <script type="application/ld+json">
        {
          "@context": "https://schema.org",
          "@graph": [
            { "@type": ["WebSite"], "name": "Food Blog" },
            {
              "@type": ["Recipe"],
              "name": "\(name)",
              "recipeIngredient": ["1 cup lentils"],
              "recipeInstructions": [{"@type":"HowToStep","text":"Simmer lentils until tender."}]
            }
          ]
        }
        </script>
        </head><body></body></html>
        """
    }

    /// JSON-LD with no recipeInstructions field at all.
    private func jsonLDHTML_noInstructions(name: String, ingredients: [String]) -> String {
        let ingredientsJSON = ingredients.map { "\"\($0)\"" }.joined(separator: ", ")
        return """
        <html><head>
        <script type="application/ld+json">
        {
          "@context": "https://schema.org",
          "@type": "Recipe",
          "name": "\(name)",
          "recipeIngredient": [\(ingredientsJSON)]
        }
        </script>
        </head><body></body></html>
        """
    }
}
