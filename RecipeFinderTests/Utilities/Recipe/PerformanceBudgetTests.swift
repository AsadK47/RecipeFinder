import Testing
import Foundation
@testable import RecipeFinder

/// Deliberately loose wall-clock budgets guarding the render hot path: they catch order-of-magnitude regressions (e.g. dropping `normalize`/`categorize` memoization, which once made tab switching crawl), not run-to-run jitter.
/// If one fails, don't bump the number reflexively — check first whether a cache or memoization was removed.
@Suite("Performance budgets")
struct PerformanceBudgetTests {

    /// A handful of repeated inputs, mimicking how filtering hits the same
    /// ingredients across many recipes.
    private static let ingredientSamples = [
        "2 cups all-purpose flour",
        "1 tbsp extra virgin olive oil",
        "canned coconut milk",
        "3 large free-range eggs",
        "fresh basil leaves, chopped"
    ]

    private static let itemSamples = [
        "chicken breast", "frozen peas", "vanilla ice cream", "cheddar cheese",
        "spaghetti", "olive oil", "tomato paste", "fresh basil"
    ]

    @Test("IngredientNormalizer.normalize stays within budget over many repeated calls")
    func normalizeBudget() {
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for i in 0..<100_000 {
                _ = IngredientNormalizer.normalize(Self.ingredientSamples[i % Self.ingredientSamples.count])
            }
        }
        #expect(elapsed < .milliseconds(300))
    }

    @Test("CategoryClassifier.categorize stays within budget over many repeated calls")
    func categorizeBudget() {
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for i in 0..<100_000 {
                _ = CategoryClassifier.categorize(Self.itemSamples[i % Self.itemSamples.count])
            }
        }
        #expect(elapsed < .milliseconds(300))
    }
}
