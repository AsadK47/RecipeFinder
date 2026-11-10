import XCTest
import Testing
@testable import RecipeFinder

final class RecipeModelTests: XCTestCase {

    // MARK: - Ingredient.scaledQuantity

    func testScaledQuantity_factorOne_returnsSameQuantity() {
        XCTAssertEqual(makeIngredient(baseQuantity: 2.0).scaledQuantity(for: 1.0), 2.0, accuracy: 0.001)
    }

    func testScaledQuantity_factorTwo_doublesQuantity() {
        XCTAssertEqual(makeIngredient(baseQuantity: 2.0).scaledQuantity(for: 2.0), 4.0, accuracy: 0.001)
    }

    func testScaledQuantity_fractionalFactor_halvesQuantity() {
        XCTAssertEqual(makeIngredient(baseQuantity: 4.0).scaledQuantity(for: 0.5), 2.0, accuracy: 0.001)
    }

    // MARK: - FractionFormatter.toFraction

    func testToFraction_half_returnsHalfSymbol() {
        XCTAssertEqual(FractionFormatter.toFraction(0.5), "½")
    }

    func testToFraction_quarter_returnsQuarterSymbol() {
        XCTAssertEqual(FractionFormatter.toFraction(0.25), "¼")
    }

    func testToFraction_threeQuarters_returnsThreeQuarterSymbol() {
        XCTAssertEqual(FractionFormatter.toFraction(0.75), "¾")
    }

    func testToFraction_oneAndHalf_returnsMixedNumber() {
        XCTAssertEqual(FractionFormatter.toFraction(1.5), "1½")
    }

    func testToFraction_wholeNumber_returnsNil() {
        XCTAssertNil(FractionFormatter.toFraction(2.0))
    }

    func testToFraction_unknownDecimal_returnsNil() {
        XCTAssertNil(FractionFormatter.toFraction(0.1))
    }

    // MARK: - FractionFormatter.format

    func testFormat_wholeNumber_returnsNoDecimalPoint() {
        XCTAssertEqual(FractionFormatter.format(3.0), "3")
    }

    func testFormat_half_returnsFractionSymbol() {
        XCTAssertEqual(FractionFormatter.format(0.5), "½")
    }

    func testFormat_unknownDecimal_returnsNonEmptyString() {
        XCTAssertFalse(FractionFormatter.format(0.1).isEmpty)
    }

    // MARK: - TimeExtractor.extractMinutes

    func testExtractMinutes_validString_returnsValue() {
        XCTAssertEqual(TimeExtractor.extractMinutes(from: "30 min"), 30)
    }

    func testExtractMinutes_zero_returnsZero() {
        XCTAssertEqual(TimeExtractor.extractMinutes(from: "0 min"), 0)
    }

    func testExtractMinutes_nonNumericString_returnsZero() {
        XCTAssertEqual(TimeExtractor.extractMinutes(from: "N/A"), 0)
    }

    func testExtractMinutes_emptyString_returnsZero() {
        XCTAssertEqual(TimeExtractor.extractMinutes(from: ""), 0)
    }

    // MARK: - IngredientNameFormatter.extractMainName

    func testExtractMainName_noComma_returnsFullName() {
        XCTAssertEqual(IngredientNameFormatter.extractMainName("Chicken Breast"), "Chicken Breast")
    }

    func testExtractMainName_withComma_returnsPartBeforeComma() {
        XCTAssertEqual(IngredientNameFormatter.extractMainName("Onion, diced"), "Onion")
    }

    func testExtractMainName_stripsParentheticalContent() {
        XCTAssertEqual(IngredientNameFormatter.extractMainName("Beef Stew Meat (Cut Into 1 To 2 Inch Cubes)"), "Beef Stew Meat")
    }

    func testExtractMainName_stripsNestedParentheses() {
        XCTAssertEqual(IngredientNameFormatter.extractMainName("Large Yellow Onion (Chopped Or Sliced (1 Large = 2 Small Onions))"), "Large Yellow Onion")
    }

    func testExtractMainName_stripsUnclosedParenthesis() {
        XCTAssertEqual(IngredientNameFormatter.extractMainName("Button Red Chili Peppers (If Using Regular Dried Chilies"), "Button Red Chili Peppers")
    }

    func testExtractMainName_stripsDoubleParentheses() {
        XCTAssertEqual(IngredientNameFormatter.extractMainName("Garlic Cloves ((Leave Whole))"), "Garlic Cloves")
    }

