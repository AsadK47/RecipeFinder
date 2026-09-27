import Testing
@testable import RecipeFinder

/// Real social-caption cases for `TextRecipeParser` (emoji headers, emoji/symbol bullets, unnumbered imperative steps) — the shapes that matter most on devices without the on-device model.
@Suite struct TextRecipeParserCaptionTests {

    @Test func parsesEmojiHeadersAndBullets() {
        let text = """
        ✨ One-Pan Lemon Chicken ✨
        Serves 4 🍽

        INGREDIENTS 👇
        🍗 4 chicken thighs
        🧄 3 cloves garlic, minced
        🍋 1 lemon, juiced

        METHOD 👩‍🍳
        1. Sear the chicken skin-side down.
        2. Add garlic and lemon, then bake.
        """
        let result = TextRecipeParser.parse(text)
        #expect(result?.name == "One-Pan Lemon Chicken")
        #expect(result?.servings == 4)
        #expect(result?.ingredients == ["4 chicken thighs", "3 cloves garlic, minced", "1 lemon, juiced"])
        #expect(result?.instructions?.count == 2)
    }

    @Test func parsesHeaderlessUnnumberedImperativeSteps() {
        let text = """
        Garlic Butter Shrimp
        1 lb shrimp
        3 tbsp butter
        4 cloves garlic
        Melt the butter in a pan.
        Add the garlic and cook until fragrant.
        Toss in the shrimp and cook for 3 minutes.
        """
        let result = TextRecipeParser.parse(text)
        #expect(result?.ingredients?.count == 3)
        #expect(result?.instructions?.count == 3)
    }

    @Test func stripsEmojiBulletsInHeaderlessIngredients() {
        let text = """
        Quick Guac
        🥑 2 ripe avocados
        🧅 1/2 red onion, diced
        🍋 juice of 1 lime
        Mash the avocados until smooth.
        Stir through the onion and lime.
        """
        let result = TextRecipeParser.parse(text)
        #expect(result?.ingredients == ["2 ripe avocados", "1/2 red onion, diced", "juice of 1 lime"])
        #expect(result?.instructions?.count == 2)
    }

    @Test func toleratesLowercaseAndColonlessHeaders() {
        let text = """
        Overnight Oats
        what you need
        1/2 cup oats
        1 cup milk
        method
        Combine everything in a jar.
        Refrigerate overnight.
        """
        let result = TextRecipeParser.parse(text)
        #expect(result?.ingredients == ["1/2 cup oats", "1 cup milk"])
        #expect(result?.instructions?.count == 2)
    }
}
