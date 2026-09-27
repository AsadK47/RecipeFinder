import Testing
@testable import RecipeFinder

/// OCR-specific parser improvements: ALL-CAPS title normalisation, wrapped-title merging, hour-denominated time extraction, and punctuation-less numbered steps classified as instructions.
@Suite struct TextRecipeParserOCRTests {

    // MARK: - Title: ALL CAPS → title case

    @Test func allCapsTitleConvertsToTitleCase() {
        let text = """
        CHICKEN TIKKA MASALA
        Ingredients
        - 2 chicken breasts
        - 1 onion
        Method
        1. Marinate and cook the chicken.
        """
        let result = TextRecipeParser.parse(text)
        #expect(result?.name == "Chicken Tikka Masala")
    }

    // MARK: - Title: wrapped OCR lines

    @Test func wrappedAllCapsTitleIsMerged() {
        // Vision OCR may split "CHICKEN TIKKA MASALA" into two observations.
        let text = """
        CHICKEN TIKKA
        MASALA
        Ingredients
        - 2 chicken breasts
        - 1 onion
        Method
        1. Cook the chicken.
        """
        let result = TextRecipeParser.parse(text)
        #expect(result?.name == "Chicken Tikka Masala")
    }

    @Test func wrappedLineWithDigitIsNotMergedIntoTitle() {
        // Second line has a digit → it's an ingredient, not a title continuation.
        let text = """
        SOUP
        2 carrots, sliced
        1 potato
        Ingredients
        - 1 onion
        Method
        1. Simmer everything for 20 minutes.
        """
        let result = TextRecipeParser.parse(text)
        // Title must not include the ingredient line.
        #expect(result?.name == "Soup")
    }

    // MARK: - Time extraction: hour units

    @Test(arguments: [
        ("Prep time: 1 hour\nCook time: 2 hours", 60, 120),
        ("Prep time: 1 hr\nCook time: 90 minutes", 60, 90),
        ("Prep 30 min\nCook 1 hour", 30, 60),
    ])
    func hourAwareTimeExtraction(text suffix: String, expectedPrep: Int, expectedCook: Int) {
        let full = """
        Roast Chicken
        Ingredients
        - 1 whole chicken
        Method
        1. Roast until cooked through.
        \(suffix)
        """
        let result = TextRecipeParser.parse(full)
        #expect(result?.prepTime == expectedPrep)
        #expect(result?.cookTime == expectedCook)
    }

    // MARK: - Numbered step without period/paren

    @Test func numberedStepWithoutPunctuationIsInstruction() {
        // "1 Heat…" and "2 Beat…" — OCR often drops the period.
        let text = """
        Omelette
        1 egg
        1 tbsp butter
        1 Heat a pan over medium heat.
        2 Beat the egg and pour in.
        """
        let result = TextRecipeParser.parse(text)
        #expect(result?.ingredients == ["1 egg", "1 tbsp butter"])
        #expect(result?.instructions?.count == 2)
    }

    @Test func lowercaseAfterDigitRemainsIngredient() {
        // "2 cups flour" must still be an ingredient, not a numbered step.
        let text = """
        Pancakes
        2 cups flour
        1 cup milk
        1 egg
        1. Mix all ingredients together.
        2. Cook on a hot griddle.
        """
        let result = TextRecipeParser.parse(text)
        #expect(result?.ingredients?.contains("2 cups flour") == true)
        #expect(result?.ingredients?.contains("1 cup milk") == true)
    }
}
