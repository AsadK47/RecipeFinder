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
