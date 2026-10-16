import Testing
import Foundation
@testable import RecipeFinder

/// Import hardening regressions: short instruction steps must survive JSON-LD parsing, and text-heuristic
/// servings must reject implausible values. (New tests use Swift Testing per repo convention.)
@Suite struct RecipeImportHardeningTests {

    private func jsonLD(instructions: [String]) -> String {
        let steps = instructions.map { "{\"@type\":\"HowToStep\",\"text\":\"\($0)\"}" }.joined(separator: ", ")
        return """
        <html><head>
        <script type="application/ld+json">
        {
          "@context": "https://schema.org",
          "@type": "Recipe",
          "name": "Short Steps",
          "recipeIngredient": ["1 cup flour", "2 eggs"],
          "recipeInstructions": [\(steps)]
        }
        </script>
        </head><body></body></html>
        """
    }

    @Test("Short instruction steps are kept, not dropped as noise")
    func shortStepsSurvive() {
        let result = RecipeParser.parse(html: jsonLD(instructions: ["Serve hot.", "Stir.", "Rest for ten minutes before slicing."]))
        #expect(result.instructions == ["Serve hot.", "Stir.", "Rest for ten minutes before slicing."])
    }

    @Test("Implausible text-heuristic servings are rejected", arguments: [
        ("Serves: 0", Int?.none),
        ("Makes 999999 servings", Int?.none),
        ("Serves: 4", Int?.some(4)),
        ("Servings: 12", Int?.some(12)),
    ])
    func servingsBounds(text: String, expected: Int?) {
        #expect(RecipeParser.extractServings(from: text) == expected)
    }
}
