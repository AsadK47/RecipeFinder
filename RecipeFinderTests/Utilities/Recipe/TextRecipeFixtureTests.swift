import Testing
import Foundation
@testable import RecipeFinder

/// Corpus tests for `TextRecipeParser` against real recipes captured from
/// textonlyrecipes.com (see `TextRecipeFixtures`). Proves the text/paste/OCR path
/// extracts name, ingredients, and instructions correctly across both headered
/// and header-less layouts — and that the extracted lines feed the ingredient
/// parser cleanly end to end.
@Suite struct TextRecipeFixtureTests {

    @Test(
        "Extracts real recipes into name + ingredient/instruction counts",
        arguments: [
            // (name, fixture, ingredientCount, instructionCount, firstInstructionPrefix)
            ("Banana Bread", TextRecipeFixtures.bananaBread, 10, 6, "Preheat the oven to 325 degrees F."),
            ("Chicken Curry", TextRecipeFixtures.chickenCurry, 14, 8, "Heat oil in a deep pan"),
            ("Pancakes", TextRecipeFixtures.pancakes, 10, 8, "In a large mixing bowl, whisk together"),
            ("Spaghetti Bolognese", TextRecipeFixtures.spaghettiBolognese, 12, 5, "In a large skillet, cook the ground beef"),
            ("Apple Pie", TextRecipeFixtures.applePie, 10, 9, "Preheat your oven to 425"),            // trailing "Note:" dropped
            ("Oatmeal Cookies", TextRecipeFixtures.oatmealCookies, 11, 10, "Preheat the oven to 350 degrees F (175 degrees C)."),
            ("Lentil Soup", TextRecipeFixtures.lentilSoup, 14, 7, "Rinse the lentils under cold water"), // trailing "Note:" dropped
            ("Barbecue Sauce", TextRecipeFixtures.barbecueSauce, 11, 7, "In a medium saucepan, combine all the ingredients."),
            ("Margaritas", TextRecipeFixtures.margaritas, 5, 1, "Blend all ingredients throughly in blender."), // "*" footnote dropped
            ("Instant Pot Tikka Masala", TextRecipeFixtures.tikkaMasala, 16, 7, "Set the Instant Pot to sauté mode")
        ]
    )
    func parsesRealRecipe(
        name: String, fixture: String, ingredientCount: Int, instructionCount: Int, firstInstruction: String
    ) throws {
        let r = try #require(TextRecipeParser.parse(fixture))
        #expect(r.name == name)
        #expect(r.ingredients?.count == ingredientCount)
        #expect(r.instructions?.count == instructionCount)
        #expect(r.instructions?.first?.hasPrefix(firstInstruction) == true)
    }

    /// The extracted ingredient lines must parse cleanly through the shared
    /// `IngredientLineParser` — quantity/unit/name, parentheticals stripped.
    @Test func extractedLinesFeedIngredientParser() throws {
        let sp = try #require(TextRecipeParser.parse(TextRecipeFixtures.spaghettiBolognese))
        let canLine = try #require(sp.ingredients?.first { $0.contains("crushed tomatoes") })
        let can = IngredientLineParser.parse(canLine)
        #expect(can.quantity == 1)
        #expect(can.unit == "can")            // "(14 oz)" stripped, "can" recognised
        #expect(can.name == "crushed tomatoes")

        let bb = try #require(TextRecipeParser.parse(TextRecipeFixtures.bananaBread))
        let butterLine = try #require(bb.ingredients?.first { $0.contains("unsalted butter") })
        let butter = IngredientLineParser.parse(butterLine)
        #expect(butter.quantity == 8)
        #expect(butter.unit == "tbsp")        // "8 tablespoons (1 stick) ..." → 8 tbsp
        #expect(butter.name.contains("unsalted butter"))
    }

    /// Trickier ingredient lines surfaced by the wider corpus: a glued drink unit,
    /// a decimal weight, and a range.
    @Test func handlesCorpusIngredientEdgeCases() throws {
        let m = try #require(TextRecipeParser.parse(TextRecipeFixtures.margaritas))
        let limeade = try #require(m.ingredients?.first { $0.contains("limeade") })
        let limeadeParsed = IngredientLineParser.parse(limeade)     // "6oz frozen limeade"
        #expect(limeadeParsed.quantity == 6)
        #expect(limeadeParsed.unit == "oz")
        #expect(limeadeParsed.name == "frozen limeade")

        let tm = try #require(TextRecipeParser.parse(TextRecipeFixtures.tikkaMasala))
        let chicken = try #require(tm.ingredients?.first { $0.contains("chicken breasts") })
        let chickenParsed = IngredientLineParser.parse(chicken)     // "1.5 lbs boneless, ..."
        #expect(chickenParsed.quantity == 1.5)
        #expect(chickenParsed.unit == "lbs")
        #expect(chickenParsed.name.hasPrefix("boneless"))

        let ap = try #require(TextRecipeParser.parse(TextRecipeFixtures.applePie))
        let apples = try #require(ap.ingredients?.first { $0.contains("apples") })
        let applesParsed = IngredientLineParser.parse(apples)       // "6-7 medium-sized apples, ..."
        #expect(applesParsed.quantity == 7)                          // range → upper bound
        #expect(applesParsed.unit == "")
        #expect(applesParsed.name.hasPrefix("medium-sized apples"))
    }
}
