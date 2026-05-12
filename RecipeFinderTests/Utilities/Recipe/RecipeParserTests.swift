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
        recipeYield: String = "4"
    ) -> String {
        let ingredientsJSON = ingredients.map { "\"\($0)\"" }.joined(separator: ", ")
        let instructionsJSON = instructions.map { "{\"@type\":\"HowToStep\",\"text\":\"\($0)\"}" }.joined(separator: ", ")

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
          "recipeYield": \(recipeYield)
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
}
