import Testing
@testable import RecipeFinder

@Suite("EnglishPlural")
struct EnglishPluralTests {

    @Test("A plural folds to its singular", arguments: [
        ("blueberries", "blueberry"), ("cherries", "cherry"), ("anchovies", "anchovy"),
        ("tomatoes", "tomato"), ("potatoes", "potato"),
        ("peaches", "peach"), ("radishes", "radish"), ("boxes", "box"), ("glasses", "glass"),
        ("leaves", "leaf"), ("loaves", "loaf"), ("halves", "half"),
        ("carrots", "carrot"), ("eggs", "egg"), ("cheeses", "cheese"), ("glazes", "glaze"),
        ("olives", "olive"), ("cloves", "clove"), ("chives", "chive"),
        ("cookies", "cookie"), ("brownies", "brownie"), ("quiches", "quiche"), ("sloes", "sloe"),
        ("pies", "pie"), ("chillies", "chilli"), ("chilies", "chili"), ("geese", "goose"),
    ])
    func foldsPlural(plural: String, singular: String) {
        #expect(EnglishPlural.singular(plural) == singular)
    }

    @Test("A word that only looks plural is left alone", arguments: [
        "hummus", "asparagus", "couscous", "molasses", "swiss", "glass", "watercress", "citrus", "series", "species",
    ])
    func keepsLookalikes(word: String) {
        #expect(EnglishPlural.singular(word) == word)
    }

    @Test("A singular and a short word are left alone", arguments: [
        "blueberry", "cheese", "leaf", "egg", "gas", "pea", "olive",
    ])
    func keepsSingulars(word: String) {
        #expect(EnglishPlural.singular(word) == word)
    }
}
