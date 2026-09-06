import Testing
@testable import RecipeFinder

/// Characterization tests for `groupSimilarIngredients` (used by `IngredientCatalog`),
/// which previously had no coverage. They lock the compound/descriptor/comma
/// behaviour so the precedence cleanup is provably behaviour-preserving.
@Suite("CategoryClassifier grouping")
struct CategoryClassifierGroupingTests {

    @Test("A known compound is kept as a two-word name")
    func compoundKept() {
        #expect(CategoryClassifier.groupSimilarIngredients(["chicken breast"]) == ["Chicken Breast"])
    }

    @Test("Descriptor words are stripped before grouping")
    func descriptorsStripped() {
        #expect(CategoryClassifier.groupSimilarIngredients(["boneless chicken breast"]) == ["Chicken Breast"])
    }

    @Test("Only the part before the first comma is used")
    func commaTrimmed() {
        #expect(CategoryClassifier.groupSimilarIngredients(["carrots, peeled and chopped"]) == ["Carrots"])
    }

    @Test("Surrounding whitespace does not affect the result")
    func whitespaceIgnored() {
        #expect(CategoryClassifier.groupSimilarIngredients(["  olive oil  "]) == ["Olive Oil"])
    }

    @Test("Results are de-duplicated and sorted")
    func dedupedAndSorted() {
        let result = CategoryClassifier.groupSimilarIngredients(["chicken thigh", "chicken breast", "chicken breast"])
        #expect(result == ["Chicken Breast", "Chicken Thigh"])
    }

    @Test("An entry that is only a descriptor is dropped")
    func pureDescriptorDropped() {
        #expect(CategoryClassifier.groupSimilarIngredients(["fresh"]).isEmpty)
    }
}
