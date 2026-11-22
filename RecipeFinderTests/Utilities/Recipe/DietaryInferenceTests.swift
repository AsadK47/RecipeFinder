import Testing
import Foundation
@testable import RecipeFinder

@Suite("DietaryInference")
struct DietaryInferenceTests {

    private static func recipe(_ name: String = "Dinner", _ ingredients: [String]) -> RecipeModel {
        RecipeModel(
            name: name, category: "Main", difficulty: "Basic", prepTime: "10 minutes", cookingTime: "20 minutes",
            baseServings: 2,
            ingredients: ingredients.map { Ingredient(baseQuantity: 1, unit: "", name: $0) },
            prePrepInstructions: [], instructions: [], notes: ""
        )
    }

    private static func infer(_ name: String = "Dinner", _ ingredients: [String]) -> DietaryInfo {
        DietaryInference.infer(recipe(name, ingredients))
    }

    @Test("a plant-only recipe is vegetarian and vegan")
    func plantOnlyIsVegan() {
        let info = Self.infer(["onion, diced", "chickpeas", "coconut milk", "peanut butter", "eggplants", "butternut squash"])
        #expect(info.isVegetarian)
        #expect(info.isVegan)
    }

    @Test("any meat or fish ingredient means neither vegetarian nor vegan", arguments: [
        "boneless chicken thighs", "lamb mince", "fish sauce", "cod fillets", "beef broth", "prawns",
        "worcestershire sauce", "halal gelatin powder", "dried kelp and anchovy stock pack", "yeo's laksa paste",
        "kimchi, packed", "nuoc mam cham, optional", "lard", "bacon"
    ])
    func meatIsNotVegetarian(ingredient: String) {
        let info = Self.infer(["onion", ingredient])
        #expect(!info.isVegetarian)
        #expect(!info.isVegan)
    }

    @Test("a plain or unnamed stock counts as meat; a vegetable stock doesn't", arguments: [
        ("chicken stock", false), ("cold water or stock, for the slurry", false), ("hot vegetable stock", true),
        ("vegetable bouillon powder, optional", true), ("mushroom broth", true)
    ])
    func stockNeedsAVegetableWord(ingredient: String, vegetarian: Bool) {
        #expect(Self.infer([ingredient]).isVegetarian == vegetarian)
    }

    @Test("mushrooms and quail eggs named after animals stay vegetarian", arguments: [
        "oyster mushrooms", "seafood mushrooms, trimmed", "hard boiled quail eggs, optional"
    ])
    func animalNamedPlantsStayVegetarian(ingredient: String) {
        #expect(Self.infer([ingredient]).isVegetarian)
    }

    @Test("oyster sauce is not vegetarian")
    func oysterSauceIsNotVegetarian() {
        #expect(!Self.infer(["oyster sauce"]).isVegetarian)
    }

    @Test("parmesan is made with animal rennet, so it isn't vegetarian")
    func parmesanIsNotVegetarian() {
        #expect(!Self.infer(["parmesan, grated"]).isVegetarian)
    }

    @Test("dairy, eggs and honey are vegetarian but not vegan", arguments: [
        "large free-range eggs", "unsalted butter", "double cream", "milk, dairy or non-dairy", "lactose-free milk",
        "greek yoghurt", "ghee", "honey", "mature cheddar", "dark chocolate", "egg noodles", "chow mein noodles", "curd", "kaya jam"
    ])
    func animalProductsAreVegetarianOnly(ingredient: String) {
        let info = Self.infer([ingredient])
        #expect(info.isVegetarian)
        #expect(!info.isVegan)
    }

    @Test("plant versions of dairy words stay vegan", arguments: [
        "coconut cream", "almond milk", "oat milk", "vegan butter", "cream of tartar", "cocoa butter", "bean curd", "unsweetened plant-based milk"
    ])
    func plantDairyStaysVegan(ingredient: String) {
        #expect(Self.infer([ingredient]).isVegan)
    }

    @Test("a meat word in the recipe's name rules it out even if the list doesn't say")
    func meatInTheNameIsNotVegetarian() {
        #expect(!Self.infer("Chicken korma", ["onion", "korma paste"]).isVegetarian)
    }

    @Test("a recipe with no real ingredient list isn't tagged", arguments: [[String](), ["See recipe"]])
    func unknownIngredientsAreNotTagged(ingredients: [String]) {
        let info = Self.infer(ingredients)
        #expect(!info.isVegetarian)
        #expect(!info.isVegan)
    }

    @Test("only vegetarian and vegan are inferred — allergen and diet flags are never guessed")
    func allergenFlagsAreNeverGuessed() {
        let info = Self.infer(["rice", "water", "salt"])
        #expect(!info.isGlutenFree && !info.isDairyFree && !info.isNutFree && !info.isLowCarb && !info.isKeto)
    }

    @Test("matching is case-insensitive")
    func caseInsensitive() {
        #expect(!Self.infer(["Chicken Breast"]).isVegetarian)
        #expect(!Self.infer(["EGGS"]).isVegan)
    }
}
