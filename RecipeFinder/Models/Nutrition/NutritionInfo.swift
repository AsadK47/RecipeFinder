import Foundation

struct NutritionInfo: Equatable {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    let fibre: Double
    /// Fraction of recipe ingredients that matched the nutrition database (0–1).
    let coverage: Double
}
