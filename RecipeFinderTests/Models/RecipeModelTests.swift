import XCTest
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

    // MARK: - Helpers

    private func makeIngredient(
        baseQuantity: Double = 1.0,
        unit: String = "cup",
        name: String = "Flour"
    ) -> Ingredient {
        Ingredient(baseQuantity: baseQuantity, unit: unit, name: name)
    }

    private func makeRecipe(
        baseServings: Int = 4,
        currentServings: Int = 4,
        prepTime: String = "10 min",
        cookingTime: String = "20 min",
        ingredients: [Ingredient] = []
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
            notes: ""
        )
    }
}
