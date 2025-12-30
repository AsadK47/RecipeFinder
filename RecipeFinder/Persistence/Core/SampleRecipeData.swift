import Foundation

extension PersistenceController {
    // swiftlint:disable function_body_length
    func populateDatabase() {
        let context = container.viewContext
        let fetchRequest = Recipe.fetchRequest()
        
        do {
            let existingRecipes = try context.fetch(fetchRequest)
            if !existingRecipes.isEmpty {
                debugLog("ℹ️ Database already contains \(existingRecipes.count) recipes, skipping population")
                return
            }
        } catch {
            debugLog("⚠️ Failed to check existing recipes: \(error.localizedDescription)")
        }
        
        debugLog("🔄 Populating database with sample recipes...")
        
        saveRecipe(parameters: RecipeSaveParameters(
            name: "Achari Chicken Curry (Instant Pot Version)",
            category: "Main",
            difficulty: "Medium",
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
            imageName: "default",
            isFavorite: false
        ))
        
        saveRecipe(parameters: RecipeSaveParameters(
            name: "Chicken Pot Pie",
            category: "Main",
            difficulty: "Hard",
            prepTime: "30 minutes",
            cookingTime: "45 minutes",
            baseServings: 6,
            currentServings: 6,
            ingredients: [
                // Puff Pastry
                Ingredient(baseQuantity: 231, unit: "g", name: "plain flour"),
                Ingredient(baseQuantity: 104, unit: "g", name: "unsalted butter, cold and cubed"),
                Ingredient(baseQuantity: 0.22, unit: "tsp", name: "salt"),
                Ingredient(baseQuantity: 229, unit: "ml", name: "cold water"),
                // Egg Wash
                Ingredient(baseQuantity: 1, unit: "", name: "egg, for egg wash"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "water, for egg wash"),
                // Filling
                Ingredient(baseQuantity: 500, unit: "g", name: "chicken breast, cubed (1 inch)"),
                Ingredient(baseQuantity: 220, unit: "g", name: "mushrooms, sliced"),
                Ingredient(baseQuantity: 1, unit: "", name: "medium onion, diced"),
                Ingredient(baseQuantity: 1, unit: "", name: "celery stalk, sliced"),
                Ingredient(baseQuantity: 2, unit: "", name: "carrots, sliced"),
                Ingredient(baseQuantity: 250, unit: "g", name: "frozen peas"),
                Ingredient(baseQuantity: 500, unit: "ml", name: "chicken stock (1 stock cube)"),
                Ingredient(baseQuantity: 6, unit: "tbsp", name: "unsalted butter (85g)"),
                Ingredient(baseQuantity: 118, unit: "ml", name: "double cream"),
                Ingredient(baseQuantity: 72, unit: "g", name: "plain flour"),
                Ingredient(baseQuantity: 3, unit: "cloves", name: "garlic, diced"),
                Ingredient(baseQuantity: 1, unit: "", name: "egg, whisked"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "salt"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "ground black pepper"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "chilli powder"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "dried mixed herbs"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "dried oregano")
            ],
            prePrepInstructions: [
                "Make puff pastry ahead: Using a food processor with metal blade, add flour and salt, then add 3/4 of the cold butter (cubed) and pulse 10-12 times until absorbed.",
                "Add remaining cold butter and pulse 2-3 times, then add cold water and pulse 4-5 times until dough forms a ball.",
                "On a lightly floured surface, knead dough lightly about 10 times, then roll into a 12x18 inch rectangle.",
                "Fold dough like an envelope, then fold in half, wrap in plastic and refrigerate for 1-2 hours."
            ],
            instructions: [
                "Preheat oven to 190°C (170°C fan) or gas mark 5.",
                "Melt butter in a medium-high heat pan.",
                "Add and cook chicken cubes for approximately 10 minutes.",
                "Add and cook the onions, carrots, and celery for approximately 10 minutes.",
                "Add and cook mushrooms, then mix in salt, black pepper, chilli powder, mixed herbs, and dried oregano.",
                "Reduce heat to low and add plain flour to the pan, mixing until sauce becomes paste consistency (approximately 2 minutes).",
                "Add in stock and double cream.",
                "Bring to a boil to thicken sauce, then reduce heat to simmer.",
                "Check seasoning and adjust if necessary (1 tsp salt, 1 tsp black pepper) so that it's slightly saltier and peppery.",
                "Add frozen peas (no need to cook as heat will cook them), then turn off heat to cool down.",
                "Pour mixture into an oven tray.",
                "Roll out chilled puff pastry and cover the pie, scoring a small hole in the middle for air to escape.",
                "Brush with whisked egg wash.",
                "Bake in preheated oven at 170°C (fan assisted) for 20-25 minutes until golden brown.",
                "Set aside for 10-15 minutes to cool before serving."
            ],
            notes: "A classic comfort food with homemade puff pastry. The pastry can be made ahead and refrigerated. Make sure the filling is slightly over-seasoned before baking as flavors mellow during cooking.",
            imageName: "default",
            isFavorite: false
        ))
        
        saveRecipe(parameters: RecipeSaveParameters(
            name: "Aloo Gosht - Stovetop (Mutton/Lamb and Potato Curry)",
            category: "Main",
            difficulty: "Medium",
            prepTime: "20 minutes",
            cookingTime: "2 hours 15 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 0.25, unit: "cup", name: "neutral oil (grapeseed or avocado)"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "ghee or butter"),
                Ingredient(baseQuantity: 1.2, unit: "lb", name: "bone-in goat or lamb meat, cut into 2-inch pieces, cleaned and patted dry"),
                Ingredient(baseQuantity: 1.75, unit: "tsp", name: "kosher salt, divided"),
                Ingredient(baseQuantity: 6, unit: "cloves", name: "garlic, crushed or finely chopped"),
                Ingredient(baseQuantity: 1, unit: "inch", name: "ginger, crushed or finely chopped"),
                Ingredient(baseQuantity: 1, unit: "medium", name: "yellow onion, finely chopped"),
                Ingredient(baseQuantity: 2, unit: "small", name: "tomatoes (Roma), roughly puréed or finely chopped"),
                Ingredient(baseQuantity: 1, unit: "", name: "small green chili pepper (Thai or Serrano), chopped"),
                Ingredient(baseQuantity: 2, unit: "", name: "green cardamom pods"),
                Ingredient(baseQuantity: 3, unit: "", name: "whole cloves"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "cumin seeds"),
                Ingredient(baseQuantity: 1.5, unit: "tsp", name: "coriander powder"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "cumin powder"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "red chili powder (or Kashmiri chili powder)"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "turmeric powder"),
                Ingredient(baseQuantity: 0.25, unit: "tsp", name: "ground black pepper"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "plain whole-milk yogurt, whisked"),
                Ingredient(baseQuantity: 2, unit: "small", name: "russet potatoes, peeled and cut into 1.5-2 inch cubes"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "garam masala (for garnish)"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "cilantro leaves, chopped (for garnish)")
            ],
            prePrepInstructions: [
                "Clean meat and remove excess fat, then pat dry.",
                "Finely chop onion and garlic (can use food processor to pulse, but don't blend or it will release water).",
                "Roughly purée tomatoes in food processor or finely chop.",
                "Peel and cube potatoes into 1.5-2 inch pieces."
            ],
            instructions: [
                "Heat Dutch oven or heavy-bottomed pot over medium-high heat. Add oil and ghee.",
                "Once hot, add goat or lamb meat and 3/4 tsp salt. Sauté for 6-7 minutes, stirring occasionally, until meat has changed color and seared on some edges.",
                "Add garlic and ginger and sauté for another minute until no longer raw.",
                "Add onion, tomatoes, green chili pepper, whole spices (cardamom, cloves, cumin seeds), ground spices (coriander, cumin, chili powder, turmeric, black pepper), and remaining 1 tsp salt.",
                "Add 1 to 1.25 cups water (just enough to cover 1/3 of the meat). Bring mixture to a boil.",
                "Once boiling, reduce heat to gentle simmer (low or low-medium). Cover and cook for 1 hour 30 minutes until meat is fully cooked and breaks when pressed with wooden spoon. If not tender, cook another 15-30 minutes, adding water if needed.",
                "Increase heat to high and stir occasionally to sauté out remaining water content (5-7 minutes).",
                "Once water has evaporated, continue to sauté (bhunai) for another 5-6 minutes. The masala will thicken and reduce, and oil will separate from curry.",
                "Reduce heat to low and stir in yogurt.",
                "Add potatoes and 2 to 2.25 cups water (depending on desired curry amount).",
                "Increase heat to high to bring to boil, then reduce to simmer (low/medium-low). Cover and cook for 23-25 minutes until meat and potatoes are both fork tender.",
                "Uncover and simmer until oil rises to top (2-3 minutes). Taste and adjust salt if needed.",
                "Turn off heat. Garnish with garam masala and cilantro. Serve with roti, paratha, naan, or basmati rice."
            ],
            notes: "Traditional Pakistani comfort food. The bhunai technique (sautéing to reduce and intensify flavors) is key. Oil naturally separating from masala indicates proper cooking. Can be frozen after Step 8, before adding potatoes.",
            imageName: "default",
            isFavorite: false
        ))
        
