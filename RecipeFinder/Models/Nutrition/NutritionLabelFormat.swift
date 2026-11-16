import Foundation

/// The numbers on the recipe Nutrition card (UK label style), kept pure so they're testable.
enum NutritionLabelFormat {
    /// Reference intakes for an average adult (8400 kJ / 2000 kcal), per the UK label.
    enum ReferenceIntake {
        static let calories: Double = 2000
        static let fat: Double = 70
        static let saturates: Double = 20
        static let carbs: Double = 260
        static let sugars: Double = 90
        static let protein: Double = 50
        static let salt: Double = 6
    }

    /// "% RI" text; a present nutrient never reads 0%. Blank when there's no reference.
    static func percent(_ value: Double, of reference: Double) -> String {
        guard reference > 0 else { return "" }
        return "\(max(1, Int((value / reference * 100).rounded())))%"
    }

    /// Grams: whole numbers from 10 g up, one decimal below.
    static func macro(_ value: Double) -> String {
        value >= 10 ? "\(Int(value.rounded()))" : String(format: "%.1f", value)
    }

    /// Salt: one decimal from 1 g up, two below (small amounts matter for salt).
    static func salt(_ value: Double) -> String {
        value >= 1.0 ? String(format: "%.1f", value) : String(format: "%.2f", value)
    }

    /// Share of energy from fat / carbs / protein (9 / 4 / 4 kcal per gram), so the bar shows energy, not mass.
    static func energySplit(_ nutrition: NutritionInfo) -> (fat: Double, carbs: Double, protein: Double) {
        let fat = nutrition.fat * 9
        let carbs = nutrition.carbs * 4
        let protein = nutrition.protein * 4
        let total = max(fat + carbs + protein, 1)
        return (fat / total, carbs / total, protein / total)
    }
}
