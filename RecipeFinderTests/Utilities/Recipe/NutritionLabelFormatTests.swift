import Testing
import Foundation
@testable import RecipeFinder

// Characterisation tests: pin the recipe Nutrition card's numbers before they moved out of RecipeDetailView.
@Suite struct NutritionLabelFormatTests {

    private func info(fat: Double = 0, carbs: Double = 0, protein: Double = 0) -> NutritionInfo {
        NutritionInfo(calories: 0, fat: fat, saturates: 0, carbs: carbs, sugars: 0,
                      fibre: 0, protein: protein, salt: 0, coverage: 1)
    }

    @Test(arguments: [
        (1000.0, 2000.0, "50%"),
        (35.4, 70.0, "51%"),
        (0.1, 70.0, "1%"),   // never shows 0% for a present nutrient
        (0.0, 6.0, "1%"),
        (12.0, 0.0, ""),     // no reference intake → blank
    ])
    func percentOfReferenceIntake(value: Double, reference: Double, expected: String) {
        #expect(NutritionLabelFormat.percent(value, of: reference) == expected)
    }

    @Test(arguments: [(12.4, "12"), (10.0, "10"), (9.96, "10.0"), (3.14, "3.1"), (0.0, "0.0")])
    func macroGramsWholeFromTenUp(value: Double, expected: String) {
        #expect(NutritionLabelFormat.macro(value) == expected)
    }

    @Test(arguments: [(1.234, "1.2"), (1.0, "1.0"), (0.456, "0.46"), (0.0, "0.00")])
    func saltTwoDecimalsBelowOneGram(value: Double, expected: String) {
        #expect(NutritionLabelFormat.salt(value) == expected)
    }

    @Test func referenceIntakesMatchUKAdult() {
        let ri = NutritionLabelFormat.ReferenceIntake.self
        #expect([ri.calories, ri.fat, ri.saturates, ri.carbs, ri.sugars, ri.protein, ri.salt]
                == [2000, 70, 20, 260, 90, 50, 6])
    }

    @Test func energySplitWeighsFatAtNineKcalPerGram() {
        // 10 g fat = 90 kcal, 20 g carbs = 80 kcal, 5 g protein = 20 kcal → 190 kcal.
        let split = NutritionLabelFormat.energySplit(info(fat: 10, carbs: 20, protein: 5))
        #expect(abs(split.fat - 90.0 / 190) < 1e-9)
        #expect(abs(split.carbs - 80.0 / 190) < 1e-9)
        #expect(abs(split.protein - 20.0 / 190) < 1e-9)
    }

    @Test func energySplitOfNothingIsAllZero() {
        let split = NutritionLabelFormat.energySplit(info())
        #expect(split.fat == 0 && split.carbs == 0 && split.protein == 0)
    }
}