    func testExtractMainName_stripsLeadingRangeDash() {
        XCTAssertEqual(IngredientNameFormatter.extractMainName("- 1 Cup Plain Whole Milk Yogurt"), "Plain Whole Milk Yogurt")
    }

    func testExtractMainName_stripsLeadingQuantityAndUnit() {
        XCTAssertEqual(IngredientNameFormatter.extractMainName("1/4 Tsp Kosher Salt"), "Kosher Salt")
    }

    // MARK: - IngredientNameFormatter.extractPreparationNotes

    func testExtractPreparationNotes_noNotes_returnsNil() {
        XCTAssertNil(IngredientNameFormatter.extractPreparationNotes("Chicken Breast"))
    }

    func testExtractPreparationNotes_withCommaNotation_containsNote() {
        let result = IngredientNameFormatter.extractPreparationNotes("Onion, diced")
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("diced"))
    }

    // MARK: - DietaryInfo.activeTags

    func testActiveTags_defaultInit_isEmpty() {
        XCTAssertTrue(DietaryInfo().activeTags.isEmpty)
    }

    func testActiveTags_veganSet_containsVegan() {
        XCTAssertTrue(DietaryInfo(isVegan: true).activeTags.contains("Vegan"))
    }

    func testActiveTags_multipleFlags_returnsAllActive() {
        let info = DietaryInfo(isVegetarian: true, isGlutenFree: true)
        XCTAssertEqual(info.activeTags.count, 2)
        XCTAssertTrue(info.activeTags.contains("Vegetarian"))
        XCTAssertTrue(info.activeTags.contains("Gluten-Free"))
    }

    func testActiveTags_allFlags_returnsSevenTags() {
        let info = DietaryInfo(
            isVegetarian: true, isVegan: true, isGlutenFree: true,
            isDairyFree: true, isNutFree: true, isLowCarb: true, isKeto: true
        )
        XCTAssertEqual(info.activeTags.count, 7)
    }

    // MARK: - RecipeModel.scaleFactor

    func testScaleFactor_currentEqualsBase_returnsOne() {
        XCTAssertEqual(makeRecipe(baseServings: 4, currentServings: 4).scaleFactor, 1.0, accuracy: 0.001)
    }

    func testScaleFactor_currentDoubleBase_returnsTwo() {
        XCTAssertEqual(makeRecipe(baseServings: 4, currentServings: 8).scaleFactor, 2.0, accuracy: 0.001)
    }

    func testScaleFactor_currentHalfBase_returnsHalf() {
        XCTAssertEqual(makeRecipe(baseServings: 4, currentServings: 2).scaleFactor, 0.5, accuracy: 0.001)
    }

    // MARK: - RecipeModel.totalTime

    func testTotalTime_addsPrepAndCookMinutes() {
        XCTAssertEqual(makeRecipe(prepTime: "15 min", cookingTime: "30 min").totalTime, "45 minutes")
    }

    func testTotalTime_zeroCookTime_returnsPrepOnly() {
        XCTAssertEqual(makeRecipe(prepTime: "10 min", cookingTime: "0 min").totalTime, "10 minutes")
    }

    func testTotalTime_bothZero_returnsZeroMinutes() {
        XCTAssertEqual(makeRecipe(prepTime: "0 min", cookingTime: "0 min").totalTime, "0 minutes")
    }

    // MARK: - RecipeModel.containsIngredient

    func testContainsIngredient_exactMatch_returnsTrue() {
        let recipe = makeRecipe(ingredients: [makeIngredient(name: "Garlic")])
        XCTAssertTrue(recipe.containsIngredient("garlic"))
    }

    func testContainsIngredient_partialMatch_returnsTrue() {
        let recipe = makeRecipe(ingredients: [makeIngredient(name: "Chicken Breast")])
        XCTAssertTrue(recipe.containsIngredient("chicken"))
    }

    func testContainsIngredient_noMatch_returnsFalse() {
        let recipe = makeRecipe(ingredients: [makeIngredient(name: "Garlic")])
        XCTAssertFalse(recipe.containsIngredient("onion"))
    }

    func testContainsIngredient_emptyIngredients_returnsFalse() {
        XCTAssertFalse(makeRecipe(ingredients: []).containsIngredient("garlic"))
    }

    // MARK: - RecipeModel.ingredientMatchPercentage

    func testIngredientMatchPercentage_emptyIngredients_returnsZero() {
        XCTAssertEqual(makeRecipe(ingredients: []).ingredientMatchPercentage(availableIngredients: ["garlic"]), 0.0, accuracy: 0.001)
    }

    func testIngredientMatchPercentage_allMatch_returnsOne() {
        let recipe = makeRecipe(ingredients: [makeIngredient(name: "Garlic"), makeIngredient(name: "Onion")])
        XCTAssertEqual(recipe.ingredientMatchPercentage(availableIngredients: ["garlic", "onion"]), 1.0, accuracy: 0.001)
    }

    func testIngredientMatchPercentage_noneMatch_returnsZero() {
        let recipe = makeRecipe(ingredients: [makeIngredient(name: "Garlic")])
        XCTAssertEqual(recipe.ingredientMatchPercentage(availableIngredients: []), 0.0, accuracy: 0.001)
    }

    func testIngredientMatchPercentage_halfMatch_returnsHalf() {
        let recipe = makeRecipe(ingredients: [makeIngredient(name: "Garlic"), makeIngredient(name: "Onion")])
        XCTAssertEqual(recipe.ingredientMatchPercentage(availableIngredients: ["garlic"]), 0.5, accuracy: 0.001)
    }

    // MARK: - RecipeModel.missingIngredients

    func testMissingIngredients_noneAvailable_returnsAll() {
        let recipe = makeRecipe(ingredients: [makeIngredient(name: "Garlic"), makeIngredient(name: "Onion")])
        XCTAssertEqual(recipe.missingIngredients(from: []).count, 2)
    }

    func testMissingIngredients_allAvailable_returnsEmpty() {
        let recipe = makeRecipe(ingredients: [makeIngredient(name: "Garlic")])
        XCTAssertTrue(recipe.missingIngredients(from: ["garlic"]).isEmpty)
    }

    func testMissingIngredients_partiallyAvailable_returnsOnlyMissing() {
        let recipe = makeRecipe(ingredients: [makeIngredient(name: "Garlic"), makeIngredient(name: "Onion")])
        let missing = recipe.missingIngredients(from: ["garlic"])
        XCTAssertEqual(missing.count, 1)
        XCTAssertEqual(missing.first?.name, "Onion")
    }

    // MARK: - RecipeModel.shareText

    func testShareText_containsRecipeName() {
        XCTAssertTrue(makeRecipe().shareText.contains("Test Recipe"))
    }

    func testShareText_containsCategoryAndDifficulty() {
        let text = makeRecipe().shareText
        XCTAssertTrue(text.contains("Test • Easy"))
    }

    func testShareText_containsTimingsAndServings() {
        let text = makeRecipe().shareText
        XCTAssertTrue(text.contains("Prep: 10 min"))
        XCTAssertTrue(text.contains("Cook: 20 min"))
        XCTAssertTrue(text.contains("Serves: 4"))
    }

    func testShareText_listsIngredientsWithQuantities() {
        let recipe = makeRecipe(ingredients: [makeIngredient(baseQuantity: 2.0, unit: "cups", name: "Flour")])
        XCTAssertTrue(recipe.shareText.contains("• 2 cups Flour"))
    }

    func testShareText_formatsFractionalQuantities() {
        let recipe = makeRecipe(ingredients: [makeIngredient(baseQuantity: 0.5, unit: "tsp", name: "Salt")])
        XCTAssertTrue(recipe.shareText.contains("• ½ tsp Salt"))
    }

    func testShareText_omitsUnitlessIngredientDoubleSpace() {
        let recipe = makeRecipe(ingredients: [makeIngredient(baseQuantity: 2.0, unit: "", name: "Eggs")])
        XCTAssertTrue(recipe.shareText.contains("• 2 Eggs"))
    }

    func testShareText_numbersInstructions() {
        let recipe = RecipeModel(
            name: "Numbered",
            category: "Test",
            difficulty: "Easy",
            prepTime: "5 min",
            cookingTime: "10 min",
            baseServings: 2,
            ingredients: [],
            prePrepInstructions: ["Soak the rice"],
            instructions: ["Boil water", "Add rice"],
            notes: ""
        )
        let text = recipe.shareText
        XCTAssertTrue(text.contains("Preparation:\n1. Soak the rice"))
        XCTAssertTrue(text.contains("Instructions:\n1. Boil water\n2. Add rice"))
    }

    func testShareText_emptyRecipe_omitsEmptySections() {
        let text = makeRecipe().shareText
        XCTAssertFalse(text.contains("Ingredients:"))
        XCTAssertFalse(text.contains("Instructions:"))
        XCTAssertFalse(text.contains("Notes:"))
    }

    func testShareText_includesNotesWhenPresent() {
        let recipe = RecipeModel(
            name: "Noted",
            category: "Test",
            difficulty: "Easy",
            prepTime: "5 min",
            cookingTime: "10 min",
            baseServings: 2,
            ingredients: [],
            prePrepInstructions: [],
            instructions: [],
            notes: "Best served warm"
        )
        XCTAssertTrue(recipe.shareText.contains("Notes: Best served warm"))
    }

    // MARK: - Scale factor safety (regression: zero base servings)

    func testScaleFactorWithZeroBaseServingsFallsBackToOne() {
        let recipe = makeRecipe(baseServings: 0, currentServings: 4)
        XCTAssertEqual(recipe.scaleFactor, 1.0)
    }

    func testScaledQuantityWithZeroBaseServingsDoesNotTrap() {
        let recipe = makeRecipe(
            baseServings: 0,
            currentServings: 4,
            ingredients: [makeIngredient(baseQuantity: 2.5)]
        )
        // Rendering the detail view formats every ingredient quantity; with an
        // unguarded scale factor this trapped in FractionFormatter (Int(inf)).
        let formatted = FractionFormatter.format(recipe.ingredients[0].scaledQuantity(for: recipe.scaleFactor))
        XCTAssertFalse(formatted.isEmpty)
    }

    // MARK: - FractionFormatter non-finite input

    func testFormatOfNonFiniteValuesDoesNotTrap() {
        XCTAssertEqual(FractionFormatter.format(.infinity), "0")
        XCTAssertEqual(FractionFormatter.format(-.infinity), "0")
        XCTAssertEqual(FractionFormatter.format(.nan), "0")
    }

    func testToFractionOfNonFiniteValueReturnsNil() {
        XCTAssertNil(FractionFormatter.toFraction(.infinity))
        XCTAssertNil(FractionFormatter.toFraction(.nan))
    }

    // MARK: - Helpers

    private func makeIngredient(
        baseQuantity: Double = 1.0,
        unit: String = "cup",
        name: String = "Flour"
    ) -> Ingredient {
        Ingredient(baseQuantity: baseQuantity, unit: unit, name: name)
    }

    // MARK: - importedFromURL

    func testImportedFromURL_httpsURL_parsesCorrectly() {
        let recipe = makeRecipe(notes: "Imported · 14 Sep 2026\nhttps://example.com/recipe")
        XCTAssertEqual(recipe.importedFromURL, URL(string: "https://example.com/recipe"))
    }

    func testImportedFromURL_withDescription_parsesLastLineURL() {
        let recipe = makeRecipe(notes: "Great flavour.\n\nImported · 14 Sep 2026\nhttps://food.com/pasta")
        XCTAssertEqual(recipe.importedFromURL, URL(string: "https://food.com/pasta"))
    }

    func testImportedFromURL_noURL_returnsNil() {
        let recipe = makeRecipe(notes: "Just a personal note")
        XCTAssertNil(recipe.importedFromURL)
    }

    func testImportedFromURL_emptyNotes_returnsNil() {
        let recipe = makeRecipe(notes: "")
        XCTAssertNil(recipe.importedFromURL)
    }

    // MARK: - notesForDisplay

    func testNotesForDisplay_stripsImportFooter() {
        let recipe = makeRecipe(notes: "Great flavour.\n\nImported · 14 Sep 2026\nhttps://example.com/recipe")
        XCTAssertEqual(recipe.notesForDisplay, "Great flavour.")
    }

    func testNotesForDisplay_onlyImportFooter_returnsEmpty() {
        let recipe = makeRecipe(notes: "Imported · 14 Sep 2026\nhttps://example.com/recipe")
        XCTAssertEqual(recipe.notesForDisplay, "")
    }

    func testNotesForDisplay_noURL_returnsFullNotes() {
        let recipe = makeRecipe(notes: "Just a personal note")
        XCTAssertEqual(recipe.notesForDisplay, "Just a personal note")
    }

    func testNotesForDisplay_emptyNotes_returnsEmpty() {
        let recipe = makeRecipe(notes: "")
        XCTAssertEqual(recipe.notesForDisplay, "")
    }

    private func makeRecipe(
        baseServings: Int = 4,
        currentServings: Int = 4,
        prepTime: String = "10 min",
        cookingTime: String = "20 min",
        ingredients: [Ingredient] = [],
        notes: String = ""
    ) -> RecipeModel {
        RecipeModel(
            name: "Test Recipe",
            category: "Test",
            difficulty: "Easy",
            prepTime: prepTime,
            cookingTime: cookingTime,
            baseServings: baseServings,
            currentServings: currentServings,
            ingredients: ingredients,
            prePrepInstructions: [],
            instructions: [],
            notes: notes
        )
    }
}

