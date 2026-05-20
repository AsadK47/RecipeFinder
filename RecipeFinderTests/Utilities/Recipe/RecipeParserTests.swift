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

    // MARK: - WPRM parsing

    /// Regression: WPRM renders fractions as nested `<span>` elements. The old `([^<]+)` pattern
    /// stopped at the first `<`, so "1/4" became "1" (the whole-number prefix before the inner span)
    /// and combined with the unit "cup" produced "1 cup" instead of "1/4 cup".
    func testParse_wprm_fractionInNestedSpan_preservesFraction() {
        let html = wprmHTML(
            ingredients: [wprmIngredientLI(fractionAmount: ("1", "4"), unit: "cup", name: "neutral oil", notes: "such as grapeseed or avocado oil")],
            instructions: ["Heat a medium pot over medium-high heat and add the oil."]
        )
        let result = RecipeParser.parse(html: html)
        XCTAssertFalse(result.ingredients.isEmpty, "Expected at least one ingredient")
        let oil = result.ingredients.first ?? ""
        XCTAssertTrue(oil.hasPrefix("1/4"), "Expected amount '1/4', got '\(oil)'")
        XCTAssertTrue(oil.contains("cup"), "Expected unit 'cup' in '\(oil)'")
        XCTAssertTrue(oil.contains("neutral oil"), "Expected name 'neutral oil' in '\(oil)'")
    }

    func testParse_wprm_fractionInNestedSpan_doesNotProduce1Cup() {
        // Explicit guard: the buggy output "1 cup neutral oil" must not appear
        let html = wprmHTML(
            ingredients: [wprmIngredientLI(fractionAmount: ("1", "4"), unit: "cup", name: "neutral oil")],
            instructions: ["Heat a medium pot over medium-high heat and add the oil."]
        )
        let result = RecipeParser.parse(html: html)
        let oil = result.ingredients.first ?? ""
        XCTAssertNotEqual(oil, "1 cup neutral oil", "Bug regression: 1/4 must not collapse to '1 cup'")
    }

    func testParse_wprm_plainTextAmount_stillWorks() {
        let html = wprmHTML(
            ingredients: [wprmIngredientLI(plainAmount: "2", unit: "tbsp", name: "ghee")],
            instructions: ["Melt the ghee in a pan over medium heat until fragrant."]
        )
        let result = RecipeParser.parse(html: html)
        XCTAssertFalse(result.ingredients.isEmpty)
        XCTAssertEqual(result.ingredients.first, "2 tbsp ghee")
    }

    func testParse_wprm_unicodeFractionAmount_stillWorks() {
        // WPRM sometimes emits Unicode fractions directly (e.g. ¼ for 1/4)
        let html = wprmHTML(
            ingredients: [wprmIngredientLI(plainAmount: "¼", unit: "cup", name: "ghee")],
            instructions: ["Melt the ghee in a pan over medium heat until fragrant."]
        )
        let result = RecipeParser.parse(html: html)
        XCTAssertFalse(result.ingredients.isEmpty)
        let ghee = result.ingredients.first ?? ""
        XCTAssertTrue(ghee.hasPrefix("¼"), "Expected '¼' prefix, got '\(ghee)'")
    }

    func testParse_wprm_mixedNumberAmount() {
        // "1 1/2 cups" — whole number before fraction span
        let html = wprmHTML(
            ingredients: [wprmIngredientLI(mixedAmount: ("1", "1", "2"), unit: "cups", name: "water")],
            instructions: ["Add water to the pot and bring to a boil over high heat."]
        )
        let result = RecipeParser.parse(html: html)
        XCTAssertFalse(result.ingredients.isEmpty)
        let water = result.ingredients.first ?? ""
        // Should contain both the whole part and the fraction
        XCTAssertTrue(water.contains("1/2") || water.contains("1 1/2"), "Expected '1 1/2' in '\(water)'")
    }

    func testParse_wprm_extractsNameAndCuisine() {
        let html = wprmHTML(
            name: "Aloo Gosht",
            cuisine: "Pakistani",
            course: "Main Course",
            ingredients: [wprmIngredientLI(plainAmount: "1", unit: "lb", name: "lamb")],
            instructions: ["Sear the lamb in oil over high heat for five to six minutes."]
        )
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.name, "Aloo Gosht")
        XCTAssertEqual(result.cuisine, "Pakistani")
        XCTAssertEqual(result.category, "Main Course")
    }

    func testParse_wprm_extractsCookTime() {
        let html = wprmHTML(
            cookMinutes: 135,
            ingredients: [wprmIngredientLI(plainAmount: "1", unit: "lb", name: "lamb")],
            instructions: ["Cook the lamb with spices for two hours until tender."]
        )
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.cookTime, 135)
    }

    // MARK: - JSON-LD HowToSection nesting

    /// Regression: sections were previously collapsed with `.joined(separator: " ")`, turning
    /// multiple steps into a single long string and losing all step boundaries.
    func testParse_jsonLD_howToSection_flattensIntoIndividualSteps() {
        let html = jsonLDHTML_howToSections(sections: [
            ("Stovetop Method", [
                "Heat oil in a large pot over medium-high heat until shimmering.",
                "Add the lamb and sear for six to seven minutes, stirring occasionally."
            ]),
            ("Finishing", [
                "Stir in yogurt and add the potatoes with two cups of water.",
                "Simmer for twenty-five minutes until potatoes are fork tender."
            ])
        ])
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.instructions.count, 4, "Expected 4 individual steps, got \(result.instructions.count): \(result.instructions)")
    }

    func testParse_jsonLD_howToSection_eachStepIsIndependent() {
        let step1 = "Heat oil in a large pot over medium-high heat until shimmering."
        let step2 = "Add the lamb and sear for six to seven minutes, stirring occasionally."
        let html = jsonLDHTML_howToSections(sections: [("Method", [step1, step2])])
        let result = RecipeParser.parse(html: html)
        XCTAssertTrue(result.instructions.contains(step1), "Step 1 missing from \(result.instructions)")
        XCTAssertTrue(result.instructions.contains(step2), "Step 2 missing from \(result.instructions)")
    }

    func testParse_jsonLD_howToSection_doesNotJoinStepsIntoOneString() {
        let step1 = "Heat oil in a large pot over medium-high heat until shimmering."
        let step2 = "Add the lamb and sear for six to seven minutes, stirring occasionally."
        let html = jsonLDHTML_howToSections(sections: [("Method", [step1, step2])])
        let result = RecipeParser.parse(html: html)
        // If steps were joined, there would be exactly one instruction containing both texts
        let wronglyJoined = result.instructions.first(where: { $0.contains(step1) && $0.contains(step2) })
        XCTAssertNil(wronglyJoined, "Steps must not be joined into a single instruction string")
    }

    func testParse_jsonLD_mixedFlatAndSectionSteps() {
        // Some recipes have a flat HowToStep followed by a HowToSection
        let html = """
        <html><head>
        <script type="application/ld+json">
        {
          "@context": "https://schema.org",
          "@type": "Recipe",
          "name": "Mixed Instructions Recipe",
          "recipeIngredient": ["1 cup flour"],
          "recipeInstructions": [
            { "@type": "HowToStep", "text": "Preheat oven to 350 degrees Fahrenheit before you begin." },
            {
              "@type": "HowToSection",
              "name": "Make the dough",
              "itemListElement": [
                { "@type": "HowToStep", "text": "Combine flour and butter until the mixture resembles breadcrumbs." },
                { "@type": "HowToStep", "text": "Add water gradually and mix until a smooth dough forms." }
              ]
            }
          ]
        }
        </script>
        </head><body></body></html>
        """
        let result = RecipeParser.parse(html: html)
        XCTAssertEqual(result.instructions.count, 3, "Expected 3 steps (1 flat + 2 from section), got \(result.instructions.count)")
    }

    // MARK: - Real-world fixture: Aloo Gosht (teaforturmeric.com)

    /// JSON-LD fixture matching the schema.org/Recipe structure that teaforturmeric.com
    /// (a WPRM-powered site) generates. Tests that the key ingredients are parsed verbatim,
    /// including the fractional amounts that caused the "1/4 → 1 cup" regression.
    func testParse_alooGosht_jsonLD_ingredientsPreservedVerbatim() {
        let result = RecipeParser.parse(html: alooGoshtJSONLDHTML())
        XCTAssertEqual(result.name, "Aloo Gosht (Mutton/Lamb and Potato Curry)")
        XCTAssertTrue(result.ingredients.contains("1/4 cup neutral oil, such as grapeseed or avocado oil"),
                      "1/4 cup oil missing or mangled in: \(result.ingredients)")
        XCTAssertTrue(result.ingredients.contains("1 tbsp ghee, sub butter"),
                      "ghee missing in: \(result.ingredients)")
        XCTAssertTrue(result.ingredients.contains("1/2 tsp turmeric powder"),
                      "turmeric missing in: \(result.ingredients)")
    }

    func testParse_alooGosht_jsonLD_metadata() {
        let result = RecipeParser.parse(html: alooGoshtJSONLDHTML())
        XCTAssertEqual(result.cookTime, 135)   // PT2H15M
        XCTAssertEqual(result.servings, 4)
        XCTAssertEqual(result.cuisine, "Pakistani")
        XCTAssertEqual(result.category, "Main Course")
    }

    func testParse_alooGosht_jsonLD_instructionCount() {
        let result = RecipeParser.parse(html: alooGoshtJSONLDHTML())
        // Stovetop: 8 steps, Instant Pot: 5 steps = 13 total
        XCTAssertEqual(result.instructions.count, 13,
                       "Expected 13 steps from two HowToSection blocks, got \(result.instructions.count)")
    }

    func testParse_alooGosht_jsonLD_noIngredientHasWrongAmount() {
        let result = RecipeParser.parse(html: alooGoshtJSONLDHTML())
        for ingredient in result.ingredients {
            XCTAssertFalse(ingredient == "1 cup neutral oil",
                           "Bug: '1/4 cup' was mis-parsed as '1 cup'")
        }
    }

    // MARK: - Additional test helpers

    /// Builds a minimal WPRM-style HTML page.
    private func wprmHTML(
        name: String = "Test Recipe",
        cuisine: String? = nil,
        course: String? = nil,
        cookMinutes: Int? = nil,
        servings: Int = 4,
        ingredients: [String] = [],
        instructions: [String] = []
    ) -> String {
        let cuisineSpan = cuisine.map { "<span class=\"wprm-recipe-cuisine\">\($0)</span>" } ?? ""
        let courseSpan = course.map { "<span class=\"wprm-recipe-course\">\($0)</span>" } ?? ""
        let cookSpan = cookMinutes.map { "<span class=\"wprm-recipe-cook_time-minutes\">\($0)</span>" } ?? ""
        let ingredientItems = ingredients.joined(separator: "\n")
        let instructionItems = instructions.map {
            "<li class=\"wprm-recipe-instruction\"><div class=\"wprm-recipe-instruction-text\">\($0)</div></li>"
        }.joined(separator: "\n")

        return """
        <html><head><title>\(name)</title></head><body>
        <div class="wprm-recipe-container" id="wprm-recipe-1">
          <span class="wprm-recipe-name">\(name)</span>
          \(cuisineSpan)\(courseSpan)\(cookSpan)
          <span class="wprm-recipe-servings" data-recipe="1" data-servings="\(servings)">\(servings)</span>
          <ul class="wprm-recipe-ingredients">
            \(ingredientItems)
          </ul>
          <ol class="wprm-recipe-instructions">
            \(instructionItems)
          </ol>
        </div>
        </body></html>
        """
    }

    /// WPRM `<li>` for a plain text amount (no nested fraction spans).
    private func wprmIngredientLI(plainAmount: String, unit: String = "", name: String, notes: String = "") -> String {
        let unitSpan = unit.isEmpty ? "" : "<span class=\"wprm-recipe-ingredient-unit\">\(unit)</span>"
        let notesSpan = notes.isEmpty ? "" : "<span class=\"wprm-recipe-ingredient-notes\">\(notes)</span>"
        return """
        <li class="wprm-recipe-ingredient">
          <span class="wprm-recipe-ingredient-amount">\(plainAmount)</span>
          \(unitSpan)
          <span class="wprm-recipe-ingredient-name">\(name)</span>
          \(notesSpan)
        </li>
        """
    }

    /// WPRM `<li>` where the amount is a pure fraction rendered in nested spans (e.g. 1/4).
    /// This is the structure that triggered the "1/4 → 1 cup" regression.
    private func wprmIngredientLI(fractionAmount: (numerator: String, denominator: String), unit: String = "", name: String, notes: String = "") -> String {
        let unitSpan = unit.isEmpty ? "" : "<span class=\"wprm-recipe-ingredient-unit\">\(unit)</span>"
        let notesSpan = notes.isEmpty ? "" : "<span class=\"wprm-recipe-ingredient-notes\">\(notes)</span>"
        return """
        <li class="wprm-recipe-ingredient">
          <span class="wprm-recipe-ingredient-amount"><span class="wprm-recipe-fraction"><span class="wprm-recipe-fraction-numerator">\(fractionAmount.numerator)</span><span class="wprm-recipe-fraction-slash">/</span><span class="wprm-recipe-fraction-denominator">\(fractionAmount.denominator)</span></span></span>
          \(unitSpan)
          <span class="wprm-recipe-ingredient-name">\(name)</span>
          \(notesSpan)
        </li>
        """
    }

    /// WPRM `<li>` for a mixed number amount (whole + fraction spans), e.g. "1 1/2 cups".
    private func wprmIngredientLI(mixedAmount: (whole: String, numerator: String, denominator: String), unit: String = "", name: String) -> String {
        let unitSpan = unit.isEmpty ? "" : "<span class=\"wprm-recipe-ingredient-unit\">\(unit)</span>"
        return """
        <li class="wprm-recipe-ingredient">
          <span class="wprm-recipe-ingredient-amount">\(mixedAmount.whole)<span class="wprm-recipe-fraction"><span class="wprm-recipe-fraction-numerator">\(mixedAmount.numerator)</span><span class="wprm-recipe-fraction-slash">/</span><span class="wprm-recipe-fraction-denominator">\(mixedAmount.denominator)</span></span></span>
          \(unitSpan)
          <span class="wprm-recipe-ingredient-name">\(name)</span>
        </li>
        """
    }

    /// JSON-LD with `recipeInstructions` as an array of `HowToSection` objects.
    private func jsonLDHTML_howToSections(sections: [(name: String, steps: [String])]) -> String {
        let sectionsJSON = sections.map { section in
            let stepsJSON = section.steps.map { step in
                "{\"@type\":\"HowToStep\",\"text\":\"\(step)\"}"
            }.joined(separator: ",")
            return """
            {
              "@type": "HowToSection",
              "name": "\(section.name)",
              "itemListElement": [\(stepsJSON)]
            }
            """
        }.joined(separator: ",")

        return """
        <html><head>
        <script type="application/ld+json">
        {
          "@context": "https://schema.org",
          "@type": "Recipe",
          "name": "Sectioned Recipe",
          "recipeIngredient": ["1 cup flour", "2 eggs"],
          "recipeInstructions": [\(sectionsJSON)]
        }
        </script>
        </head><body></body></html>
        """
    }

    /// Realistic JSON-LD fixture for the Aloo Gosht recipe from teaforturmeric.com.
    /// Mirrors the schema.org/Recipe structure that WPRM generates, including two
    /// HowToSection blocks (Stovetop + Instant Pot) and fractional ingredient amounts.
    private func alooGoshtJSONLDHTML() -> String {
        """
        <html><head>
        <script type="application/ld+json">
        {
          "@context": "https://schema.org/",
          "@type": "Recipe",
          "name": "Aloo Gosht (Mutton/Lamb and Potato Curry)",
          "description": "A traditional Pakistani-style Mutton/Lamb and Potato Curry. Make this recipe with lamb or goat over stovetop or Instant Pot.",
          "image": "https://www.teaforturmeric.com/wp-content/uploads/2016/11/Aloo-Gosht-13-1.jpg",
          "author": { "@type": "Person", "name": "Izzah Cheema" },
          "datePublished": "2022-03-11",
          "cookTime": "PT2H15M",
          "recipeYield": "4 servings",
          "recipeCategory": "Main Course",
          "recipeCuisine": "Pakistani",
          "recipeIngredient": [
            "1/4 cup neutral oil, such as grapeseed or avocado oil",
            "1 tbsp ghee, sub butter",
            "1-1.2 lb bone-in goat or lamb meat, cut into ~2\\u201d pieces",
            "1 3/4 tsp kosher salt, divided",
            "6-7 garlic cloves, crushed or finely chopped",
            "1 inch ginger, crushed or finely chopped",
            "1 medium yellow onion, finely chopped",
            "2 small tomatoes, roughly pur\\u00e9ed",
            "1-2 small green chili peppers",
            "2 green cardamom pods",
            "3 whole cloves",
            "1/2 tsp cumin seeds",
            "1.5-2 tsp coriander powder",
            "1/2-1 tsp cumin powder",
            "1/2 tsp red chili powder",
            "1/2 tsp turmeric powder",
            "1/4 tsp ground black pepper",
            "1 tbsp plain whole-milk yogurt, whisked",
            "2 small russet potatoes, peeled and cut into 1.5-2\\u201d cubes",
            "1/2 tsp garam masala",
            "2 tbsp cilantro leaves, chopped"
          ],
          "recipeInstructions": [
            {
              "@type": "HowToSection",
              "name": "Stovetop Method",
              "itemListElement": [
                { "@type": "HowToStep", "text": "Heat a medium Dutch oven over medium-high heat. Add oil and ghee. Once hot, add meat and 3/4 tsp salt. Saut\\u00e9 for 6-7 minutes until seared." },
                { "@type": "HowToStep", "text": "Add garlic and ginger and saut\\u00e9 for another minute until no longer raw." },
                { "@type": "HowToStep", "text": "Add onion, tomatoes, green chili, whole spices, ground spices, and remaining 1 tsp salt. Add 1 to 1 1/4 cups water and bring to a boil." },
                { "@type": "HowToStep", "text": "Reduce heat to a gentle simmer. Cover and cook for 1 hour 30 minutes until meat is fully cooked and breaks when pressed with a wooden spoon." },
                { "@type": "HowToStep", "text": "Increase heat to high and saut\\u00e9 out remaining moisture for 5-7 minutes. Continue to saut\\u00e9 (bhunai) for another 5-6 minutes until oil separates." },
                { "@type": "HowToStep", "text": "Reduce heat to low and stir in yogurt. Add potatoes and 2 to 2 1/4 cups water." },
                { "@type": "HowToStep", "text": "Bring to a boil, then reduce to a simmer. Cover and cook for 23-25 minutes until potatoes are fork tender. Taste and adjust salt." },
                { "@type": "HowToStep", "text": "Uncover and simmer until oil rises to top, about 2-3 minutes. Garnish with garam masala and cilantro. Serve with roti, paratha, naan, or basmati rice." }
              ]
            },
            {
              "@type": "HowToSection",
              "name": "Instant Pot Method",
              "itemListElement": [
                { "@type": "HowToStep", "text": "Select Saut\\u00e9-More/High on the Instant Pot. Add oil, ghee, meat, and 3/4 tsp salt. Saut\\u00e9 5 minutes. Add garlic, ginger, onion, tomatoes, chili, spices, and remaining salt." },
                { "@type": "HowToStep", "text": "Add up to 1/4 cup water if needed. Moisture should cover at least 1/3 of the meat." },
                { "@type": "HowToStep", "text": "Cancel Saut\\u00e9. Pressure Cook on High for 20 minutes. Natural release for 10 minutes. Meat should break when pressed." },
                { "@type": "HowToStep", "text": "Select Saut\\u00e9-More/High. Saut\\u00e9 out moisture for 5-7 minutes then continue bhunai for 5-6 minutes until oil separates." },
                { "@type": "HowToStep", "text": "Cancel Saut\\u00e9. Stir in yogurt. Add potatoes and 2 cups water. Pressure Cook on High for 5-6 minutes. Natural release 5 minutes. Garnish and serve." }
              ]
            }
          ]
        }
        </script>
        </head><body></body></html>
        """
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
