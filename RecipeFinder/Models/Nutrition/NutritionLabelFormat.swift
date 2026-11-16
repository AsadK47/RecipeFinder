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

    /// "% RI" text: none at all reads 0%, a trace rounds up to 1%. Blank when there's no reference.
    static func percent(_ value: Double, of reference: Double) -> String {
        guard reference > 0 else { return "" }
        guard value > 0 else { return "0%" }
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

    /// One line of the label. `isSubrow` = indented "of which …" line; `dividerAbove` = rule before it.
    struct Row: Equatable {
        let label: String
        let value: String
        let unit: String
        /// nil when the label shows the whole recipe (% RI is per serving only) or the nutrient has no RI.
        let percent: String?
        var isHero = false
        var isSubrow = false
        var dividerAbove = false
    }

    /// The label's lines in UK order: calories, fat (saturates), carbohydrate (sugars), fibre, protein, salt.
    static func rows(for n: NutritionInfo, wholeRecipe: Bool) -> [Row] {
        func ri(_ value: Double, _ reference: Double) -> String? {
            wholeRecipe ? nil : percent(value, of: reference)
        }
        typealias RI = ReferenceIntake
        return [
            Row(label: "Calories", value: "\(n.calories)", unit: "kcal",
                percent: ri(Double(n.calories), RI.calories), isHero: true),
            Row(label: "Fat", value: macro(n.fat), unit: "g", percent: ri(n.fat, RI.fat), dividerAbove: true),
            Row(label: "of which saturates", value: macro(n.saturates), unit: "g",
                percent: ri(n.saturates, RI.saturates), isSubrow: true),
            Row(label: "Carbohydrate", value: macro(n.carbs), unit: "g", percent: ri(n.carbs, RI.carbs),
                dividerAbove: true),
            Row(label: "of which sugars", value: macro(n.sugars), unit: "g",
                percent: ri(n.sugars, RI.sugars), isSubrow: true),
            Row(label: "Fibre", value: macro(n.fibre), unit: "g", percent: nil, dividerAbove: true),
            Row(label: "Protein", value: macro(n.protein), unit: "g", percent: ri(n.protein, RI.protein),
                dividerAbove: true),
            Row(label: "Salt", value: salt(n.salt), unit: "g", percent: ri(n.salt, RI.salt), dividerAbove: true),
        ]
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
