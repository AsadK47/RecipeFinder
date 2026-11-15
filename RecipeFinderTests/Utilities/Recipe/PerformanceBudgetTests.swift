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

    /// Endless discovery: a 350-recipe library with a 30-item kitchen rebuilds its feed (pool + first page) — what
    /// runs on the main thread on each Recipes appear and library change — then pages 60 chapters.
    @MainActor @Test("DiscoveryFeedModel.update stays within budget for a 350-recipe library")
    func discoveryFeedBudget() {
        let letters = Array("abcdefghijklmnopqrstuvwxyz")
        let words: [String] = (0..<120).map { (n: Int) -> String in
            String(letters[n % 26]) + String(letters[(n / 26) % 26]) + "root"
        }
        let categories = ["Main", "Dessert", "Side"]
        let cuisines: [String?] = ["Italian", "Indian", nil]
        var recipes: [RecipeModel] = []
        for i in 0..<350 {
            let ingredients: [Ingredient] = (0..<12).map { offset in
                Ingredient(baseQuantity: 1, unit: "", name: words[(i * 7 + offset) % 120])
            }
            let cooked = i % 5 == 0
            let lastCooked: Date? = cooked ? Date(timeIntervalSinceNow: -86_400 * Double(i)) : nil
            recipes.append(RecipeModel(
                name: "Recipe \(i)", category: categories[i % 3], difficulty: "Basic",
                prepTime: "10 min", cookingTime: "\(i % 50) min", baseServings: 2,
                ingredients: ingredients, prePrepInstructions: [], instructions: ["Cook"], notes: "",
                isFavorite: i % 17 == 0, cookCount: cooked ? 2 : 0, lastCookedAt: lastCooked,
                cuisine: cuisines[i % 3]
            ))
        }
        let kitchen = Array(words.prefix(30))
        // Best of three fresh feeds: one busy-runner stall shouldn't fail the budget (main went red at 0.565 s on
        // 15 Nov); a real regression slows every run. The caches it leans on stay warm, as they do in the app.
        let clock = ContinuousClock()
        var best = Duration.seconds(60)
        var chapterCount = 0
        for _ in 0..<3 {
            let feed = DiscoveryFeedModel(seed: 1)
            let elapsed = clock.measure {
                feed.update(recipes: recipes, kitchenItemNames: kitchen)
                feed.update(recipes: recipes, kitchenItemNames: kitchen)
                for _ in 0..<20 {
                    if let last = feed.chapters.last { feed.chapterAppeared(last) }
                }
            }
            best = min(best, elapsed)
            chapterCount = feed.chapters.count
        }
        #expect(chapterCount >= 60)
        #expect(best < .milliseconds(500))
    }
}
