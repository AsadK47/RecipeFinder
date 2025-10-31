import Foundation

extension PersistenceController {
    // swiftlint:disable function_body_length
    func populateDatabase() {
        clearDatabase()
        
        debugLog("🔄 Populating database with sample recipes...")
        
        saveRecipe(parameters: RecipeSaveParameters(
            name: "Achari Chicken Curry (Instant Pot Version)",
            category: "Main",
            difficulty: "Intermediate",
            prepTime: "20 minutes",
            cookingTime: "20 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 3, unit: "tbsp", name: "oil of choice"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "cumin seeds"),
                Ingredient(baseQuantity: 1, unit: "", name: "bay leaf"),
                Ingredient(baseQuantity: 1, unit: "", name: "onion, diced"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "minced garlic"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "minced ginger"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "coriander powder"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "fennel seeds"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "paprika"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "salt"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "turmeric"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "amchur (dried mango powder)"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "fenugreek (methi) seeds"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "garam masala"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "kalonji (nigella seeds)"),
                Ingredient(baseQuantity: 0.25, unit: "tsp", name: "black pepper"),
                Ingredient(baseQuantity: 0.25, unit: "tsp", name: "cayenne"),
                Ingredient(baseQuantity: 2, unit: "lbs", name: "skinless and boneless chicken thighs, cut into bite-sized pieces"),
                Ingredient(baseQuantity: 1, unit: "cup", name: "fresh tomato puree")
            ],
            prePrepInstructions: [
                "Chop onions and garlic."
            ],
            instructions: [
                "Press the sauté button on the Instant Pot, add the oil, and allow it to heat up for a minute.",
                "Once the oil is hot, add the cumin seeds and bay leaf.",
                "When the cumin seeds brown, add the diced onion and stir-fry for 6-7 minutes, or until the onions begin to brown.",
                "Add the minced garlic and ginger, stir, then add all the spices. Mix well.",
                "Add the chicken pieces and stir-fry for 5-6 minutes, or until the chicken is mostly cooked.",
                "Add the fresh tomato puree and mix well.",
                "Secure the lid, close the pressure valve, and cook for 5 minutes at high pressure.",
                "Naturally release pressure.",
                "Garnish with cilantro and serve."
            ],
            notes: "A flavorful and tangy chicken curry, perfect for pairing with naan or rice.",
            imageName: "achari_chicken_curry",
            isFavorite: false
        ))
        
        debugLog("✅ Default recipes added!")
    }
    // swiftlint:enable function_body_length
}
