import Testing
import Foundation
@testable import RecipeFinder

/// Import 2/5: how well an import was read, and which fields to highlight in the wizard.
@Suite struct ImportQualityTests {

    private func prefill(
        name: String? = "Tomato Soup",
        ingredients: [String]? = ["2 tomatoes", "1 onion"],
        instructions: [String]? = ["Simmer for 20 minutes."],
        prepTime: Int? = 5,
        cookTime: Int? = 20
    ) -> RecipeWizardView.PrefilledRecipeData {
        RecipeWizardView.PrefilledRecipeData(
            name: name, description: nil, ingredients: ingredients, instructions: instructions,
            prepTime: prepTime, cookTime: cookTime, servings: 2, difficulty: nil, notes: nil,
            category: nil, isFavorite: nil, imageURL: nil
        )
    }

    @Test func completeImportScoresHighWithNothingMissing() {
        let result = ImportQuality.assess(prefill())
        #expect(result.missing.isEmpty)
        #expect(result.score == 1)
        #expect(!result.isLow)
    }

    @Test func partialImportFlagsWhatIsMissing() {
        let result = ImportQuality.assess(prefill(ingredients: ["tomatoes", "onion"], instructions: [], prepTime: nil, cookTime: 0))
        #expect(result.missing == [.steps, .amounts, .times])
        #expect(result.isLow)
    }

    @Test func emptyImportMissesEverything() {
        let result = ImportQuality.assess(prefill(name: "  ", ingredients: nil, instructions: nil, prepTime: nil, cookTime: nil))
        #expect(result.missing == Set(ImportQuality.Field.allCases))
        #expect(result.score == 0)
        #expect(result.isLow)
    }

    @Test(arguments: ["2 tomatoes", "½ cup stock", "1/2 tsp salt", "200g flour"])
    func ingredientWithAnAmountCounts(line: String) {
        #expect(!ImportQuality.assess(prefill(ingredients: [line])).missing.contains(.amounts))
    }

    @Test func parserConfidenceDecidesTheScoreButNotTheHighlights() {
        var low = prefill(instructions: [])
        low.sourceConfidence = 0.3
        #expect(ImportQuality.assess(low).score == 0.3)
        #expect(ImportQuality.assess(low).missing == [.steps])

        var high = prefill(instructions: [])
        high.sourceConfidence = 0.95
        #expect(!ImportQuality.assess(high).isLow)
    }

    @Test func onDeviceInterpretedImportCountsAsHighConfidence() {
        let recipe = InterpretedRecipe(name: "Soup", ingredients: ["1 onion"], steps: [], prepMinutes: nil,
                                       cookMinutes: nil, servings: nil, summary: nil)
        let assessed = ImportQuality.assess(RecipeWizardView.PrefilledRecipeData(interpreted: recipe))
        #expect(assessed.score == 1)
        #expect(!assessed.isLow)
    }
}
