import Testing
import Foundation
@testable import RecipeFinder

@Suite struct RecipeFileExporterTests {

    // MARK: - Helpers

    private func makeRecipe(
        name: String = "Spaghetti Bolognese",
        notes: String = "A classic.\nhttps://example.com/spaghetti"
    ) -> RecipeModel {
        var r = RecipeModel(
            name: name,
            category: "Main",
            difficulty: "Medium",
            prepTime: "15 minutes",
            cookingTime: "45 minutes",
            baseServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 400, unit: "g", name: "beef mince"),
                Ingredient(baseQuantity: 2, unit: "cloves", name: "garlic"),
            ],
            prePrepInstructions: ["Peel the garlic"],
            instructions: ["Brown the mince", "Add sauce", "Simmer 30 min"],
            notes: notes,
            imageName: "https://example.com/image.jpg",
            tags: ["italian", "pasta"],
            dietaryInfo: DietaryInfo(isGlutenFree: true),
            cuisine: "Italian"
        )
        r.isFavorite = true
        r.rating = 5
        r.cookCount = 12
        return r
    }

    // MARK: - Round-trip

    @Test func roundTripPreservesName() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.name == "Spaghetti Bolognese")
    }

    @Test func roundTripPreservesIngredients() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.ingredients.count == 2)
        #expect(decoded.ingredients[0].name == "Beef Mince")
        #expect(decoded.ingredients[0].baseQuantity == 400)
        #expect(decoded.ingredients[0].unit == "g")
    }

    @Test func roundTripPreservesInstructions() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.instructions == ["Brown the mince", "Add sauce", "Simmer 30 min"])
    }

    @Test func roundTripPreservesPrePrep() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.prePrepInstructions == ["Peel the garlic"])
    }

    @Test func roundTripPreservesCuisineTagsDietaryInfo() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.cuisine == "Italian")
        #expect(decoded.tags == ["italian", "pasta"])
        #expect(decoded.dietaryInfo.isGlutenFree == true)
    }

    @Test func roundTripPreservesHTTPImageURL() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.imageName == "https://example.com/image.jpg")
    }

    // MARK: - Personal data isolation

    @Test func decodeAssignsNewUUID() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.id != recipe.id)
    }

    @Test func decodeResetsPersonalData() throws {
        let recipe = makeRecipe()
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.isFavorite == false)
        #expect(decoded.rating == 0)
        #expect(decoded.cookCount == 0)
        #expect(decoded.lastCookedAt == nil)
    }

    // MARK: - Image URL handling

    @Test func localImagePathIsDropped() throws {
        let r = RecipeModel(
            name: "Local Image Recipe",
            category: "Main",
            difficulty: "Easy",
            prepTime: "10 min",
            cookingTime: "20 min",
            baseServings: 2,
            ingredients: [],
            prePrepInstructions: [],
            instructions: ["Cook it"],
            notes: "",
            imageName: "/var/mobile/Containers/Data/Application/abc123/recipe.jpg"
        )
        let data = try RecipeFileExporter.encode(r)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.imageName == nil)
    }

    // MARK: - Source URL reconstruction

    @Test func sourceURLAppearsInDecodedNotes() throws {
        let recipe = makeRecipe(notes: "Good recipe.\nhttps://example.com/spaghetti")
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.importedFromURL?.absoluteString == "https://example.com/spaghetti")
    }

    @Test func recipeWithNoSourceURLHasNoFooter() throws {
        let recipe = makeRecipe(notes: "My own creation.")
        let data = try RecipeFileExporter.encode(recipe)
        let decoded = try RecipeFileExporter.decode(data)
        #expect(decoded.importedFromURL == nil)
        #expect(decoded.notes == "My own creation.")
    }

    // MARK: - Version guard

    @Test func unsupportedVersionThrows() throws {
        // Build a minimal JSON with version 99 to trigger the version guard.
        let json = """
        {
          "version": 99,
          "name": "Future Recipe",
          "category": "Main",
          "difficulty": "Easy",
          "prepTime": "",
          "cookingTime": "",
          "baseServings": 2,
          "ingredients": [],
          "prePrepInstructions": [],
          "instructions": [],
          "notes": "",
          "tags": [],
          "dietaryInfo": {
            "isVegetarian": false,
            "isVegan": false,
            "isGlutenFree": false,
            "isDairyFree": false,
            "isNutFree": false,
            "isLowCarb": false,
            "isKeto": false
          }
        }
        """
        let data = Data(json.utf8)
        #expect(throws: RecipeFileError.self) {
            _ = try RecipeFileExporter.decode(data)
        }
    }
}