        saveRecipe(parameters: RecipeSaveParameters(
            name: "Aloo Gosht - Instant Pot (Mutton/Lamb and Potato Curry)",
            category: "Main",
            difficulty: "Medium",
            prepTime: "20 minutes",
            cookingTime: "45 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 0.25, unit: "cup", name: "neutral oil (grapeseed or avocado)"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "ghee or butter"),
                Ingredient(baseQuantity: 1.2, unit: "lb", name: "bone-in goat or lamb meat, cut into 2-inch pieces, cleaned and patted dry"),
                Ingredient(baseQuantity: 1.75, unit: "tsp", name: "kosher salt, divided"),
                Ingredient(baseQuantity: 6, unit: "cloves", name: "garlic, crushed or finely chopped"),
                Ingredient(baseQuantity: 1, unit: "inch", name: "ginger, crushed or finely chopped"),
                Ingredient(baseQuantity: 1, unit: "medium", name: "yellow onion, finely chopped"),
                Ingredient(baseQuantity: 2, unit: "small", name: "tomatoes (Roma), roughly puréed or finely chopped"),
                Ingredient(baseQuantity: 1, unit: "", name: "small green chili pepper (Thai or Serrano), chopped"),
                Ingredient(baseQuantity: 2, unit: "", name: "green cardamom pods"),
                Ingredient(baseQuantity: 3, unit: "", name: "whole cloves"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "cumin seeds"),
                Ingredient(baseQuantity: 1.5, unit: "tsp", name: "coriander powder"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "cumin powder"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "red chili powder (or Kashmiri chili powder)"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "turmeric powder"),
                Ingredient(baseQuantity: 0.25, unit: "tsp", name: "ground black pepper"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "plain whole-milk yogurt, whisked"),
                Ingredient(baseQuantity: 2, unit: "small", name: "russet potatoes, peeled and cut into 1.5-2 inch cubes"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "garam masala (for garnish)"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "cilantro leaves, chopped (for garnish)")
            ],
            prePrepInstructions: [
                "Clean meat and remove excess fat, then pat dry.",
                "Finely chop onion and garlic (can use food processor to pulse, but don't blend or it will release water).",
                "Roughly purée tomatoes in food processor or finely chop.",
                "Peel and cube potatoes into 1.5-2 inch pieces."
            ],
            instructions: [
                "Select 'Sauté - More/High' on Instant Pot. Once hot, add oil, ghee, goat or lamb meat, and 3/4 tsp salt.",
                "Sauté for 5 minutes, stirring occasionally, until meat has changed color and seared on some edges.",
                "Add garlic and ginger and sauté for a minute until no longer raw.",
                "Add onion, tomatoes, green chili pepper, whole spices (cardamom, cloves, cumin seeds), ground spices (coriander, cumin, chili powder, turmeric, black pepper), and remaining 1 tsp salt.",
                "Add up to 1/4 cup water if needed (moisture should cover at least 1/3 of meat; if onions and tomatoes have enough moisture, no water needed).",
                "Cancel Sauté. Select 'Pressure Cook - High' and set timer for 20 minutes (22 minutes if using larger pieces like shoulder or leg).",
                "Allow pressure to naturally release for 10 minutes. Meat should be fully cooked and break when pressed with wooden spoon. If not, pressure cook another 3-5 minutes.",
                "Select 'Sauté - More/High'. Once hot, stir occasionally to sauté out remaining water content (5-7 minutes).",
                "Once water has evaporated, continue to sauté (bhunai) for another 5-6 minutes. The masala will thicken and reduce, and oil will separate from curry.",
                "Cancel Sauté. Add yogurt and stir to mix.",
                "Add potatoes and 2 cups water (for curry/shorba).",
                "Select 'Pressure Cook - High' for 5-6 minutes depending on size of potatoes.",
                "Allow pressure to naturally release for 5 minutes.",
                "Taste and adjust salt. Garnish with garam masala and cilantro. Serve with roti, paratha, naan, or basmati rice."
            ],
            notes: "Instant Pot version of traditional Pakistani comfort food. The bhunai technique (sautéing to reduce flavors) is still important even with pressure cooking. Natural pressure release helps keep meat tender.",
            imageName: "default",
            isFavorite: false
        ))
        
        debugLog("✅ Default recipes added!")
    }
    // swiftlint:enable function_body_length
}
