import Foundation

enum NutritionCalculator {

    /// Estimated per-serving nutrition, or nil if under 10% of ingredients match the database.
    static func calculate(ingredients: [Ingredient], servings: Int) -> NutritionInfo? {
        guard servings > 0, !ingredients.isEmpty else { return nil }

        var totalKcal     = 0.0
        var totalFat      = 0.0
        var totalSat      = 0.0
        var totalCarbs    = 0.0
        var totalSugars   = 0.0
        var totalFibre    = 0.0
        var totalProtein  = 0.0
        var totalSalt     = 0.0
        var matchedCount  = 0

        for ingredient in ingredients {
            guard let entry = NutritionDatabase.lookup(ingredient.mainIngredientName) else { continue }
            // Count as matched even if unquantifiable (e.g. a pinch), so coverage reflects name recognition, not unit coverage.
            matchedCount += 1
            let grams = gramWeight(quantity: ingredient.baseQuantity, unit: ingredient.unit, entry: entry)
            guard grams > 0 else { continue }
            let f        = grams / 100.0
            totalKcal   += entry.kcalPer100g    * f
            totalFat    += entry.fatPer100g      * f
            totalSat    += entry.satPer100g      * f
            totalCarbs  += entry.carbsPer100g    * f
            totalSugars += entry.sugarsPer100g   * f
            totalFibre  += entry.fibrePer100g    * f
            totalProtein += entry.proteinPer100g * f
            totalSalt   += entry.saltPer100g     * f
        }

        let coverage = Double(matchedCount) / Double(ingredients.count)
        guard coverage >= 0.1 else { return nil }

        let s = Double(servings)
        return NutritionInfo(
            calories:  Int((totalKcal    / s).rounded()),
            fat:       round1dp(totalFat     / s),
            saturates: round1dp(totalSat     / s),
            carbs:     round1dp(totalCarbs   / s),
            sugars:    round1dp(totalSugars  / s),
            fibre:     round1dp(totalFibre   / s),
            protein:   round1dp(totalProtein / s),
            salt:      round2dp(totalSalt    / s),
            coverage:  coverage
        )
    }

    // MARK: - Unit → grams conversion

    private static func gramWeight(
        quantity: Double,
        unit: String,
        entry: NutritionDatabase.Entry
    ) -> Double {
        // Canonical unit + the shared UnitConversion factors, so "lb", "pounds" and "litres" all convert (a bare "lb"
        // used to fall through to the per-piece weight).
        let unit = UnitConversion.canonicalUnit(unit)
        typealias W = UnitConversion.Weight
        typealias V = UnitConversion.Volume
        switch unit {
        case "g":     return quantity
        case "kg":    return quantity * W.gramsPerKg
        case "oz":    return quantity * W.gramsPerOunce
        case "lbs":   return quantity * W.gramsPerPound
        case "ml":    return quantity * entry.gramsPerMl
        case "l":     return quantity * V.mlPerL      * entry.gramsPerMl
        case "dl":    return quantity * V.mlPerDL     * entry.gramsPerMl
        case "cl":    return quantity * V.mlPerCL     * entry.gramsPerMl
        case "fl oz": return quantity * V.mlPerFlOz   * entry.gramsPerMl
        case "cup":   return quantity * V.mlPerCup    * entry.gramsPerMl
        case "tbsp":  return quantity * V.mlPerTbsp   * entry.gramsPerMl
        case "tsp":   return quantity * V.mlPerTsp    * entry.gramsPerMl
        case "pt":    return quantity * V.mlPerPint   * entry.gramsPerMl
        case "qt":    return quantity * V.mlPerQuart  * entry.gramsPerMl
        case "gal":   return quantity * V.mlPerGallon * entry.gramsPerMl
        default:
            // Count-based or unitless: look up the specific unit, then fall back to "piece"
            if let w = entry.gramsPerUnit[unit] { return quantity * w }
            if let w = entry.gramsPerUnit["piece"] { return quantity * w }
            return 0
        }
    }

    private static func round1dp(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }

    private static func round2dp(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
