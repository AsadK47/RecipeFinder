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

    /// Scales every macro by `servings` to turn a per-serving estimate into a
    /// whole-recipe total. `coverage` is a proportion, so it stays unchanged.
    func scaled(by servings: Int) -> NutritionInfo {
        let factor = Double(max(servings, 1))
        return NutritionInfo(
            calories: Int((Double(calories) * factor).rounded()),
            fat: fat * factor,
            saturates: saturates * factor,
            carbs: carbs * factor,
            sugars: sugars * factor,
            fibre: fibre * factor,
            protein: protein * factor,
            salt: salt * factor,
            coverage: coverage
        )
    }
}
