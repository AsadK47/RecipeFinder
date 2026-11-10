import Foundation

/// One suggested amount for the ingredient at `index` (0-based) in the recipe's list.
struct AmountEstimate: Equatable, Sendable {
    let index: Int
    let quantity: Double
    let unit: String
}

/// What the estimator sees: the recipe as written, with the gaps marked. Built only when there is a gap to fill.
struct AmountEstimateRequest: Equatable, Sendable {
    /// Keeps the prompt inside the on-device model's small context window.
    static let maxSteps = 12

    let recipeName: String
    let servings: Int
    /// One line per ingredient, numbered from 1: "2. Plain flour — MISSING" or "3. Sugar — 100 g".
    let ingredientLines: [String]
    let steps: [String]
    let missingIndices: [Int]

    init?(recipeName: String, servings: Int, ingredients: [Ingredient], steps: [String]) {
        let missing = ingredients.indices.filter { ingredients[$0].isMissingAmount }
        guard !missing.isEmpty else { return nil }
        self.recipeName = recipeName
        self.servings = servings
        self.missingIndices = missing
        self.steps = Array(steps.prefix(Self.maxSteps))
        self.ingredientLines = ingredients.enumerated().map { offset, ingredient in
            "\(offset + 1). \(ingredient.displayName) — \(Self.amountText(ingredient))"
        }
    }

    var prompt: String {
        var lines = ["Recipe: \(recipeName) (serves \(servings))", "Ingredients:"]
        lines += ingredientLines
        if !steps.isEmpty {
            lines.append("Method:")
            lines += steps.map { "- \($0)" }
        }
        return lines.joined(separator: "\n")
    }

    private static func amountText(_ ingredient: Ingredient) -> String {
        if ingredient.isMissingAmount { return "MISSING" }
        guard ingredient.baseQuantity > 0 else { return "no amount needed" }
        let quantity = FractionFormatter.format(ingredient.baseQuantity)
        return ingredient.unit.isEmpty ? quantity : "\(quantity) \(ingredient.unit)"
    }
}

/// Suggests amounts for ingredients a recipe didn't give; production uses the on-device model (iOS 26+), tests a fake.
protocol IngredientAmountEstimating: Sendable {
    /// Suggestions for the request's missing ingredients, or nil when the model can't run — the action is then hidden.
    func estimateAmounts(for request: AmountEstimateRequest) async throws -> [AmountEstimate]?
}

/// For devices without the on-device model (pre-iOS 26 or Apple Intelligence off).
struct UnavailableIngredientAmountEstimator: IngredientAmountEstimating {
    func estimateAmounts(for request: AmountEstimateRequest) async throws -> [AmountEstimate]? { nil }
}

/// Merges accepted estimates into a recipe's ingredients without touching anything the recipe already gave.
enum AmountEstimateApplier {
    /// Fills only real gaps (`isMissingAmount`) with a positive amount; first estimate per ingredient wins.
    static func apply(_ estimates: [AmountEstimate], to ingredients: [Ingredient]) -> [Ingredient] {
        var result = ingredients
        var filled = Set<Int>()
        for estimate in estimates {
            guard result.indices.contains(estimate.index),
                  !filled.contains(estimate.index),
                  result[estimate.index].isMissingAmount,
                  estimate.quantity.isFinite, estimate.quantity > 0 else { continue }
            let unit = estimate.unit.trimmingCharacters(in: .whitespaces)
            result[estimate.index] = result[estimate.index].withAmount(estimate.quantity, unit: unit)
            filled.insert(estimate.index)
        }
        return result
    }
}

/// The estimator for this device: the on-device model where available, otherwise one that always declines.
func makeIngredientAmountEstimator() -> IngredientAmountEstimating {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
        return FoundationModelsAmountEstimator()
    }
    #endif
    return UnavailableIngredientAmountEstimator()
}

#if canImport(FoundationModels)
import FoundationModels

/// On-device (private/free/offline) amount estimation via guided generation; nil when the model can't run.
@available(iOS 26.0, *)
struct FoundationModelsAmountEstimator: IngredientAmountEstimating {

    @Generable
    struct GeneratedAmount {
        @Guide(description: "The number of the MISSING ingredient in the list")
        var ingredientNumber: Int
        @Guide(description: "A typical quantity for this recipe and serving size, e.g. 200")
        var quantity: Double
        @Guide(description: "The unit, e.g. g, ml, tbsp, tsp; empty for whole items such as eggs or onions")
        var unit: String
    }

    @Generable
    struct GeneratedAmounts {
        @Guide(description: "One entry per MISSING ingredient")
        var amounts: [GeneratedAmount]
    }

    func estimateAmounts(for request: AmountEstimateRequest) async throws -> [AmountEstimate]? {
        guard SystemLanguageModel.default.isAvailable else { return nil }
        let instructions = """
        You help a home cook fill in ingredient amounts a recipe left out. For each ingredient marked MISSING, \
        suggest a typical amount for this dish and serving size. Leave ingredients that have an amount alone.
        """
        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: request.prompt, generating: GeneratedAmounts.self)
        return response.content.amounts.map {
            AmountEstimate(index: $0.ingredientNumber - 1, quantity: $0.quantity, unit: $0.unit)
        }
    }
}
#endif