@Suite struct RecipeCookedTodayTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        return calendar
    }()
    private let now = Date(timeIntervalSince1970: 1_800_000_000)   // fixed instant, UTC midday-ish

    private func recipe(lastCookedAt: Date?) -> RecipeModel {
        var recipe = RecipeModel(
            name: "Toast", category: "Breakfast", difficulty: "Basic",
            prepTime: "5 minutes", cookingTime: "5 minutes", baseServings: 1,
            ingredients: [], prePrepInstructions: [], instructions: ["Toast"], notes: ""
        )
        recipe.lastCookedAt = lastCookedAt
        return recipe
    }

    @Test("Never cooked ⇒ not cooked today")
    func neverCooked() {
        #expect(!recipe(lastCookedAt: nil).wasCookedToday(now: now, calendar: calendar))
    }

    @Test("Cooked earlier the same day ⇒ cooked today (Mark as Cooked disabled)")
    func cookedSameDay() {
        #expect(recipe(lastCookedAt: now.addingTimeInterval(-60)).wasCookedToday(now: now, calendar: calendar))
    }

    @Test("Cooked yesterday ⇒ not cooked today")
    func cookedYesterday() {
        #expect(!recipe(lastCookedAt: now.addingTimeInterval(-86_400)).wasCookedToday(now: now, calendar: calendar))
    }
}

