import Testing
import Foundation
@testable import RecipeFinder

/// Integration across the wizard → persistence seam: `RecipeWizardBuilder.assemble`
/// produces a `RecipeModel` that is saved to the Core Data store and fetched back
/// with every field intact. This guards the handoff between the wizard layer and
/// the store so regressions in field mapping or Core Data encoding are caught here
/// rather than at runtime.
@MainActor
@Suite struct RecipeWizardPersistenceTests {

    private func makeController() -> PersistenceController {
        let controller = PersistenceController(inMemory: true, userID: { "test-user" })
        #expect(controller.isStoreLoaded)
        return controller
    }

    private func ingredient(_ qty: String, _ unit: String, _ name: String) -> RecipeWizardView.IngredientItem {
        RecipeWizardView.IngredientItem(quantity: qty, unit: unit, name: name)
    }

    private func step(_ text: String) -> EditableStep { EditableStep(text: text) }

    // MARK: - Full wizard round-trip

    @Test func wizardAssemble_savesAndFetchesAllFields() throws {
        let controller = makeController()
        let id = UUID()

        let built = RecipeWizardBuilder.assemble(
            recipeId: id,
            name: "Classic Pancakes",
            category: "Breakfast",
            difficulty: "Basic",
            prepTime: 10,
            cookTime: 20,
            servings: 4,
            ingredientItems: [
                ingredient("2", "cups", "flour"),
                ingredient("1", "tsp",  "salt"),
                ingredient("3", "",     "eggs"),
            ],
            prePrepSteps: [step("Sift the flour"), step("Crack eggs into bowl")],
            mainInstructions: [step("Mix dry ingredients"), step("Add eggs"), step("Cook on medium heat")],
            notes: "Serve with maple syrup",
            imageReference: nil,
            isFavorite: true
        )

        controller.saveRecipeModel(built)
        let recipes = controller.fetchRecipes()

        #expect(recipes.count == 1)
        let saved = try #require(recipes.first)
        #expect(saved.id == id)
        #expect(saved.name == "Classic Pancakes")
        #expect(saved.category == "Breakfast")
        #expect(saved.difficulty == "Basic")
        #expect(saved.prepTime == "10 minutes")
        #expect(saved.cookingTime == "20 minutes")
        #expect(saved.baseServings == 4)
        #expect(saved.ingredients.count == 3)
        // Ingredient.init capitalises names; assert the stored form.
        #expect(Set(saved.ingredients.map(\.name)) == ["Flour", "Salt", "Eggs"])
        #expect(saved.prePrepInstructions == ["Sift the flour", "Crack eggs into bowl"])
        #expect(saved.instructions == ["Mix dry ingredients", "Add eggs", "Cook on medium heat"])
        #expect(saved.notes == "Serve with maple syrup")
        #expect(saved.isFavorite == true)
    }

    // MARK: - Blank step filtering survives the round-trip

    @Test func blankPrePrepSteps_areOmittedInStore() throws {
        let controller = makeController()

        let built = RecipeWizardBuilder.assemble(
            recipeId: UUID(),
            name: "Simple Toast",
            category: "Breakfast",
            difficulty: "Basic",
            prepTime: 0,
            cookTime: 2,
            servings: 1,
            ingredientItems: [ingredient("1", "slice", "bread")],
            prePrepSteps: [step("   "), step("")],   // all blank — should be stripped
            mainInstructions: [step("Toast bread")],
            notes: "",
            imageReference: nil,
            isFavorite: false
        )

        controller.saveRecipeModel(built)
        let saved = try #require(controller.fetchRecipes().first)
        #expect(saved.prePrepInstructions.isEmpty)
        #expect(saved.instructions == ["Toast bread"])
    }

    // MARK: - Edit (update in place)

