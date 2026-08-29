import Testing
import Foundation
@testable import RecipeFinder

/// Guardrail against silent performance regressions on the rendering hot path.
///
/// These are deliberately *loose* wall-clock budgets: they exist to catch
/// order-of-magnitude regressions — e.g. accidentally deleting the memoization
/// on `normalize`/`categorize`, which is exactly what once made tab switching
/// crawl — not small run-to-run fluctuations. The cached path collapses a large
/// call count into a few real computations plus cheap lookups, so it finishes in
/// a few milliseconds; an uncached path scales linearly and blows past the budget.
///
/// If one of these ever fails, do not bump the number reflexively: check whether
/// a cache or other memoization was removed first.
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
