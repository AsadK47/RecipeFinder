import XCTest
@testable import RecipeFinder

final class RecipeImportBuilderTests: XCTestCase {

    private let builder = RecipeImportBuilder()

    // MARK: - Helpers

    private func makeData(
        name: String = "Test Recipe",
        description: String? = nil,
        rawIngredients: [String] = [],
        instructions: [String] = ["Cook it."],
        prepTimeMinutes: Int? = nil,
        cookTimeMinutes: Int? = nil,
        servings: Int? = nil,
        difficulty: String? = nil,
        category: String? = nil,
        cuisine: String? = nil,
        imageURL: String? = nil
    ) -> RecipeImporter.ExtractedRecipeData {
        RecipeImporter.ExtractedRecipeData(
            name: name,
            description: description,
            matchedIngredients: [],
            rawIngredients: rawIngredients,
            rawText: "",
            instructions: instructions,
            sourceURL: URL(string: "https://example.com/recipe")!,
            cookTimeMinutes: cookTimeMinutes,
            prepTimeMinutes: prepTimeMinutes,
            servings: servings,
            difficulty: difficulty,
            category: category,
            cuisine: cuisine,
            imageURL: imageURL
        )
    }

    // MARK: - build(from:) tests

    func testBuild_setsName() {
        let data = makeData(name: "Pasta Bake")
        let recipe = builder.build(from: data)
        XCTAssertEqual(recipe.name, "Pasta Bake")
    }

    func testBuild_usesDefaultCategoryWhenNil() {
        let data = makeData(category: nil)
        let recipe = builder.build(from: data)
        XCTAssertEqual(recipe.category, "Main")
    }

    func testBuild_usesProvidedCategory() {
        let data = makeData(category: "Dessert")
        let recipe = builder.build(from: data)
        XCTAssertEqual(recipe.category, "Dessert")
    }

    func testBuild_usesDefaultDifficultyWhenNil() {
        let data = makeData(difficulty: nil)
        let recipe = builder.build(from: data)
        XCTAssertEqual(recipe.difficulty, "Medium")
    }

    func testBuild_usesDefaultServingsWhenNil() {
        let data = makeData(servings: nil)
        let recipe = builder.build(from: data)
        XCTAssertEqual(recipe.baseServings, 4)
    }

    func testBuild_usesProvidedServings() {
        let data = makeData(servings: 6)
        let recipe = builder.build(from: data)
        XCTAssertEqual(recipe.baseServings, 6)
    }

    func testBuild_formatsPrepTime() {
        let data = makeData(prepTimeMinutes: 15)
        let recipe = builder.build(from: data)
        XCTAssertEqual(recipe.prepTime, "15 minutes")
    }

    func testBuild_formatsCookTime() {
        let data = makeData(cookTimeMinutes: 30)
        let recipe = builder.build(from: data)
        XCTAssertEqual(recipe.cookingTime, "30 minutes")
    }

    func testBuild_defaultsTimesToZeroWhenNil() {
        let data = makeData(prepTimeMinutes: nil, cookTimeMinutes: nil)
        let recipe = builder.build(from: data)
        XCTAssertEqual(recipe.prepTime, "0 minutes")
        XCTAssertEqual(recipe.cookingTime, "0 minutes")
    }

    func testBuild_setsImageName() {
        let data = makeData(imageURL: "https://cdn.example.com/photo.jpg")
        let recipe = builder.build(from: data)
        XCTAssertEqual(recipe.imageName, "https://cdn.example.com/photo.jpg")
    }

    func testBuild_nilImageNameWhenNoURL() {
        let data = makeData(imageURL: nil)
        let recipe = builder.build(from: data)
        XCTAssertNil(recipe.imageName)
    }

    func testBuild_fallbackIngredientWhenListEmpty() {
        let data = makeData(rawIngredients: [])
        let recipe = builder.build(from: data)
        XCTAssertEqual(recipe.ingredients.count, 1)
        XCTAssertEqual(recipe.ingredients[0].name, "See recipe")
    }

    func testBuild_filtersBlankInstructions() {
        let data = makeData(instructions: ["Step 1.", "  ", "Step 2."])
        let recipe = builder.build(from: data)
        XCTAssertEqual(recipe.instructions, ["Step 1.", "Step 2."])
    }

    func testBuild_isNotFavoriteByDefault() {
        let recipe = builder.build(from: makeData())
        XCTAssertFalse(recipe.isFavorite)
    }

    // MARK: - parseIngredient tests

    func testParseIngredient_simpleQuantityUnitName() {
        let ingredient = builder.parseIngredient("2 cups flour")
        XCTAssertEqual(ingredient.baseQuantity, 2.0)
        XCTAssertEqual(ingredient.unit.lowercased(), "cups")
        XCTAssertEqual(ingredient.name.lowercased(), "flour")
    }

    func testParseIngredient_fractionQuantity() {
        let ingredient = builder.parseIngredient("1/4 tsp kosher salt")
        XCTAssertEqual(ingredient.unit.lowercased(), "tsp")
        XCTAssertEqual(ingredient.name.lowercased(), "kosher salt")
    }