    @Test func editRecipe_updatesInPlaceWithoutDuplicating() throws {
        let controller = makeController()
        let id = UUID()

        controller.saveRecipeModel(RecipeWizardBuilder.assemble(
            recipeId: id,
            name: "Original Name",
            category: "Lunch",
            difficulty: "Intermediate",
            prepTime: 15,
            cookTime: 30,
            servings: 2,
            ingredientItems: [ingredient("1", "cup", "rice")],
            prePrepSteps: [],
            mainInstructions: [step("Cook rice")],
            notes: "",
            imageReference: nil,
            isFavorite: false
        ))

        // Overwrite with same id (edit path).
        controller.saveRecipeModel(RecipeWizardBuilder.assemble(
            recipeId: id,
            name: "Updated Name",
            category: "Dinner",
            difficulty: "Intermediate",
            prepTime: 15,
            cookTime: 35,
            servings: 4,
            ingredientItems: [ingredient("2", "cups", "rice"), ingredient("1", "tsp", "oil")],
            prePrepSteps: [step("Rinse rice")],
            mainInstructions: [step("Cook rice"), step("Fluff and serve")],
            notes: "Better version",
            imageReference: nil,
            isFavorite: true
        ))

        let recipes = controller.fetchRecipes()
        #expect(recipes.count == 1)   // updated, not duplicated
        let saved = try #require(recipes.first)
        #expect(saved.id == id)
        #expect(saved.name == "Updated Name")
        #expect(saved.baseServings == 4)
        #expect(saved.ingredients.count == 2)
        #expect(saved.prePrepInstructions == ["Rinse rice"])
        #expect(saved.instructions == ["Cook rice", "Fluff and serve"])
        #expect(saved.notes == "Better version")
        #expect(saved.isFavorite == true)
    }

    // MARK: - Multiple recipes

    @Test func multipleRecipes_allSavedAndFetched() {
        let controller = makeController()

        let names = ["Pancakes", "Omelette", "French Toast"]
        for name in names {
            controller.saveRecipeModel(RecipeWizardBuilder.assemble(
                recipeId: UUID(),
                name: name,
                category: "Breakfast",
                difficulty: "Basic",
                prepTime: 5,
                cookTime: 10,
                servings: 2,
                ingredientItems: [ingredient("1", "cup", "milk")],
                prePrepSteps: [],
                mainInstructions: [step("Cook")],
                notes: "",
                imageReference: nil,
                isFavorite: false
            ))
        }

        let fetched = controller.fetchRecipes()
        #expect(fetched.count == 3)
        #expect(Set(fetched.map(\.name)) == Set(names))
    }

    // MARK: - Delete

    @Test func deleteWizardRecipe_removesFromStore() {
        let controller = makeController()
        let id = UUID()

        controller.saveRecipeModel(RecipeWizardBuilder.assemble(
            recipeId: id,
            name: "To Be Deleted",
            category: "Snack",
            difficulty: "Basic",
            prepTime: 1,
            cookTime: 5,
            servings: 1,
            ingredientItems: [ingredient("1", "", "apple")],
            prePrepSteps: [],
            mainInstructions: [step("Eat the apple")],
            notes: "",
            imageReference: nil,
            isFavorite: false
        ))

        #expect(controller.fetchRecipes().count == 1)
        controller.deleteRecipe(withId: id)
        #expect(controller.fetchRecipes().isEmpty)
    }

    // MARK: - Favorite toggle

    @Test func favoriteToggle_flipsOnEachCall() {
        let controller = makeController()
        let id = UUID()

        controller.saveRecipeModel(RecipeWizardBuilder.assemble(
            recipeId: id,
            name: "Creme Brulee",
            category: "Dessert",
            difficulty: "Intermediate",
            prepTime: 20,
            cookTime: 40,
            servings: 4,
            ingredientItems: [ingredient("2", "cups", "cream")],
            prePrepSteps: [],
            mainInstructions: [step("Heat cream"), step("Torch the sugar")],
            notes: "",
            imageReference: nil,
            isFavorite: false
        ))

        #expect(controller.fetchRecipes().first?.isFavorite == false)
        controller.toggleFavorite(withId: id)
        #expect(controller.fetchRecipes().first?.isFavorite == true)
        controller.toggleFavorite(withId: id)
        #expect(controller.fetchRecipes().first?.isFavorite == false)
    }

