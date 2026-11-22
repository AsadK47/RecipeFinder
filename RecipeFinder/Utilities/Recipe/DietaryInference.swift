import Foundation

/// Works out Vegetarian / Vegan from a recipe's ingredient names (and its title), so the bundled recipes answer the
/// dietary filters. Conservative by design: any word that might be meat, fish or an animal product rules the tag out,
/// so a miss leaves a recipe untagged rather than wrongly tagged. Allergen and diet flags (gluten, dairy, nuts,
/// low-carb, keto) are never guessed — a wrong "Nut-Free" could hurt someone.
/// Applied to the bundled recipes by the `BundledRecipeCatalogTests` generator (drift test).
enum DietaryInference {

    /// Meat, fish and their by-products (gelatin, lard, fish sauces, pastes made with shrimp or fish).
    static let meatWords: Set<String> = [
        "anchovy", "anchovies", "bacon", "basa", "beef", "belacan", "bonito", "bone", "bones", "brisket", "calamari",
        "caviar", "chicken", "chorizo", "cod", "crab", "dashi", "duck", "fish", "gammon", "gelatin", "gelatine",
        "goat", "haddock", "halibut", "ham", "hen", "katsuobushi", "kimchi", "laksa", "lamb", "lard", "lobster",
        "mackerel", "meat", "meatballs", "mince", "mussels", "mutton", "nuoc", "octopus", "oyster", "oysters",
        "pancetta", "parmesan", "pecorino", "pepperoni", "pork", "prawn", "prawns", "prosciutto", "quail", "roe",
        "salami", "salmon", "sardine", "sardines", "sausage", "sausages", "scallops", "seafood", "shrimp", "sirloin",
        "squid", "steak", "suet", "tallow", "tilapia", "tuna", "turkey", "veal", "venison", "worcestershire"
    ]

    /// Animal products a vegetarian eats but a vegan doesn't (dairy, eggs, honey, and foods usually made with them —
    /// "mein" because chow mein / lo mein noodles are usually egg noodles).
    static let animalProductWords: Set<String> = [
        "butter", "buttercream", "buttermilk", "cheddar", "cheese", "chocolate", "condensed", "cream", "curd",
        "custard", "dairy", "egg", "eggs", "frosting", "ganache", "ghee", "gouda", "honey", "kaya", "lactose",
        "ladyfingers", "margarine", "mascarpone", "mayo", "mayonnaise", "mein", "meringue", "milk", "mozzarella", "nutella",
        "paneer", "raita", "shortcrust", "streusel", "whey", "yoghurt", "yogurt", "yolk", "yolks"
    ]

    /// A word right before an animal-product word that makes it a plant one ("coconut milk", "peanut butter",
    /// "plant-based milk").
    static let plantQualifiers: Set<String> = [
        "almond", "based", "bean", "cacao", "cashew", "cocoa", "coconut", "nut", "oat", "peanut", "plant", "soy", "soya", "vegan"
    ]

    /// Stock, broth and the like are made from meat unless the line says otherwise.
    static let stockWords: Set<String> = ["bouillon", "broth", "gravy", "stock"]
    static let vegetableStockWords: Set<String> = [
        "kombu", "mushroom", "mushrooms", "veg", "vegan", "vegetable", "vegetables", "vegetarian"
    ]

    /// Only vegetarian and vegan are set; every other flag stays off.
    static func infer(_ recipe: RecipeModel) -> DietaryInfo {
        let lines = recipe.ingredients.map { words(in: $0.name) }
        guard !lines.isEmpty, lines != [["see", "recipe"]] else { return DietaryInfo() }
        let vegetarian = !containsMeat(words(in: recipe.name)) && !lines.contains(where: containsMeat)
        let vegan = vegetarian && !lines.contains(where: containsAnimalProduct)
        return DietaryInfo(isVegetarian: vegetarian, isVegan: vegan)
    }

    static func words(in text: String) -> [String] {
        text.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init)
    }

    static func containsMeat(_ words: [String]) -> Bool {
        if words.contains(where: stockWords.contains), !words.contains(where: vegetableStockWords.contains) {
            return true
        }
        return words.indices.contains { index in
            guard meatWords.contains(words[index]) else { return false }
            let next = words.indices.contains(index + 1) ? words[index + 1] : ""
            // "oyster mushrooms", "seafood mushrooms", "quail eggs"
            if ["mushroom", "mushrooms"].contains(next) { return false }
            if words[index] == "quail", ["egg", "eggs"].contains(next) { return false }
            return true
        }
    }

    static func containsAnimalProduct(_ words: [String]) -> Bool {
        words.indices.contains { index in
            guard animalProductWords.contains(words[index]) else { return false }
            if index > 0, plantQualifiers.contains(words[index - 1]) { return false }
            // "cream of tartar"
            if words[index] == "cream", Array(words.dropFirst(index + 1).prefix(2)) == ["of", "tartar"] { return false }
            return true
        }
    }
}
