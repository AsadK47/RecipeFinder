import Testing
import Foundation
@testable import RecipeFinder

/// `heroImageName` decides which single image represents a recipe on its card.
/// Pins the bug where a recipe with only a post-cook photo (no main image) kept
/// its filler glyph because the card ignored `photoNames`.
@Suite("RecipeModel hero image")
struct RecipeHeroImageTests {

    private func recipe(imageName: String?, photoNames: [String]) -> RecipeModel {
        RecipeModel(
            name: "R",
            category: "Main",
            difficulty: "Basic",
            prepTime: "10 min",
            cookingTime: "20 min",
            baseServings: 4,
            ingredients: [],
            prePrepInstructions: [],
            instructions: [],
            notes: "",
            imageName: imageName,
            isFavorite: false,
            tags: [],
            dietaryInfo: DietaryInfo(),
            photoNames: photoNames
        )
    }

    @Test("Main image wins when present")
    func prefersMainImage() {
        let r = recipe(imageName: "main.jpg", photoNames: ["cook.jpg"])
        #expect(r.heroImageName == "main.jpg")
    }

    @Test("Falls back to first cook photo when no main image")
    func fallsBackToFirstPhoto() {
        let r = recipe(imageName: nil, photoNames: ["cook1.jpg", "cook2.jpg"])
        #expect(r.heroImageName == "cook1.jpg")
    }

    @Test("Empty main image is treated as absent")
    func emptyImageNameFallsBack() {
        let r = recipe(imageName: "", photoNames: ["cook.jpg"])
        #expect(r.heroImageName == "cook.jpg")
    }

    @Test("Nil when there is no image at all")
    func nilWhenNothing() {
        let r = recipe(imageName: nil, photoNames: [])
        #expect(r.heroImageName == nil)
    }
}