@Suite("RecipeModel display & source rules")
struct RecipeModelDisplayTests {
    private func recipe(prep: String = "10 min", cook: String = "20 min", notes: String = "") -> RecipeModel {
        RecipeModel(name: "Test", category: "Main", difficulty: "Basic", prepTime: prep, cookingTime: cook,
                    baseServings: 2, ingredients: [], prePrepInstructions: [], instructions: [], notes: notes)
    }

    @Test("Total time over an hour reads as hours and minutes (was \"585 minutes\")")
    func totalTimeOverAnHour() {
        #expect(recipe(prep: "45 min", cook: "540 min").totalTime == "9 hr 45 min")
        #expect(recipe(prep: "30 min", cook: "30 min").totalTime == "1 hr")
    }

    @Test("Prep and cook labels use the same hours format as the total")
    func prepAndCookDisplay() {
        let r = recipe(prep: "10 min", cook: "575 min")
        #expect(r.cookTimeDisplay == "9 hr 35 min")
        #expect(r.prepTimeDisplay == "10 minutes")
    }

    @Test("Unknown times read \"Not set\" on the recipe screen, not a fake 0 minutes")
    func unknownTimeNotSet() {
        #expect(recipe(prep: "0 minutes", cook: "0 minutes").prepTimeDisplay == "Not set")
    }

