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

    private static func infer(_ ingredients: [String], name: String = "Dinner") -> DietaryInfo {
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
        "kimchi, packed", "nuoc mam cham, optional", "lard", "bacon", "dripping"
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
        "greek yoghurt", "ghee", "honey", "mature cheddar", "dark chocolate", "egg noodles", "chow mein noodles", "curd", "kaya jam",
        "oil or fat of choice, for frying"
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

    @Test("full-fat coconut milk is still vegan")
    func fullFatPlantMilkStaysVegan() {
        #expect(Self.infer(["full-fat canned coconut milk"]).isVegan)
    }

    @Test("a recipe its author titled Vegan is vegan, but a meat word still rules it out")
    func veganTitleIsTrusted() {
        #expect(Self.infer(["plain flour", "dark chocolate"], name: "Vegan Chocolate Chip Cookies").isVegan)
        #expect(!Self.infer(["chicken", "rice"], name: "Vegan-ish Chicken Bowl").isVegan)
    }

    @Test("a meat word in the recipe's name rules it out even if the list doesn't say")
    func meatInTheNameIsNotVegetarian() {
        #expect(!Self.infer(["onion", "korma paste"], name: "Chicken korma").isVegetarian)
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

    /// Steps that name a dairy word but call for a plant one (the ingredient list says which) or a cooker setting.
    private static let plantStepExceptions: Set<String> = [
        "Coriander Chickpea Bowl|cream", "Wild West Wings|milk", "Instant Pot Idli Dosa Batter|yogurt"
    ]

    @Test("a bundled recipe tagged Vegan never asks for an animal product in its method")
    func veganSeedMethodsArePlantOnly() {
        let recipes = BundledRecipeCatalog.load()
        #expect(!recipes.isEmpty)
        // A recipe its author titled Vegan uses dairy words for plant versions throughout ("the buttercream").
        let tagged = recipes.filter { $0.dietaryInfo.isVegan && !DietaryInference.words(in: $0.name).contains("vegan") }
        var used: Set<String> = []
        for recipe in tagged {
            for step in recipe.prePrepInstructions + recipe.instructions {
                for word in Self.unqualifiedAnimalWords(in: step) {
                    let key = "\(recipe.name)|\(word)"
                    if Self.plantStepExceptions.contains(key) {
                        used.insert(key)
                    } else {
                        Issue.record("\(recipe.name) is tagged Vegan but its method says: \(step)")
                    }
                }
            }
        }
        // A fixed or renamed recipe's exception must go, so it can't cover a later step under that name.
        #expect(used == Self.plantStepExceptions)
    }

    /// Each animal-product word in the step that no plant word qualifies ("butter", not "vegan butter").
    private static func unqualifiedAnimalWords(in step: String) -> [String] {
        let words = DietaryInference.words(in: step)
        return words.indices.compactMap { index in
            let pair = Array(words[max(0, index - 1)...index])
            guard DietaryInference.animalProductWords.contains(words[index]),
                  DietaryInference.containsAnimalProduct(pair) else { return nil }
            return words[index]
        }
    }
}
