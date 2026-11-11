import Testing
import XCTest
@testable import RecipeFinder

final class TextRecipeParserTests: XCTestCase {

    // MARK: - Section-header format

    func testParsesHeaderedRecipe() {
        let text = """
        Chicken Curry

        Ingredients:
        - 2 chicken breasts
        - 1 onion
        - 2 tbsp curry powder

        Method:
        1. Dice the onion and fry until soft.
        2. Add the chicken and brown.
        3. Stir in the curry powder and simmer.
        """

        let result = TextRecipeParser.parse(text)

        XCTAssertEqual(result?.name, "Chicken Curry")
        XCTAssertEqual(result?.ingredients, ["2 chicken breasts", "1 onion", "2 tbsp curry powder"])
        XCTAssertEqual(result?.instructions?.count, 3)
        XCTAssertEqual(result?.instructions?.first, "Dice the onion and fry until soft.")
    }


    /// Regression (scanned page): OCR interleaves a SERVES/TIME/Prep/Cook sidebar and GARNISH header into the ingredients — sidebar lines must not become ingredients, garnish items stay, servings/times extract. Mirrors RecipeFinder/Images/PhotoRecipe.jpeg.
    func testFencesSidebarMetadataAndGarnishHeader() {
        let text = """
        Sweet & Sour Prawns

        Ingredients
        2 tablespoons cornflour
        220g tin of pineapple chunks in juice
        GARNISH
        1 spring onion, julienned
        SERVES
        2
        TIME
        Prep 20 minutes
        Cook 20 minutes

        Method
        Mix the cornflour and water.
        Stir-fry everything together.
        """

        let result = TextRecipeParser.parse(text)
        let ingredients = result?.ingredients ?? []

        XCTAssertTrue(ingredients.contains("2 tablespoons cornflour"))
        XCTAssertTrue(ingredients.contains("1 spring onion, julienned"))   // garnish item kept
        XCTAssertFalse(ingredients.contains("2"))                          // stray servings number dropped
        // GARNISH is kept as a group header line ("Garnish:"), never an ingredient.
        XCTAssertEqual(ingredients.compactMap(IngredientSections.title(ofHeaderLine:)), ["Garnish"])
        XCTAssertFalse(IngredientSections.ingredientLines(ingredients).contains { line in
            line.range(of: #"(?i)^(garnish|serves|time|prep|cook)\b"#, options: .regularExpression) != nil
        }, "sidebar/metadata lines must not appear as ingredients")
        XCTAssertEqual(result?.servings, 2)
        XCTAssertEqual(result?.prepTime, 20)
        XCTAssertEqual(result?.cookTime, 20)
    }

    /// Footnotes/asides ("Note:", a "*"-glued footnote) must not become an
    /// ingredient or a step — but a spaced "* " bullet is a real ingredient.
    func testDropsNotesAndFootnotesButKeepsAsteriskBullets() {
        let text = """
        Test Dish
        Ingredients:
        * 2 eggs
        - 1 cup flour
        *chef's secret: use room-temp eggs
        Instructions:
        1. Mix and cook.
        Note: Best served fresh.
        """

        let result = TextRecipeParser.parse(text)
        let ingredients = result?.ingredients ?? []
        let instructions = result?.instructions ?? []

        XCTAssertEqual(ingredients, ["2 eggs", "1 cup flour"])  // spaced "* " bullet kept; glued "*" footnote dropped
        XCTAssertEqual(instructions, ["Mix and cook."])         // "Note:" aside dropped
    }

    func testStripsBulletsAndStepNumbers() {
        let text = """
        Pasta

        Ingredients
        • 200g spaghetti
        * 1 clove garlic

        Steps
        Step 1: Boil the spaghetti.
        2) Fry the garlic.
        """

        let result = TextRecipeParser.parse(text)

        XCTAssertEqual(result?.ingredients, ["200g spaghetti", "1 clove garlic"])
        XCTAssertEqual(result?.instructions, ["Boil the spaghetti.", "Fry the garlic."])
    }

    // MARK: - Metadata

    func testRejectsImplausibleServings() {
        let text = """
        Beef Stew
        Serves: 0

        Ingredients:
        - 500g beef

        Method:
        1. Brown the beef and simmer.
        """
        XCTAssertNil(TextRecipeParser.parse(text)?.servings)
    }

    func testExtractsServingsAndTimes() {
        let text = """
        Beef Stew
        Serves: 6
        Prep time: 20 minutes
        Cooking time: 90 minutes

        Ingredients:
        - 500g beef

        Method:
        1. Brown the beef and simmer.
        """

        let result = TextRecipeParser.parse(text)

        XCTAssertEqual(result?.servings, 6)
        XCTAssertEqual(result?.prepTime, 20)
        XCTAssertEqual(result?.cookTime, 90)
        XCTAssertEqual(result?.ingredients, ["500g beef"])
    }

    func testMetadataLinesAreNotIngredientsOrInstructions() {
        let text = """
        Soup

        Ingredients:
        Serves 4
        - 1 leek

        Method:
        1. Simmer the leek.
        """

        let result = TextRecipeParser.parse(text)

        XCTAssertEqual(result?.ingredients, ["1 leek"])
    }

    // MARK: - Headerless format (caption-style)

    func testParsesHeaderlessCaptionStyleText() {
        let text = """
        Midnight Garlic Noodles
        200g noodles
        4 cloves garlic
        2 tbsp soy sauce
        1. Cook the noodles per the packet.
        2. Fry the garlic gently, then toss everything together.
        """

        let result = TextRecipeParser.parse(text)

        XCTAssertEqual(result?.name, "Midnight Garlic Noodles")
        XCTAssertEqual(result?.ingredients?.count, 3)
        XCTAssertEqual(result?.instructions?.count, 2)
    }

    // MARK: - Rejection

    func testRejectsNonRecipeText() {
        XCTAssertNil(TextRecipeParser.parse("Hey, are we still on for dinner tomorrow?"))
    }

    func testRejectsTextWithIngredientsButNoInstructions() {
        let text = """
        Shopping
        - 2 apples
        - 1 loaf of bread
        """
        XCTAssertNil(TextRecipeParser.parse(text))
    }
}

@Suite("TextRecipeParser decimals")
struct TextRecipeParserDecimalTests {
    @Test("Decimal amounts aren't stripped as numbered-list markers")
    func decimalAmountsSurvive() {
        let text = """
        Aloo Gosht

        Ingredients
        0.44 cup neutral oil
        1.75 tbsp ghee

        Method
        1. Heat the oil and ghee.
        """
        let result = TextRecipeParser.parse(text)
        // Regression: "1.75" lost its "1." to the numbered-step stripper and imported as 75 tbsp.
        #expect(result?.ingredients == ["0.44 cup neutral oil", "1.75 tbsp ghee"])
        #expect(result?.instructions == ["Heat the oil and ghee."])
    }
}