    @Test("No known time means no clock on the card (imports without timings)")
    func hasTotalTime() {
        #expect(!recipe(prep: "0 minutes", cook: "0 minutes").hasTotalTime)
        #expect(recipe(prep: "0 minutes", cook: "20 minutes").hasTotalTime)
    }

    @Test("Only the user's own URL imports re-check their source on open")
    func autoRefreshOnlyForUserImports() {
        var imported = recipe(notes: "Imported · 14 Sep 2026\nhttps://example.com/recipe")
        #expect(imported.shouldAutoRefreshFromSource)
        // Bundled recipes carry a source link for credit/photos but must not hit the site on every open.
        imported.isSampleRecipe = true
        #expect(!imported.shouldAutoRefreshFromSource)
        #expect(!recipe(notes: "Just a personal note").shouldAutoRefreshFromSource)
    }
}

// MARK: - Quick-scale servings

@Suite("Quick-scale servings")
struct QuickScaleServingsTests {

    private func recipe(baseServings: Int) -> RecipeModel {
        RecipeModel(
            name: "Toast", category: "Test", difficulty: "Basic", prepTime: "5 min", cookingTime: "5 min",
            baseServings: baseServings, ingredients: [], prePrepInstructions: [], instructions: [], notes: ""
        )
    }

    @Test(arguments: [(1, 0.5, 1), (4, 0.5, 2), (3, 0.5, 2), (2, 3.0, 6), (0, 2.0, 1)])
    func scalesBaseServingsNeverBelowOne(base: Int, multiplier: Double, expected: Int) {
        #expect(recipe(baseServings: base).servings(scaledBy: multiplier) == expected)
    }
}
