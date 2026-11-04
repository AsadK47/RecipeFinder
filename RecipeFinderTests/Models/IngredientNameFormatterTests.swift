import Testing
@testable import RecipeFinder

/// Guards ingredient-name sanitisation: the amount/unit and prep notes must never bleed into the displayed name,
/// and prep notes must not repeat a phrase alongside its own keyword ("cut, cut into cubes"). Inputs are `.capitalized`
/// to mirror `Ingredient.name`, which is what the formatter actually receives.
@Suite("IngredientNameFormatter sanitisation")
struct IngredientNameFormatterTests {

    @Test("Main name drops leading amount+unit and bare counts", arguments: [
        ("050 g chicken breast, cut into cubes, cut", "Chicken Breast"),
        ("1 chicken breast, cut into cubes", "Chicken Breast"),
        ("2-3 eggs, beaten", "Eggs"),
        ("1/4 tsp kosher salt", "Kosher Salt"),
        ("2 cups all-purpose flour, sifted", "All-Purpose Flour"),
        ("boneless skinless chicken thighs", "Chicken Thighs"),
    ])
    func mainName(input: String, expected: String) {
        #expect(IngredientNameFormatter.extractMainName(input.capitalized) == expected)
    }

    @Test("Prep notes de-duplicate and never repeat a phrase with its own keyword", arguments: [
        ("050 g chicken breast, cut into cubes, cut", "cut into cubes"),
        ("red pepper, cut into small cubes, cut", "cut into small cubes"),
        ("2-3 eggs, beaten", "beaten"),
        ("boneless skinless chicken thighs", "boneless, skinless"),
    ])
    func prepNotes(input: String, expected: String) {
        #expect(IngredientNameFormatter.extractPreparationNotes(input.capitalized) == expected)
    }

    @Test("No prep notes when the name has none")
    func noPrep() {
        #expect(IngredientNameFormatter.extractPreparationNotes("Kosher Salt") == nil)
    }

    @Test("Match key is the lowercased main name, so decorated and plain names compare equal", arguments: [
        ("Fresh Basil", "basil"),
        ("  Chicken   Breast, diced ", "chicken breast"),
        ("2 Large Eggs (Room Temperature)", "large eggs"),
    ])
    func matchKey(input: String, expected: String) {
        #expect(IngredientNameFormatter.matchKey(input) == expected)
    }
}