    func testParseIngredient_rangeQuantityTakesUpperBound() {
        let ingredient = builder.parseIngredient("3/4 – 1 cup yogurt")
        XCTAssertEqual(ingredient.baseQuantity, 1.0)
        XCTAssertEqual(ingredient.unit.lowercased(), "cup")
        XCTAssertEqual(ingredient.name.lowercased(), "yogurt")
    }

    func testParseIngredient_noQuantityOrUnit_usesFullStringAsName() {
        let ingredient = builder.parseIngredient("salt and pepper to taste")
        XCTAssertEqual(ingredient.name.lowercased(), "salt and pepper to taste")
    }

    func testParseIngredient_stripsCommaAndRemainder() {
        let ingredient = builder.parseIngredient("2 tbsp olive oil, extra virgin")
        XCTAssertEqual(ingredient.unit.lowercased(), "tbsp")
        XCTAssertEqual(ingredient.name.lowercased(), "olive oil")
    }

    func testParseIngredient_inchUnit() {
        let ingredient = builder.parseIngredient("1 inch ginger")
        XCTAssertEqual(ingredient.unit.lowercased(), "inch")
        XCTAssertEqual(ingredient.name.lowercased(), "ginger")
    }

    func testParseIngredient_unicodeFractionQuarter() {
        let ingredient = builder.parseIngredient("¼ cup neutral oil")
        XCTAssertEqual(ingredient.baseQuantity, 0.25, accuracy: 0.01)
        XCTAssertEqual(ingredient.unit.lowercased(), "cup")
        XCTAssertEqual(ingredient.name.lowercased(), "neutral oil")
    }

    func testParseIngredient_unicodeFractionHalf() {
        let ingredient = builder.parseIngredient("½ tsp salt")
        XCTAssertEqual(ingredient.baseQuantity, 0.5, accuracy: 0.01)
        XCTAssertEqual(ingredient.unit.lowercased(), "tsp")
    }

    func testParseIngredient_unicodeFractionThreeQuarters() {
        let ingredient = builder.parseIngredient("¾ cup yogurt")
        XCTAssertEqual(ingredient.baseQuantity, 0.75, accuracy: 0.01)
        XCTAssertEqual(ingredient.unit.lowercased(), "cup")
    }

    func testParseIngredient_gUnit() {
        let ingredient = builder.parseIngredient("200g spaghetti")
        XCTAssertEqual(ingredient.name.lowercased(), "spaghetti")
    }

    // MARK: - buildNotes tests

    func testBuildNotes_includesDescription() {
        let data = makeData(description: "A classic Italian dish.")
        let notes = builder.buildNotes(from: data)
        XCTAssertTrue(notes.contains("A classic Italian dish."))
    }

    func testBuildNotes_includesCuisine() {
        let data = makeData(cuisine: "Italian")
        let notes = builder.buildNotes(from: data)
        XCTAssertTrue(notes.contains("Cuisine: Italian"))
    }

    func testBuildNotes_includesSourceDomain() {
        let notes = builder.buildNotes(from: makeData())
        XCTAssertTrue(notes.contains("Imported from example.com"))
    }

    func testBuildNotes_stripsWWWFromDomain() {
        let data = RecipeImporter.ExtractedRecipeData(
            name: "Test", description: nil,
            matchedIngredients: [], rawIngredients: [], rawText: "",
            instructions: [],
            sourceURL: URL(string: "https://www.foodnetwork.com/recipe")!,
            cookTimeMinutes: nil, prepTimeMinutes: nil,
            servings: nil, difficulty: nil, category: nil, cuisine: nil, imageURL: nil
        )
        let notes = builder.buildNotes(from: data)
        XCTAssertTrue(notes.contains("Imported from foodnetwork.com"))
        XCTAssertFalse(notes.contains("www.foodnetwork.com"))
    }

    func testBuildNotes_domainAndDateOnSingleLine() {
        // Regression: previously "teaforturmeric.com" split across two lines
        let data = RecipeImporter.ExtractedRecipeData(
            name: "Curry", description: nil,
            matchedIngredients: [], rawIngredients: [], rawText: "",
            instructions: [],
            sourceURL: URL(string: "https://teaforturmeric.com/beef-curry")!,
            cookTimeMinutes: nil, prepTimeMinutes: nil,
            servings: nil, difficulty: nil, category: nil, cuisine: nil, imageURL: nil
        )
        let notes = builder.buildNotes(from: data)
        let lines = notes.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        // The domain line must appear on a single line and include ".com"
        XCTAssertTrue(lines.contains { $0.contains("teaforturmeric.com") })
        // No line should be just "com"
        XCTAssertFalse(lines.contains { $0.trimmingCharacters(in: .whitespaces) == "com" })
    }

    func testBuildNotes_noPairingSuggestions() {
        let data = makeData(category: "Main")
        let notes = builder.buildNotes(from: data)
        XCTAssertFalse(notes.contains("Perfect for pairing"))
        XCTAssertFalse(notes.contains("naan"))
    }
}
