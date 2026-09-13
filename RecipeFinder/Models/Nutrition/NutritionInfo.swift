import Foundation

/// Per-serving nutrition estimate, modelled on the UK standard nutrition label order.
struct NutritionInfo: Equatable {
    let calories: Int
    let fat: Double
    let saturates: Double
    let carbs: Double
    let sugars: Double
    let fibre: Double
    let protein: Double
    let salt: Double
    /// Fraction of recipe ingredients that matched the nutrition database (0–1).
    let coverage: Double
}
