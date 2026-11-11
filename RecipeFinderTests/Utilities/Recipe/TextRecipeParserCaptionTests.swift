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

    @Test func dropsPageFurnitureAndKeepsNotesSeparate() {
        let text = """
        Garlic Butter Rice
        Jump to Recipe
        4.9 from 88 votes
        Ingredients
        US Customary
        1x2x3x
        1 cup rice
        2 tbsp butter
        Instructions
        Rinse the rice well.
        Advertisement
        Cook with the butter and 2 cups water for 15 minutes.
        Notes
        Leftovers keep for 2 days.
        Nutrition
        Calories: 210kcal
        #rice #easy
        """
        let result = TextRecipeParser.parse(text)
        #expect(result?.ingredients == ["1 cup rice", "2 tbsp butter"])
        #expect(result?.instructions == ["Rinse the rice well.", "Cook with the butter and 2 cups water for 15 minutes."])
        #expect(result?.notes == "Leftovers keep for 2 days.")
    }

    @Test func keycapAndBulletStepsStaySeparate() {
        let text = """
        Quick Oats
        Ingredients
        1/2 cup oats
        1 cup milk
        Method:
        1️⃣ Warm the milk.
        2️⃣ Stir in the oats.
        Steps:
        - Top with fruit.
        - Serve warm.
        """
        let result = TextRecipeParser.parse(text)
        #expect(result?.instructions == ["Warm the milk.", "Stir in the oats.", "Top with fruit.", "Serve warm."])
    }

    @Test func firstStepEndsIngredientsWhenThereIsNoMethodHeader() {
        let text = """
        Simple Pancakes
        FOR THE BATTER
        1 cup flour
        1 egg
        FOR THE TOPPING
        2 tbsp maple syrup
        ASSEMBLE:
        Whisk the flour and egg into a smooth batter.
        Fry spoonfuls in a hot pan until golden.
        """
        let result = TextRecipeParser.parse(text)
        // Group headers stay as "Title:" lines so the editor files each ingredient under its group.
        #expect(result?.ingredients == ["For the batter:", "1 cup flour", "1 egg", "For the topping:", "2 tbsp maple syrup"])
        #expect(result?.instructions?.count == 2)
    }

    @Test func countedTitleIsKept() {
        let text = """
        15 minute garlic pasta
        Ingredients
        200g spaghetti
        Method
        Boil the pasta.
        """
        #expect(TextRecipeParser.parse(text)?.name == "15 minute garlic pasta")
    }
}