    // MARK: - Tags through wizard builder

    @Test func wizardAssemble_persistsTags() throws {
        let controller = makeController()

        controller.saveRecipeModel(RecipeWizardBuilder.assemble(
            recipeId: UUID(),
            name: "Tagged Recipe",
            category: "Main",
            difficulty: "Basic",
            prepTime: 5,
            cookTime: 10,
            servings: 2,
            ingredientItems: [ingredient("1", "cup", "rice")],
            prePrepSteps: [],
            mainInstructions: [step("Cook")],
            notes: "",
            imageReference: nil,
            isFavorite: false,
            tags: ["quick", "weeknight", "healthy"]
        ))

        let saved = try #require(controller.fetchRecipes().first)
        #expect(Set(saved.tags) == ["quick", "weeknight", "healthy"])
    }

    @Test func wizardAssemble_emptyTags_roundTripsToEmpty() throws {
        let controller = makeController()

        controller.saveRecipeModel(RecipeWizardBuilder.assemble(
            recipeId: UUID(),
            name: "No Tags",
            category: "Main",
            difficulty: "Basic",
            prepTime: 5,
            cookTime: 10,
            servings: 2,
            ingredientItems: [ingredient("1", "cup", "flour")],
            prePrepSteps: [],
            mainInstructions: [step("Mix")],
            notes: "",
            imageReference: nil,
            isFavorite: false,
            tags: []
        ))

        let saved = try #require(controller.fetchRecipes().first)
        #expect(saved.tags.isEmpty)
    }

    @Test func editRecipe_updatesTags() throws {
        let controller = makeController()
        let id = UUID()

        controller.saveRecipeModel(RecipeWizardBuilder.assemble(
            recipeId: id,
            name: "Tag Update Test",
            category: "Main",
            difficulty: "Basic",
            prepTime: 5,
            cookTime: 10,
            servings: 2,
            ingredientItems: [ingredient("1", "cup", "rice")],
            prePrepSteps: [],
            mainInstructions: [step("Cook")],
            notes: "",
            imageReference: nil,
            isFavorite: false,
            tags: ["old-tag"]
        ))

        controller.saveRecipeModel(RecipeWizardBuilder.assemble(
            recipeId: id,
            name: "Tag Update Test",
            category: "Main",
            difficulty: "Basic",
            prepTime: 5,
            cookTime: 10,
            servings: 2,
            ingredientItems: [ingredient("1", "cup", "rice")],
            prePrepSteps: [],
            mainInstructions: [step("Cook")],
            notes: "",
            imageReference: nil,
            isFavorite: false,
            tags: ["new-tag", "quick"]
        ))

        let saved = try #require(controller.fetchRecipes().first)
        #expect(Set(saved.tags) == ["new-tag", "quick"])
    }

    // MARK: - Ingredient quantities

    @Test func ingredientQuantity_survivesRoundTrip() throws {
        let controller = makeController()

        controller.saveRecipeModel(RecipeWizardBuilder.assemble(
            recipeId: UUID(),
            name: "Precise Recipe",
            category: "Main",
            difficulty: "Expert",
            prepTime: 30,
            cookTime: 60,
            servings: 6,
            ingredientItems: [
                ingredient("1.5",  "kg",   "beef"),
                ingredient("0.25", "cups", "wine"),
                ingredient("",     "pinch","pepper"),  // blank qty → defaults to 1.0
            ],
            prePrepSteps: [],
            mainInstructions: [step("Braise")],
            notes: "",
            imageReference: nil,
            isFavorite: false
        ))

        let saved = try #require(controller.fetchRecipes().first)
        let beef  = try #require(saved.ingredients.first { $0.name == "Beef" })
        let wine  = try #require(saved.ingredients.first { $0.name == "Wine" })
        let pepper = try #require(saved.ingredients.first { $0.name == "Pepper" })

        #expect(beef.baseQuantity == 1.5)
        #expect(wine.baseQuantity == 0.25)
        #expect(pepper.baseQuantity == 1.0)  // blank qty defaults to 1
    }
}
