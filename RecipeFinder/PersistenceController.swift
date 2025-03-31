//
//  PersistenceController.swift
//  RecipeFinder
//
//  Created by asad.e.khan on 11/12/2024.
//

import CoreData

struct Ingredient: Identifiable, Codable {
    var id: UUID = UUID()
    var baseQuantity: Double
    var quantity: Double
    var unit: String
    var name: String
    
    init(id: UUID = UUID(), baseQuantity: Double,
         quantity: Double? = nil, unit: String, name: String) {
        self.id = id
        self.baseQuantity = baseQuantity
        self.quantity = quantity ?? baseQuantity
        self.unit = unit
        self.name = name
    }
}

struct RecipeModel: Identifiable, Codable {
    var id: UUID = UUID() // Mutable to support decoding
    let name: String
    let category: String
    let difficulty: String
    let prepTime: String
    let cookingTime: String
    let baseServings: Int
    var currentServings: Int // Mutable for dynamic adjustment
    var ingredients: [Ingredient]
    let prePrepInstructions: [String]
    let instructions: [String]
    let notes: String
    
    init(
        id: UUID = UUID(),
        name: String,
        category: String,
        difficulty: String,
        prepTime: String,
        cookingTime: String,
        baseServings: Int,
        currentServings: Int,
        ingredients: [Ingredient],
        prePrepInstructions: [String],
        instructions: [String],
        notes: String
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.difficulty = difficulty
        self.prepTime = prepTime
        self.cookingTime = cookingTime
        self.baseServings = baseServings
        self.currentServings = currentServings
        self.ingredients = ingredients
        self.prePrepInstructions = prePrepInstructions
        self.instructions = instructions
        self.notes = notes
    }
}

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "RecipeModel")
        
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            try? FileManager.default.removeItem(at: storeURL)
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Failed to load persistent store: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    func clearDatabase() {
        if let storeURL = container.persistentStoreDescriptions.first?.url {
            do {
                try FileManager.default.removeItem(at: storeURL)
                print("Database cleared successfully.")
            } catch {
                print("Failed to clear database: \(error)")
            }
        }
    }
    
    func saveRecipe(
            name: String,
            category: String,
            difficulty: String,
            prepTime: String,
            cookingTime: String,
            baseServings: Int,
            currentServings: Int,
            ingredients: [Ingredient],
            prePrepInstructions: [String],
            instructions: [String],
            notes: String
    ) {
        let context = container.viewContext
        let entity = NSEntityDescription.insertNewObject(forEntityName: "Recipe", into: context)
        
        let id = UUID()
        entity.setValue(id, forKey: "id")
        
        let ingredientValues: Data
        do {
            ingredientValues = try JSONEncoder().encode(ingredients)
        } catch {
            print("Failed to encode ingredients: \(error)")
            return
        }
        print("Encoded ingredients: \(String(data: ingredientValues, encoding: .utf8) ?? "Invalid data")")
        
        let values: [String: Any] = [
            "name": name,
            "category": category,
            "difficulty": difficulty,
            "prepTime": prepTime,
            "cookingTime": cookingTime,
            "baseServings": baseServings,
            "currentServings": currentServings,
            "ingredients": ingredientValues,
            "prePrepInstructions": prePrepInstructions,
            "instructions": instructions,
            "notes": notes
        ]
        
        for (key, value) in values {
            entity.setValue(value, forKey: key)
        }
        
        do {
            try context.save()
            print("Recipe '\(name)' saved successfully!")
        } catch {
            print("Failed to save recipe: \(error)")
        }
    }
    
    func fetchRecipes() -> [RecipeModel] {
        let context = container.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Recipe")
        
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let results = try context.fetch(fetchRequest)
            print("Fetched \(results.count) recipes")
            
            return results.compactMap { result in
                let id = result.value(forKey: "id") as? UUID ?? UUID()
                let name = result.value(forKey: "name") as? String ?? "Unknown Name"
                let category = result.value(forKey: "category") as? String ?? "Uncategorised"
                let difficulty = result.value(forKey: "difficulty") as? String ?? "Unknown Name"
                let prepTime = result.value(forKey: "prepTime") as? String ?? "Unknown Prep Time"
                let cookingTime = result.value(forKey: "cookingTime") as? String ?? "Unknown Cooking Time"
                let baseServings = result.value(forKey: "baseServings") as? Int ?? 1
                let currentServings = result.value(forKey: "currentServings") as? Int ?? baseServings
                let prePrepInstructions = result.value(forKey: "prePrepInstructions") as? [String] ?? []
                let instructions = result.value(forKey: "instructions") as? [String] ?? []
                let notes = result.value(forKey: "notes") as? String ?? ""
                
                let ingredients: [Ingredient]
                if let ingredientsData = result.value(forKey: "ingredients") as? Data {
                    do {
                        ingredients = try JSONDecoder().decode([Ingredient].self, from: ingredientsData)
                    } catch {
                        print("Failed to decode ingredients: \(error.localizedDescription)")
                        ingredients = []
                    }
                } else {
                    ingredients = []
                }
                
                return RecipeModel(
                    id: id,
                    name: name,
                    category: category,
                    difficulty: difficulty,
                    prepTime: prepTime,
                    cookingTime: cookingTime,
                    baseServings: baseServings,
                    currentServings: currentServings,
                    ingredients: ingredients,
                    prePrepInstructions: prePrepInstructions,
                    instructions: instructions,
                    notes: notes
                )
            }
        } catch {
            print("Failed to fetch recipes from Core Data \(error.localizedDescription)")
            return []
        }
    }
}

extension PersistenceController {
    func populateDatabase() {
        let context = container.viewContext
        
        let fetchRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Recipe")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Failed to clear existing data: \(error)")
        }
        
        saveRecipe(
            name: "Achari Chicken Curry (Instant Pot Version)",
            category: "Main Course",
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
            notes: "A flavorful and tangy chicken curry, perfect for pairing with naan or rice."
        )
        
        saveRecipe(
            name: "Air Fryer Crispy Chilli Beef",
            category: "Main Course",
            difficulty: "Medium",
            prepTime: "15 minutes",
            cookingTime: "10 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 500, unit: "g", name: "beef steak, sliced into strips"),
                Ingredient(baseQuantity: 3, unit: "tbsp", name: "cornflour"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "soy sauce"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "sweet chilli sauce"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "rice vinegar"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "ketchup"),
                Ingredient(baseQuantity: 1, unit: "", name: "red chilli, finely sliced"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "vegetable oil"),
                Ingredient(baseQuantity: 2, unit: "", name: "spring onions, finely sliced")
            ],
            prePrepInstructions: [
                "Slice the beef into thin strips and pat dry."
            ],
            instructions: [
                "Place the beef strips in a bowl, add cornflour, and toss to coat evenly.",
                "Preheat the air fryer to 200°C.",
                "Lightly spray the air fryer basket with oil and add the beef strips in a single layer.",
                "Cook for 8-10 minutes, shaking halfway through until crispy.",
                "In a separate bowl, mix soy sauce, sweet chilli sauce, rice vinegar, ketchup, and red chilli.",
                "Heat the sauce mixture in a pan until it starts to thicken.",
                "Add the cooked beef to the pan and toss to coat in the sauce.",
                "Garnish with spring onions before serving."
            ],
            notes: "Serve immediately with steamed rice or noodles for a delicious and crispy meal."
        )
        
        saveRecipe(
            name: "Achari Gosht (Hot & Sour Lamb Curry Instant Pot Version)",
            category: "Main Course",
            difficulty: "Medium",
            prepTime: "25 minutes",
            cookingTime: "40 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 3, unit: "tbsp", name: "mustard oil"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "fenugreek seeds"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "fennel seeds"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "mustard seeds"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "nigella seeds"),
                Ingredient(baseQuantity: 2, unit: "", name: "large onions, finely sliced"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "minced garlic"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "minced ginger"),
                Ingredient(baseQuantity: 2, unit: "", name: "large tomatoes, pureed"),
                Ingredient(baseQuantity: 1, unit: "cup", name: "yogurt, whisked"),
                Ingredient(baseQuantity: 1.5, unit: "tsp", name: "turmeric powder"),
                Ingredient(baseQuantity: 1.5, unit: "tsp", name: "red chili powder"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "coriander powder"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "garam masala"),
                Ingredient(baseQuantity: 2, unit: "lbs", name: "lamb pieces, bone-in"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "salt, or to taste"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "vinegar"),
                Ingredient(baseQuantity: 2, unit: "", name: "green chilies, slit"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "fresh cilantro, chopped (for garnish)")
            ],
            prePrepInstructions: [
                "Puree the tomatoes and whisk the yogurt."
            ],
            instructions: [
                "Turn on the sauté function on the Instant Pot and heat mustard oil until it begins to smoke slightly.",
                "Add fenugreek seeds, fennel seeds, mustard seeds, and nigella seeds. Sauté until aromatic.",
                "Add sliced onions and cook until golden brown.",
                "Stir in minced garlic and ginger, cooking for another 2 minutes.",
                "Add pureed tomatoes, yogurt, turmeric, red chili powder, and coriander powder. Mix well.",
                "Add lamb pieces and sauté for 5-7 minutes until coated in the spice mixture.",
                "Pour in 1 cup of water, close the lid, and pressure cook on high for 25 minutes.",
                "Naturally release pressure for 10 minutes before opening the lid.",
                "Add garam masala, vinegar, and slit green chilies. Mix well.",
                "Garnish with chopped cilantro and serve hot."
            ],
            notes: "Pairs well with naan, roti, or steamed basmati rice. Adjust spices to taste for a milder or spicier curry."
        )
        
        saveRecipe(
            name: "Air-Fryer Doughnuts",
            category: "Dessert",
            difficulty: "Medium",
            prepTime: "15 minutes",
            cookingTime: "15 minutes",
            baseServings: 12,
            currentServings: 12,
            ingredients: [
                Ingredient(baseQuantity: 2, unit: "cups", name: "all-purpose flour"),
                Ingredient(baseQuantity: 0.25, unit: "cup", name: "sugar"),
                Ingredient(baseQuantity: 2.5, unit: "tsp", name: "baking powder"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "salt"),
                Ingredient(baseQuantity: 0.5, unit: "cup", name: "milk"),
                Ingredient(baseQuantity: 2, unit: "", name: "large eggs"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "unsalted butter, melted"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "vanilla extract"),
                Ingredient(baseQuantity: 1, unit: "cup", name: "powdered sugar (for coating)")
            ],
            prePrepInstructions: [
                "Combine dry ingredients in a bowl."
            ],
            instructions: [
                "In a separate bowl, whisk wet ingredients together.",
                "Combine wet and dry ingredients to form a dough.",
                "Shape into doughnuts.",
                "Air fry at 350°F for 5-6 minutes until golden.",
                "Coat with powdered sugar before serving."
            ],
            notes: "A healthier twist on a classic treat. Best served fresh."
        )
        
        saveRecipe(
            name: "Air Fryer Korean Fried Chicken",
            category: "Appetizer",
            difficulty: "Hard",
            prepTime: "20 minutes",
            cookingTime: "25 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 2, unit: "lbs", name: "chicken wings"),
                Ingredient(baseQuantity: 0.5, unit: "cup", name: "cornstarch"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "soy sauce"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "ginger, grated"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "gochujang (Korean chili paste)"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "honey"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "sesame oil"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "scallions, chopped"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "sesame seeds")
            ],
            prePrepInstructions: [
                "Pat chicken wings dry.",
                "Combine cornstarch, soy sauce, and grated ginger."
            ],
            instructions: [
                "Coat chicken wings with the cornstarch mixture.",
                "Air fry at 375°F for 15 minutes, turning halfway.",
                "Prepare sauce by mixing gochujang, honey, and sesame oil.",
                "Toss cooked wings in sauce and garnish with scallions and sesame seeds."
            ],
            notes: "Crispy, spicy, and savory, these wings pair well with a cold drink."
        )
        
        saveRecipe(
            name: "Air Fryer Southern Fried Chicken",
            category: "Main Course",
            difficulty: "Medium",
            prepTime: "30 minutes",
            cookingTime: "20 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 4, unit: "", name: "chicken drumsticks"),
                Ingredient(baseQuantity: 1, unit: "cup", name: "buttermilk"),
                Ingredient(baseQuantity: 1, unit: "cup", name: "all-purpose flour"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "paprika"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "garlic powder"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "onion powder"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "cayenne pepper"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "salt"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "black pepper")
            ],
            prePrepInstructions: [
                "Marinate chicken in buttermilk for 2 hours or overnight."
            ],
            instructions: [
                "Mix flour and spices in a bowl.",
                "Coat chicken in the flour mixture.",
                "Place chicken in the air fryer and spray lightly with oil.",
                "Air fry at 375°F for 20 minutes, flipping halfway through."
            ],
            notes: "Crispy, flavorful chicken with less grease—perfect for any occasion."
        )
        
        saveRecipe(
            name: "Air Fryer Soy Sauce Chicken Wings",
            category: "Appetizer",
            difficulty: "Easy",
            prepTime: "10 minutes",
            cookingTime: "20 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 2, unit: "lbs", name: "chicken wings"),
                Ingredient(baseQuantity: 0.25, unit: "cup", name: "soy sauce"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "honey"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "ginger, grated"),
                Ingredient(baseQuantity: 2, unit: "cloves", name: "garlic, minced"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "sesame oil"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "black pepper"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "sesame seeds (optional)")
            ],
            prePrepInstructions: [
                "Mix soy sauce, honey, ginger, garlic, sesame oil, and black pepper in a bowl."
            ],
            instructions: [
                "Marinate chicken wings in the sauce for 30 minutes.",
                "Place wings in air fryer and cook at 375°F for 20 minutes, flipping halfway.",
                "Garnish with sesame seeds before serving."
            ],
            notes: "Juicy and savory wings, perfect for game day."
        )
        
        saveRecipe(
            name: "Aloo Gosht (Mutton/Lamb and Potato Curry)",
            category: "Main Course",
            difficulty: "Medium",
            prepTime: "20 minutes",
            cookingTime: "1 hour",
            baseServings: 6,
            currentServings: 6,
            ingredients: [
                Ingredient(baseQuantity: 2, unit: "lbs", name: "mutton or lamb, bone-in"),
                Ingredient(baseQuantity: 4, unit: "medium", name: "potatoes, peeled and cubed"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "vegetable oil"),
                Ingredient(baseQuantity: 2, unit: "large", name: "onions, finely sliced"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "ginger paste"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "garlic paste"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "turmeric powder"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "red chili powder"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "coriander powder"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "cumin seeds"),
                Ingredient(baseQuantity: 3, unit: "cups", name: "water"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "cilantro, chopped (for garnish)")
            ],
            prePrepInstructions: [
                "Wash and cut mutton into pieces."
            ],
            instructions: [
                "Heat oil in a large pot and fry onions until golden brown.",
                "Add ginger and garlic paste, followed by spices.",
                "Add mutton and cook until browned.",
                "Add potatoes and water, and simmer until tender.",
                "Garnish with chopped cilantro before serving."
            ],
            notes: "A hearty and comforting curry, best served with naan or rice."
        )
        
        saveRecipe(
            name: "American Pancakes",
            category: "Breakfast",
            difficulty: "Easy",
            prepTime: "5 minutes",
            cookingTime: "10 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 200, unit: "g", name: "self-raising flour"),
                Ingredient(baseQuantity: 1.5, unit: "tsp", name: "baking powder"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "golden caster sugar"),
                Ingredient(baseQuantity: 3, unit: "large", name: "eggs"),
                Ingredient(baseQuantity: 25, unit: "g", name: "melted butter"),
                Ingredient(baseQuantity: 200, unit: "ml", name: "milk"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "vegetable oil"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "maple syrup"),
                Ingredient(baseQuantity: 1, unit: "assorted", name: "toppings (e.g., bacon, chocolate chips, blueberries, peanut butter, jam)")
            ],
            prePrepInstructions: [
                "Mix self-raising flour, baking powder, golden caster sugar, and a pinch of salt together in a large bowl."
            ],
            instructions: [
                "Create a well in the centre with the back of your spoon, then add eggs, melted butter, and milk.",
                "Whisk together with a balloon whisk or electric hand beaters until smooth, then pour into a jug.",
                "Heat a small knob of butter and vegetable oil in a large, non-stick frying pan over medium heat.",
                "When the butter looks frothy, pour in rounds of the batter, approximately 8cm wide.",
                "Cook pancakes on one side for about 1-2 minutes or until tiny bubbles appear and pop on the surface.",
                "Flip pancakes over and cook for another minute on the other side. Repeat until all batter is used.",
                "Serve pancakes stacked with a drizzle of maple syrup and your favourite toppings."
            ],
            notes: "American pancakes are a classic breakfast dish. Experiment with different toppings like fresh fruits, whipped cream, or savory additions like bacon."
        )
        
        saveRecipe(
            name: "Apam Balik",
            category: "Dessert",
            difficulty: "Medium",
            prepTime: "10 minutes",
            cookingTime: "20 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 5, unit: "ml", name: "unsalted butter (for greasing the pan, or substitute with dairy-free butter or neutral oil)"),
                Ingredient(baseQuantity: 135, unit: "g", name: "all-purpose flour"),
                Ingredient(baseQuantity: 63, unit: "g", name: "self-rising flour"),
                Ingredient(baseQuantity: 3, unit: "g", name: "baking soda"),
                Ingredient(baseQuantity: 0.8, unit: "g", name: "salt"),
                Ingredient(baseQuantity: 500, unit: "ml", name: "warm milk (or substitute with plain oat milk for a dairy-free version)"),
                Ingredient(baseQuantity: 4.7, unit: "g", name: "dry active yeast"),
                Ingredient(baseQuantity: 10, unit: "ml", name: "vanilla extract"),
                Ingredient(baseQuantity: 24, unit: "g", name: "white granulated sugar"),
                Ingredient(baseQuantity: 1, unit: "large", name: "egg (room temperature)"),
                Ingredient(baseQuantity: 1, unit: "as desired", name: "white granulated sugar (for topping)"),
                Ingredient(baseQuantity: 1, unit: "as desired", name: "crushed peanuts (for topping)"),
                Ingredient(baseQuantity: 250, unit: "ml", name: "creamed corn (canned)"),
                Ingredient(baseQuantity: 1, unit: "as needed", name: "unsalted butter (or substitute with vegan butter)")
            ],
            prePrepInstructions: [
                "Sift and whisk all-purpose flour, self-rising flour, baking soda, and salt in a large mixing bowl.",
                "In a medium-sized bowl, whisk together warm milk, dry active yeast, vanilla extract, and sugar. Allow the yeast to dissolve completely.",
                "Whisk the milk mixture into the dry ingredients, then crack an egg into the batter and whisk just until combined. Do not overmix.",
                "Cover the bowl and rest the pancake batter for 30 minutes (or 60 minutes if you have extra time)."
            ],
            instructions: [
                "Set a 10-inch pan over medium-low heat and lightly grease it with butter using a clean paper towel.",
                "Ladle the batter into the pan and spread it into an even pancake.",
                "Swirl the batter against the wall of the pan to create a thin crust, then cover the pan with a lid.",
                "Cook until bubbles form all over the pancake (about 2-3 minutes).",
                "Evenly sprinkle sugar, creamed corn, crushed peanuts, and small slices of butter across the pancake.",
                "Cover the pan with a lid for 2 minutes so the creamed corn can warm up.",
                "Remove the lid and fold one side of the pancake over the other to create a semi-circle.",
                "Slide the pancake onto a cutting board, slice it in half with a sharp knife, and repeat for the remaining batter. Enjoy!"
            ],
            notes: "Apam Balik is a popular Malaysian street food pancake filled with sweet and savory fillings. For a dairy-free version, use oat milk and vegan butter. Enjoy it as a dessert, snack, or breakfast."
        )
        
        saveRecipe(
            name: "Apple Crumble",
            category: "Dessert",
            difficulty: "Easy",
            prepTime: "10 minutes",
            cookingTime: "25-30 minutes",
            baseServings: 6,
            currentServings: 6,
            ingredients: [
                Ingredient(baseQuantity: 350, unit: "g", name: "Bramley apples (approx. 4-5)"),
                Ingredient(baseQuantity: 100, unit: "g", name: "Demerara sugar (for filling)"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "ground nutmeg"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "ground cinnamon"),
                Ingredient(baseQuantity: 1, unit: "box", name: "shortcrust pastry"),
                Ingredient(baseQuantity: 1, unit: "as needed", name: "water"),
                Ingredient(baseQuantity: 112.5, unit: "g", name: "Demerara sugar (for crumble)"),
                Ingredient(baseQuantity: 45, unit: "g", name: "oats"),
                Ingredient(baseQuantity: 75, unit: "g", name: "plain flour"),
                Ingredient(baseQuantity: 90, unit: "g", name: "cold butter"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "ground cinnamon (for crumble)"),
                Ingredient(baseQuantity: 1, unit: "to serve", name: "custard")
            ],
            prePrepInstructions: [
                "Defrost the butter and pastry.",
                "Peel and chop the apples into cubes.",
                "Preheat the oven to 200°C (180°C Fan)/Gas 6."
            ],
            instructions: [
                "Sprinkle 100g Demerara sugar evenly over the chopped apples in a saucepan.",
                "Add 1/2 teaspoon nutmeg, 1/2 teaspoon cinnamon, and water to the apples. Cover and cook until translucent.",
                "In a bowl, mix 90g butter, 112.5g sugar, 75g flour, and 45g oats until a crumble forms. Add 1/2 teaspoon cinnamon to the crumble mix.",
                "Preheat the oven to Gas Mark 5/375°F/190°C.",
                "Grease the two tins and blind bake the pastry for about 6 minutes.",
                "Remove the cooked apple from the stove and set aside.",
                "Arrange the shortcrust pastry in the oven dish and add the cooked apple.",
                "Distribute the crumble mix over the apples and pat it down with a spatula.",
                "Bake for 25 minutes or until the crumble is toasted golden.",
                "Sprinkle cinnamon sugar and serve with custard."
            ],
            notes: "Apple crumble is a versatile dessert that pairs well with custard, vanilla ice cream, or chilled double cream. For added flavor, consider adding 1 tsp of cinnamon to the apples before cooking. You can substitute Hob Nobs for digestive biscuits in the crumble for a different texture. Serve warm with custard or vanilla ice cream. Adjust sugar based on the sweetness of the apples used."
        )
        
        saveRecipe(
            name: "Apple Crumble",
            category: "Dessert",
            difficulty: "Easy",
            prepTime: "10 minutes",
            cookingTime: "30 minutes",
            baseServings: 6,
            currentServings: 6,
            ingredients: [
                Ingredient(baseQuantity: 1000, unit: "g", name: "Bramley apples (2lb 3½oz)"),
                Ingredient(baseQuantity: 1, unit: "pinch", name: "sugar, to taste"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "water or apple juice"),
                Ingredient(baseQuantity: 100, unit: "g", name: "plain flour"),
                Ingredient(baseQuantity: 75, unit: "g", name: "butter"),
                Ingredient(baseQuantity: 50, unit: "g", name: "rolled oats"),
                Ingredient(baseQuantity: 100, unit: "g", name: "demerara sugar")
            ],
            prePrepInstructions: [
                "Preheat the oven to 200°C (180°C Fan)/Gas 6."
            ],
            instructions: [
                "Wipe the apples and cut them into quarters. Remove the cores and slice each piece in two.",
                "Put the apples into a pan. Taste a slice for sweetness and add sugar accordingly. Add a tablespoon of water or apple juice and cook over medium heat for about 5 minutes until softened.",
                "Transfer the apple mixture to a shallow ovenproof dish.",
                "Blend the flour and butter in a food processor until the mixture resembles breadcrumbs.",
                "Stir in the oats and brown sugar, then sprinkle over the cooked apples in the dish.",
                "Bake for 30 minutes or until crisp and golden brown on top."
            ],
            notes: "Serve warm with custard or vanilla ice cream. Adjust sugar based on the sweetness of the apples used."
        )
        
        saveRecipe(
            name: "Apple Jalebi (Gluten Free, Paleo, Vegan)",
            category: "Dessert",
            difficulty: "Hard",
            prepTime: "10 hours (fermentation) + 15 minutes",
            cookingTime: "15 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 1, unit: "as needed", name: "avocado oil or fat of choice (for frying)"),
                Ingredient(baseQuantity: 0.5, unit: "cup", name: "almond flour"),
                Ingredient(baseQuantity: 0.5, unit: "cup", name: "arrowroot flour (for batter)"),
                Ingredient(baseQuantity: 0.5, unit: "cup", name: "full-fat canned coconut milk"),
                Ingredient(baseQuantity: 40, unit: "to 50 billion", name: "probiotic cultures (capsules)"),
                Ingredient(baseQuantity: 0.25, unit: "cup", name: "water (for batter)"),
                Ingredient(baseQuantity: 0.25, unit: "cup", name: "arrowroot flour (for coating)"),
                Ingredient(baseQuantity: 2, unit: "medium", name: "apples (peeled, cored, and sliced)"),
                Ingredient(baseQuantity: 0.5, unit: "cup", name: "coconut sugar"),
                Ingredient(baseQuantity: 0.25, unit: "cup", name: "water (for syrup)"),
                Ingredient(baseQuantity: 0.25, unit: "tsp", name: "ground cardamom"),
                Ingredient(baseQuantity: 1, unit: "as needed", name: "crushed pistachios (for garnish)")
            ],
            prePrepInstructions: [
                "Prepare the batter by combining almond flour, arrowroot flour, and coconut milk in a bowl.",
                "Empty the contents of the probiotic capsules into the bowl and mix well.",
                "Loosely cover the bowl with a lid and place it in an oven with only the oven light on (do not turn on the oven) for at least 10 hours to ferment the batter."
            ],
            instructions: [
                "Add ¼ cup water to the fermented batter and mix well.",
                "Heat oil in a wok or a deep, wide-bottomed pot to 360°F or until a small drop of the batter sizzles and floats to the top.",
                "While the oil is heating, add ¼ cup arrowroot flour to a plate. Dip the apple slices on both sides into the arrowroot flour.",
                "Dip the apple slices into the fermented batter, then place them into the hot oil. Fry 2-3 apple slices at a time until both sides are light golden brown.",
                "Remove the fried apple slices and set them aside on a paper-towel-lined plate.",
                "Dip the fried apple slices into the cooled syrup, garnish with crushed pistachios, and serve."
            ],
            notes: "This delicious Malaysian-inspired dessert uses probiotics to ferment the batter, resulting in a light and flavorful dish. The syrup can be prepared ahead of time and cooled for dipping. Experiment with different oils or vegan butter substitutes for frying. Adjust the number of probiotic capsules based on the culture count (40-50 billion)."
        )
        
        saveRecipe(
            name: "Apple Crisp with Oat Topping",
            category: "Dessert",
            difficulty: "Easy",
            prepTime: "10 minutes",
            cookingTime: "35-40 minutes",
            baseServings: 6,
            currentServings: 6,
            ingredients: [
                Ingredient(baseQuantity: 6, unit: "medium", name: "apples (peeled, cored, and sliced)"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "white sugar"),
                Ingredient(baseQuantity: 1.5, unit: "tsp", name: "ground cinnamon (divided)"),
                Ingredient(baseQuantity: 1, unit: "cup", name: "brown sugar"),
                Ingredient(baseQuantity: 0.75, unit: "cup", name: "old-fashioned oats"),
                Ingredient(baseQuantity: 0.75, unit: "cup", name: "all-purpose flour"),
                Ingredient(baseQuantity: 0.5, unit: "cup", name: "cold butter")
            ],
            prePrepInstructions: [
                "Preheat the oven to 350°F (175°C)."
            ],
            instructions: [
                "Toss apples with white sugar and ½ teaspoon cinnamon in a medium bowl to coat. Pour into a 9-inch square baking dish.",
                "Mix brown sugar, oats, flour, and 1 teaspoon cinnamon in a separate bowl.",
                "Cut in cold butter with two knives or a pastry blender until the mixture resembles coarse crumbs.",
                "Spread over apples and pat down gently until even.",
                "Bake in the preheated oven until golden brown and sides are bubbling, about 35-40 minutes."
            ],
            notes: "Use high-quality cinnamon for a richer flavor. Serve with ice cream or whipped cream for an extra treat."
        )
        
        saveRecipe(
            name: "Apple Oat Crumble",
            category: "Dessert",
            difficulty: "Easy",
            prepTime: "20 minutes",
            cookingTime: "30 minutes",
            baseServings: 6,
            currentServings: 6,
            ingredients: [
                Ingredient(baseQuantity: 700, unit: "g", name: "apples, peeled, cored, and sliced finely"),
                Ingredient(baseQuantity: 3, unit: "tbsp", name: "brown sugar"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "plain white flour"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "lemon juice (or water)"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "ground cinnamon"),
                Ingredient(baseQuantity: 0.75, unit: "cup", name: "plain white flour (112g)"),
                Ingredient(baseQuantity: 0.75, unit: "cup", name: "rolled oats (63g)"),
                Ingredient(baseQuantity: 0.5, unit: "cup", name: "brown sugar (100g)"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "ground cinnamon"),
                Ingredient(baseQuantity: 0.25, unit: "tsp", name: "salt"),
                Ingredient(baseQuantity: 120, unit: "g", name: "cold butter, cubed")
            ],
            prePrepInstructions: [
                "Preheat the oven to 190°C (375°F)."
            ],
            instructions: [
                "Peel and core the apples, then slice finely and place in a medium bowl.",
                "Add the first measure of brown sugar, flour, lemon juice, and cinnamon. Mix to coat the apples.",
                "Pour into a baking dish and press the apples flat in the dish to remove gaps.",
                "In a medium bowl, combine the flour, oats, second measure of brown sugar, cinnamon, and salt. Mix well.",
                "Rub in the cubed butter into the flour and oats mixture until it forms moist breadcrumbs.",
                "Sprinkle the crumble mixture evenly over the apples.",
                "Bake for at least 30 minutes until golden brown and bubbling.",
                "Let sit for 20 minutes before serving."
            ],
            notes: "Serve with ice cream, custard, or cream. This dish can be reheated or frozen for later use."
        )
        
        saveRecipe(
            name: "Apple Crumble with Spiced Filling",
            category: "Dessert",
            difficulty: "Medium",
            prepTime: "15 minutes",
            cookingTime: "18-22 minutes",
            baseServings: 6,
            currentServings: 6,
            ingredients: [
                Ingredient(baseQuantity: 5, unit: "medium", name: "apples, peeled and cut into 1-inch pieces"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "apple cider vinegar"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "water"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "cinnamon"),
                Ingredient(baseQuantity: 0.25, unit: "tsp", name: "ground ginger"),
                Ingredient(baseQuantity: 0.25, unit: "tsp", name: "nutmeg"),
                Ingredient(baseQuantity: 1, unit: "pinch", name: "sea salt"),
                Ingredient(baseQuantity: 0.5, unit: "cup", name: "almond flour"),
                Ingredient(baseQuantity: 0.33, unit: "cup", name: "all-purpose flour"),
                Ingredient(baseQuantity: 0.33, unit: "cup", name: "whole rolled oats"),
                Ingredient(baseQuantity: 0.33, unit: "cup", name: "crushed walnuts"),
                Ingredient(baseQuantity: 0.33, unit: "cup", name: "brown sugar or coconut sugar"),
                Ingredient(baseQuantity: 0.33, unit: "cup", name: "melted coconut oil"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "cinnamon"),
                Ingredient(baseQuantity: 0.25, unit: "heaping tsp", name: "sea salt"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "water, if needed")
            ],
            prePrepInstructions: [
                "Preheat the oven to 400°F and grease an 8x8-inch baking dish."
            ],
            instructions: [
                "Combine the apples, apple cider vinegar, and water in a saucepan. Simmer over very low heat, covered, for 15 minutes, stirring occasionally.",
                "Uncover, add cinnamon, ginger, nutmeg, and salt. Stir well. The apples should be tender, and the juices should thicken.",
                "In a food processor, pulse the almond flour, all-purpose flour, oats, walnuts, sugar, coconut oil, cinnamon, and salt until crumbly. Add water if needed.",
                "Scoop the apple filling into the prepared baking dish. Sprinkle the topping evenly over the filling.",
                "Bake for 18-22 minutes or until lightly crisp on top."
            ],
            notes: "This recipe has a delightful spiced twist. Garnish with additional walnuts or a dollop of whipped cream for extra flavor."
        )
        
        saveRecipe(
            name: "Asian Lemon Wings",
            category: "Main Course",
            difficulty: "Medium",
            prepTime: "20 minutes",
            cookingTime: "16 minutes (air fry) or 8 minutes (deep fry)",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 907, unit: "g", name: "chicken wings (about 22 wings)"),
                Ingredient(baseQuantity: 120, unit: "g", name: "corn starch or potato starch/tapioca starch"),
                Ingredient(baseQuantity: 30, unit: "ml", name: "vegetable oil"),
                Ingredient(baseQuantity: 30, unit: "ml", name: "regular soy sauce (for marinade)"),
                Ingredient(baseQuantity: 4, unit: "g", name: "chicken bouillon powder (for marinade)"),
                Ingredient(baseQuantity: 1, unit: "g", name: "ginger powder (for marinade)"),
                Ingredient(baseQuantity: 4.5, unit: "g", name: "garlic powder (for marinade)")
            ],
            prePrepInstructions: [
                "Marinate chicken wings with soy sauce, chicken bouillon powder, ginger powder, and garlic powder for 10 minutes."
            ],
            instructions: [
                "Coat marinated wings with cornstarch or potato starch.",
                "Air fry or deep fry the wings as per instructions.",
                "Toss hot wings in sweet lemon sauce and serve."
            ],
            notes: "Crispy, tangy, and delicious wings with an Asian twist!"
        )
        
        saveRecipe(
            name: "Baingan ka Bharta (Indian Eggplant)",
            category: "Main Course",
            difficulty: "Medium",
            prepTime: "10 minutes",
            cookingTime: "50 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 2, unit: "large", name: "eggplants"),
                Ingredient(baseQuantity: 4, unit: "tbsp", name: "oil, divided"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "cumin seeds"),
                Ingredient(baseQuantity: 1, unit: "large", name: "white onion, finely chopped"),
                Ingredient(baseQuantity: 5, unit: "cloves", name: "garlic, minced"),
                Ingredient(baseQuantity: 1, unit: "inch", name: "knob ginger, minced"),
                Ingredient(baseQuantity: 1-2, unit: "pieces", name: "Serrano peppers, minced (adjust to preference)"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "coriander powder"),
                Ingredient(baseQuantity: 2, unit: "tsp", name: "salt"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "black pepper"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "garam masala"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "paprika"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "turmeric powder"),
                Ingredient(baseQuantity: 3, unit: "medium", name: "tomatoes, chopped"),
                Ingredient(baseQuantity: 1, unit: "handful", name: "cilantro, chopped (for garnish)")
            ],
            prePrepInstructions: [
                "Preheat the oven to 500°F.",
                "Make four slits in each eggplant and coat them with 1 tablespoon of oil each.",
                "Place eggplants on a baking sheet and roast in the oven for 40 minutes, flipping halfway through.",
                "Turn the oven to broil for the last 5 minutes. Remove the eggplants and allow them to cool.",
                "Peel off the skin from the eggplants and chop the flesh. Set aside."
            ],
            instructions: [
                "While the eggplants are roasting, heat 2 tablespoons of oil in a Dutch oven or heavy pot over medium heat.",
                "Add cumin seeds and wait for them to splutter.",
                "Add onions and sauté for 10 minutes until golden brown.",
                "Stir in garlic, ginger, Serrano pepper, and spices. Stir-fry for 1 minute.",
                "Add chopped tomatoes, mix well, cover the pot, and cook for 10 minutes.",
                "Uncover and stir-fry for another 5 minutes.",
                "Add the roasted and chopped eggplant, mix, and cook for an additional 5 minutes.",
                "Garnish with chopped cilantro and serve hot."
            ],
            notes: "Baingan ka Bharta is a traditional Indian dish known for its smoky flavor, thanks to the roasted eggplant. Serve it with naan, roti, or steamed rice for a comforting meal. This dish originates from North India and is a staple in many households."
        )
        
        saveRecipe(
            name: "Baked Cajun Garlic Butter Cod",
            category: "Main Course",
            difficulty: "Easy",
            prepTime: "5 minutes",
            cookingTime: "15 minutes",
            baseServings: 3,
            currentServings: 3,
            ingredients: [
                Ingredient(baseQuantity: 3, unit: "filets", name: "cod, cut in half"),
                Ingredient(baseQuantity: 1, unit: "pinch", name: "salt and pepper, to taste"),
                Ingredient(baseQuantity: 0.25, unit: "cup", name: "butter, melted"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "olive oil"),
                Ingredient(baseQuantity: 3, unit: "cloves", name: "garlic, minced"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "Cajun seasoning")
            ],
            prePrepInstructions: [
                "Preheat oven to 400°F (200°C).",
                "Cut cod filets in half and place in a 9x13 inch baking dish."
            ],
            instructions: [
                "Sprinkle cod with salt and pepper.",
                "In a small bowl, whisk together melted butter, olive oil, garlic, and Cajun seasoning to make the Cajun Garlic Butter Sauce.",
                "Spread the sauce evenly over the fish.",
                "Bake for about 15 minutes or until the fish is opaque and flakes easily."
            ],
            notes: "This dish pairs wonderfully with steamed vegetables or a side of rice. Cajun seasoning adds a spicy kick, but feel free to adjust based on your spice tolerance!"
        )
        
        saveRecipe(
            name: "Banana Roti - Thai Banana Pancakes",
            category: "Dessert",
            difficulty: "Medium",
            prepTime: "3+ hours (including resting time for dough)",
            cookingTime: "20 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 1.5, unit: "tsp", name: "salt"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "sweetened condensed milk (or sugar substitute)"),
                Ingredient(baseQuantity: 1, unit: "large", name: "egg"),
                Ingredient(baseQuantity: 260, unit: "ml", name: "water"),
                Ingredient(baseQuantity: 500, unit: "g", name: "all-purpose flour"),
                Ingredient(baseQuantity: 55, unit: "g", name: "unsalted butter, room temperature"),
                Ingredient(baseQuantity: 1.5, unit: "tbsp", name: "unsalted butter, for coating the dough"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "neutral-flavored oil, for coating the dough"),
                Ingredient(baseQuantity: 3, unit: "tbsp", name: "neutral-flavored oil, for cooking"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "extra unsalted butter, optional for cooking"),
                Ingredient(baseQuantity: 2, unit: "medium", name: "bananas, sliced"),
                Ingredient(baseQuantity: 3, unit: "tbsp", name: "sweetened condensed milk, for drizzling"),
                Ingredient(baseQuantity: 3, unit: "tbsp", name: "Nutella or chocolate sauce"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "granulated sugar, for sprinkling")
            ],
            prePrepInstructions: [
                "In a large bowl, mix salt and water until dissolved.",
                "Add condensed milk and egg, and whisk to combine.",
                "In another bowl, combine flour and butter.",
                "Rub butter into the flour until no large chunks remain.",
                "Add the flour mixture to the wet ingredients and knead until the dry flour is absorbed.",
                "Let rest for 15-30 minutes.",
                "Knead the dough for 5 minutes until moist but not sticky.",
                "Let rest for 10-15 minutes.",
                "Cut dough into 80g pieces and form into balls.",
                "Brush with a butter-oil mixture and store in a container.",
                "Allow to rest for at least 3 hours (or refrigerate overnight)."
            ],
            instructions: [
                "Preheat a flat skillet over medium heat and generously coat with oil.",
                "Stretch each dough ball into a very thin sheet.",
                "Transfer stretched dough carefully to the pan.",
                "Place banana slices or other filling in the center and fold the edges of the dough over to seal.",
                "Cook until both sides are golden and crispy, flipping every minute (about 4-5 minutes total).",
                "Optionally, add a small piece of butter to the pan, let it melt, and coat the roti.",
                "Cut the roti into pieces, drizzle with condensed milk or chocolate sauce, and sprinkle with granulated sugar before serving."
            ],
            notes: "This street-food favorite is perfect for dessert or a snack. Adjust toppings to suit your taste. Be cautious of hot filling when serving!"
        )
        
        saveRecipe(
            name: "Banana Bread - One 2lb loaf",
            category: "Dessert",
            difficulty: "Easy",
            prepTime: "15 minutes",
            cookingTime: "50 minutes to 1 hour",
            baseServings: 1, // Makes one standard 2lb loaf
            currentServings: 1,
            ingredients: [
                // Dry Ingredients
                Ingredient(baseQuantity: 270, unit: "g", name: "plain (all-purpose) flour"),
                Ingredient(baseQuantity: 200, unit: "g", name: "caster (granulated) sugar"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "bicarbonate of soda"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "salt"),
                
                // Wet Ingredients
                Ingredient(baseQuantity: 3, unit: "small-medium", name: "bananas (ripe)"),
                Ingredient(baseQuantity: 2, unit: "large", name: "bananas (ripe, if using instead of small)"),
                Ingredient(baseQuantity: 1, unit: "large", name: "egg"),
                Ingredient(baseQuantity: 1, unit: "large", name: "egg yolk"),
                Ingredient(baseQuantity: 60, unit: "g", name: "plain yogurt (or sour cream or buttermilk)"),
                Ingredient(baseQuantity: 110, unit: "g", name: "unsalted butter, melted and cooled"),

                // Mix-ins
                Ingredient(baseQuantity: 100, unit: "g", name: "chocolate chips (mix of milk and dark recommended)"),
                Ingredient(baseQuantity: 60, unit: "g", name: "chopped walnuts"),
                Ingredient(baseQuantity: 20, unit: "g", name: "chopped pecans")
            ],
            prePrepInstructions: [
                "Preheat oven to Gas Mark 4.5 or 165°C (fan-assisted).",
                "Grease a 2lb loaf tin and line it with parchment paper, leaving an overhang on the long sides."
            ],
            instructions: [
                "In a large bowl, mix together the dry ingredients: flour, sugar, bicarbonate of soda, and salt.",
                "Mash the bananas in a separate bowl using a fork or potato masher.",
                "In another bowl, whisk together the whole egg and egg yolk. Add yogurt, melted butter, and the mashed bananas. Mix until combined.",
                "Pour the wet mixture into the bowl with the dry ingredients. Mix just until combined; avoid overmixing.",
                "Fold in 90% of the chocolate chips, walnuts, and pecans. Save the remaining 10% for topping.",
                "Pour the batter into the prepared loaf tin and sprinkle the reserved chocolate chips and nuts on top.",
                "Bake for 50 minutes to 1 hour. Check doneness with a skewer inserted into the middle; if it comes out clean, it's cooked.",
                "If the top browns too quickly and the skewer comes out unclean, cover the loaf loosely with foil and bake for additional time until fully cooked.",
                "Let the banana bread cool in the tin for 10 minutes, then transfer to a wire rack to cool completely before slicing."
            ],
            notes: "This banana bread is rich and moist, perfect for breakfast or dessert. Use overly ripe bananas for the best flavor. Customize with different nuts or chocolate types!"
        )
        
        saveRecipe(
            name: "Bao Buns (A Foolproof Recipe)",
            category: "Bread",
            difficulty: "Medium",
            prepTime: "20 minutes",
            cookingTime: "10 minutes",
            baseServings: 8, // Makes 8-12 buns
            currentServings: 8,
            ingredients: [
                // Dry Ingredients
                Ingredient(baseQuantity: 300, unit: "g", name: "all-purpose flour (see notes for substitutes)"),
                Ingredient(baseQuantity: 1.25, unit: "tsp", name: "instant yeast (see notes for substitutes)"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "baking powder"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "white sugar"),
                
                // Wet Ingredients
                Ingredient(baseQuantity: 165, unit: "g", name: "lukewarm water or milk (see notes)"),
                
                // Other
                Ingredient(baseQuantity: 1, unit: "as needed", name: "oil (for brushing)")
            ],
            prePrepInstructions: [
                "Ensure all ingredients are measured and ready.",
                "Prepare necessary tools: mixing bowl, steamer with liners, rolling pin, and biscuit cutter (optional)."
            ],
            instructions: [
                "To prepare the dough (manual method): In a large bowl, mix flour, instant yeast, baking powder, and sugar. Gradually add water or milk while stirring.",
                "Knead by hand until a rough dough forms. Rest for 10 minutes, then knead for 2-3 minutes until smooth.",
                "For the stand-mixer method: Combine all ingredients in the mixing bowl and knead with a dough hook on low speed for 8-10 minutes until smooth.",
                "To shape the buns: Roll the dough into a rope and divide into 8-12 pieces. Roll each piece into a ball and flatten with a rolling pin into an oval shape (dust with flour to prevent sticking).",
                "Brush a thin layer of oil over half the oval, then fold over lengthways.",
                "Alternatively, flatten the dough into a rectangle and use a round cutter to cut out circles. Roll each circle into an oval shape and fold as above.",
                "Line the steamer basket with parchment paper or silicone liners. Place the buns in the basket, leaving space for expansion.",
                "Let the buns proof for about 30 minutes or until they are plump and feel lighter in weight.",
                "To steam the buns: Add 500 ml of water to the steaming pot. Once boiling, reduce heat to medium-low and steam the buns for 10 minutes.",
                "Allow buns to cool completely if storing or freeze for later use.",
                "Reheat by steaming for 5 minutes if chilled or 7 minutes if frozen."
            ],
            notes: "Bao buns are soft and fluffy, perfect for filling with meats, vegetables, or sweet spreads. Adjust proofing time based on room temperature and ensure proper steaming for best results!"
        )
        
        saveRecipe(
            name: "Beijing Beef",
            category: "Main",
            difficulty: "Easy",
            prepTime: "30 minutes",
            cookingTime: "20 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 800, unit: "g", name: "beef strips (beef fillet or any tender beef strips will work)"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "Shaoxing cooking wine"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "soy sauce"),
                Ingredient(baseQuantity: 1, unit: "", name: "red capsicum, diced"),
                Ingredient(baseQuantity: 1, unit: "", name: "brown onion, diced"),
                Ingredient(baseQuantity: 3, unit: "cloves", name: "garlic, finely diced"),
                Ingredient(baseQuantity: 3, unit: "tbsp", name: "oyster sauce"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "black vinegar"),
                Ingredient(baseQuantity: 3, unit: "tbsp", name: "tomato sauce (ketchup)"),
                Ingredient(baseQuantity: 3, unit: "tsp", name: "sambal (chilli paste)"),
                Ingredient(baseQuantity: 200, unit: "g", name: "cornflour (cornstarch)"),
                Ingredient(baseQuantity: 400, unit: "ml", name: "beef tallow or neutral-flavoured oil"),
                Ingredient(baseQuantity: 1, unit: "as needed", name: "Rice, to serve")
            ],
            prePrepInstructions: [
                "Mix beef strips with Shaoxing cooking wine and soy sauce in a bowl. Marinate for 30 minutes to 1 hour.",
                "Prepare the sauce by mixing oyster sauce, black vinegar, tomato sauce, and sambal in a small bowl.",
                "Chop all vegetables and ensure the rice is cooked and kept warm."
            ],
            instructions: [
                "Heat oil in a wok to 180°C (350°F).",
                "Dust the marinated beef strips in cornflour, shaking off excess.",
                "Fry the beef in batches until crispy. Remove from the oil and set aside.",
                "Drain 99% of the oil from the wok and return it to high heat.",
                "Add diced onion and capsicum to the wok. Sauté for 2–3 minutes until slightly softened.",
                "Add diced garlic and toss well.",
                "Return the crispy beef to the wok and add the prepared sauce. Stir-fry over high heat for 2–3 minutes until the beef is well coated.",
                "Serve hot with steamed rice and optional wok-fried greens."
            ],
            notes: "Beijing Beef is a quick and flavorful dish that pairs perfectly with rice and stir-fried vegetables.\nCustomize the spice level by adjusting the sambal quantity to taste.\nMake sure to fry the beef in small batches to keep it crispy.\nLeftovers can be stored in an airtight container and reheated in a pan or air fryer."
        )
        
        saveRecipe(
            name: "Beef Chow Fun",
            category: "Main",
            difficulty: "Medium",
            prepTime: "20 minutes",
            cookingTime: "10 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 300, unit: "g", name: "flank steak"),
                Ingredient(baseQuantity: 4, unit: "g", name: "cornstarch"),
                Ingredient(baseQuantity: 7.5, unit: "ml", name: "soy sauce (for marinade)"),
                Ingredient(baseQuantity: 5, unit: "ml", name: "Shaoxing wine"),
                Ingredient(baseQuantity: 1, unit: "g", name: "baking soda"),
                Ingredient(baseQuantity: 0.3, unit: "g", name: "white pepper"),
                Ingredient(baseQuantity: 15, unit: "ml", name: "vegetable oil (for marinade)"),
                Ingredient(baseQuantity: 22, unit: "ml", name: "soy sauce (for noodle sauce)"),
                Ingredient(baseQuantity: 15, unit: "ml", name: "oyster sauce"),
                Ingredient(baseQuantity: 15, unit: "ml", name: "dark soy sauce"),
                Ingredient(baseQuantity: 10, unit: "ml", name: "sesame oil"),
                Ingredient(baseQuantity: 8, unit: "g", name: "sugar"),
                Ingredient(baseQuantity: 400, unit: "g", name: "wide flat rice noodles (fresh or refrigerated)"),
                Ingredient(baseQuantity: 2, unit: "cloves", name: "garlic, minced"),
                Ingredient(baseQuantity: 2, unit: "", name: "scallions, whites and greens separated and cut into 2-inch pieces"),
                Ingredient(baseQuantity: 100, unit: "g", name: "bean sprouts"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "vegetable oil (for cooking)")
            ],
            prePrepInstructions: [
                "Thinly slice flank steak against the grain on an angle into ¼-inch-thick pieces and transfer to a bowl.",
                "Add marinade ingredients (4 g cornstarch, 7.5 ml soy sauce, 5 ml Shaoxing wine, 1 g baking soda, 0.3 g white pepper, and 15 ml vegetable oil) to the beef and mix well. Marinate for 15 minutes.",
                "Combine noodle sauce ingredients (22 ml soy sauce, 15 ml oyster sauce, 15 ml dark soy sauce, 10 ml sesame oil, and 8 g sugar) in a small bowl and set aside.",
                "If using fresh rice noodles, microwave for 2–3 intervals of 60 seconds until soft and pliable. Gently separate them by hand once cooled."
            ],
            instructions: [
                "Heat vegetable oil in a large pan over medium-high heat.",
                "Fry marinated beef in a single layer until cooked and slightly browned on the edges. Remove and set aside.",
                "Using the residual oil, fry the scallion whites and garlic for 10 seconds.",
                "Add remaining oil, rice noodles, and noodle sauce to the pan. Toss gently with two spatulas, lifting from the bottom.",
                "Return the cooked beef, bean sprouts, and scallion greens to the pan. Toss gently until everything is mixed.",
                "Remove from heat and serve hot."
            ],
            notes: "Use fresh rice noodles if available for the best texture.\nAvoid over-stirring the noodles to keep them from breaking.\nCook beef in a single layer for good browning.\nThis dish is best served immediately after cooking."
        )
        
        saveRecipe(
            name: "Beef in Black Bean",
            category: "Main",
            difficulty: "Medium",
            prepTime: "10 minutes",
            cookingTime: "10 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 300, unit: "g", name: "beef steak, thinly sliced"),
                Ingredient(baseQuantity: 25, unit: "ml", name: "light soy sauce (for marinade)"),
                Ingredient(baseQuantity: 25, unit: "ml", name: "Shao Xing wine (optional, for marinade)"),
                Ingredient(baseQuantity: 25, unit: "g", name: "sugar (for marinade)"),
                Ingredient(baseQuantity: 5, unit: "ml", name: "cornstarch (for marinade)"),
                Ingredient(baseQuantity: 2.5, unit: "ml", name: "baking soda (for marinade)"),
                
                Ingredient(baseQuantity: 75, unit: "ml", name: "oyster sauce (for stir fry sauce)"),
                Ingredient(baseQuantity: 5, unit: "ml", name: "dark soy sauce (for stir fry sauce)"),
                Ingredient(baseQuantity: 75, unit: "ml", name: "water (for stir fry sauce)"),
                Ingredient(baseQuantity: 2.5, unit: "ml", name: "cornstarch (for stir fry sauce)"),
                Ingredient(baseQuantity: 15, unit: "ml", name: "Shao Xing wine (for stir fry sauce)"),
                Ingredient(baseQuantity: 15, unit: "g", name: "sugar (for stir fry sauce)"),

                Ingredient(baseQuantity: 2, unit: "tbsp", name: "oil (for cooking)"),
                Ingredient(baseQuantity: 2, unit: "cloves", name: "garlic, chopped"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "ginger, chopped"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "fermented black beans, roughly chopped or whole"),
                Ingredient(baseQuantity: 1, unit: "", name: "onion, diced"),
                Ingredient(baseQuantity: 1, unit: "", name: "bell pepper, chopped")
            ],
            prePrepInstructions: [
                "Cut the beef steak into thin slices against the grain.",
                "Marinate the beef with 25 ml light soy sauce, 25 g sugar, 25 ml Shao Xing wine (optional), 5 ml corn starch, and 2.5 ml baking soda. Mix well and let sit for 10–15 minutes.",
                "Mix all the stir fry sauce ingredients (75 ml oyster sauce, 5 ml dark soy sauce, 75 ml water, 2.5 ml corn starch, 15 ml Shao Xing wine, and 15 g sugar) in a small bowl and set aside.",
                "Roughly chop the black beans or leave them whole if preferred."
            ],
            instructions: [
                "Heat a wok or pan over medium-high heat and drizzle in oil. Add the marinated beef slices.",
                "Flatten the beef and sear for 2–3 minutes, then flip and stir fry for another 2–3 minutes.",
                "Add the diced onions and stir fry for 1 minute, then add the bell peppers and stir for a few seconds. Remove from the pan and set aside.",
                "In the same pan, drizzle a bit more oil. Sauté the chopped garlic over medium heat for 1 minute.",
                "Add the ginger and stir for a few seconds. Then add the black beans and stir fry for 1–2 minutes.",
                "Pour in the sauce mixture and stir until the sauce thickens.",
                "Add the fried beef, onions, and peppers back into the pan. Toss well over medium-high heat to combine evenly for 1–2 minutes.",
                "Remove from heat and transfer to a serving plate. Serve hot with plain rice, egg fried rice, or noodles."
            ],
            notes: "Adjust sugar and salt to taste.\nYou can substitute black beans with black bean garlic sauce if needed.\nEnsure the beef is thinly sliced and not overcrowded in the pan for best browning.\nThis dish pairs well with hot steamed rice or noodles."
        )
        
        saveRecipe(
            name: "Keema (Instant Pot Ground Beef Curry)",
            category: "Main Course",
            difficulty: "Medium",
            prepTime: "30 minutes",
            cookingTime: "30 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                // Main Ingredients
                Ingredient(baseQuantity: 1, unit: "lb", name: "ground beef (lean or regular)"),
                Ingredient(baseQuantity: 1, unit: "medium", name: "onion, peeled and chopped into eighths"),
                Ingredient(baseQuantity: 5, unit: "cloves", name: "garlic, peeled"),
                Ingredient(baseQuantity: 0.5, unit: "inch", name: "ginger, peeled and cut into a few pieces"),
                Ingredient(baseQuantity: 0.25, unit: "cup", name: "neutral oil (such as avocado or grapeseed)"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "cumin seeds"),
                Ingredient(baseQuantity: 1, unit: "small", name: "green chili peppers, stems removed and roughly chopped"),
                Ingredient(baseQuantity: 1, unit: "small to medium", name: "tomato, quartered or use a chopped tomato can"),
                Ingredient(baseQuantity: 0.5, unit: "lb", name: "potatoes, diced"),
                
                // Ground Spices & Salt
                Ingredient(baseQuantity: 2, unit: "tsp", name: "coriander powder"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "cumin powder"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "turmeric powder"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "red chili powder, or to taste"),
                Ingredient(baseQuantity: 0.25, unit: "tsp", name: "red chili flakes (optional)"),
                Ingredient(baseQuantity: 0.25, unit: "tsp", name: "freshly ground black pepper"),
                Ingredient(baseQuantity: 1.25, unit: "tsp", name: "kosher salt, or to taste"),
                
                // After Pressure Cooking
                Ingredient(baseQuantity: 135, unit: "g", name: "Peas"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "whole milk yogurt"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "cilantro leaves, finely chopped"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "garam masala"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "freshly squeezed lemon juice (optional)")
            ],
            prePrepInstructions: [
                "Place onion, garlic, and ginger in a food processor.",
                "Pulse until finely chopped but not blended.",
                "Use the pulse function to roughly chop the tomato and green chili peppers.",
                "Set aside."
            ],
            instructions: [
                "Select the Sauté setting on the Instant Pot and set to More/High.",
                "When the screen says 'Hot', add oil and cumin seeds.",
                "Let them sizzle for a few seconds.",
                "Add the onion mixture and sauté until lightly browned, about 6-8 minutes.",
                "Deglaze the Instant Pot with a splash of water, stirring to remove any bits stuck to the pan.",
                "Add ground beef and cook, stirring to remove lumps, until the meat changes color, about 4-5 minutes.",
                "Add the tomato and green chili mixture, ground spices, and salt.",
                "Mix well, deglazing any bits. (No need to add extra water as the beef and tomatoes provide enough moisture.)",
                "Cancel Sauté, close the lid, and seal.",
                "Select the Pressure Cook setting on High for 10 minutes.",
                "After cooking, allow pressure to naturally release for 5 minutes, then manually release any remaining pressure.",
                "Select the Sauté setting on More/High.",
                "Stir in yogurt and sauté until the meat turns glossy and no excess liquid remains, about 6-7 minutes.",
                "Taste and adjust salt and spices.",
                "Sprinkle with garam masala, cilantro, and lemon juice (if desired).",
                "Serve warm."
            ],
            notes: "The moisture from the tomato and beef is sufficient for pressure cooking; no extra water is needed. If it appears dry, add a small splash of water and mix. Keema freezes well. Cool completely before transferring to an airtight container. Reheat in a saucepan or microwave, adding a splash of water if needed."
        )
        
        saveRecipe(
            name: "Beef Lo Mein (Easy)",
            category: "Main",
            difficulty: "Medium",
            prepTime: "23 minutes",
            cookingTime: "7 minutes",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 300, unit: "g", name: "flank steak, thinly sliced"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "soy sauce (for marinade)"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "Shaoxing wine (for marinade)"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "cornstarch (for marinade)"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "sugar (for marinade)"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "vegetable oil (for marinade)"),

                Ingredient(baseQuantity: 3, unit: "tbsp", name: "soy sauce (for sauce)"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "oyster sauce (for sauce)"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "dark soy sauce (for sauce)"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "sesame oil (for sauce)"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "sugar (for sauce)"),

                Ingredient(baseQuantity: 400, unit: "g", name: "fresh egg noodles"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "vegetable oil (for cooking)"),
                Ingredient(baseQuantity: 1, unit: "pc", name: "carrot, julienned"),
                Ingredient(baseQuantity: 1, unit: "pc", name: "red bell pepper, sliced"),
                Ingredient(baseQuantity: 1, unit: "cup", name: "cabbage, shredded"),
                Ingredient(baseQuantity: 60, unit: "ml", name: "water (for steaming veg)"),
                Ingredient(baseQuantity: 2, unit: "stalks", name: "green onions, chopped")
            ],
            prePrepInstructions: [
                "Thinly slice flank steak against the grain into ¼-inch-thick pieces.",
                "Add marinade ingredients (2 tbsp soy sauce, 1 tbsp Shaoxing wine, 1 tsp cornstarch, 1 tsp sugar, and 1 tbsp vegetable oil) to sliced beef and mix well. Set aside to marinate for 15 minutes at room temperature.",
                "To thinly slice beef, freeze it for 45–60 minutes until the exterior is firm, then slice with a sharp knife.",
                "In a small bowl, combine sauce ingredients (3 tbsp soy sauce, 1 tbsp oyster sauce, 1 tbsp dark soy sauce, 1 tbsp sesame oil, and 1 tsp sugar) and set aside."
            ],
            instructions: [
                "Bring a large pot of water to a boil. Blanch fresh egg noodles for 20–30 seconds until loosened.",
                "Strain noodles, rinse under cold running water, and shake off excess water. Set aside.",
                "Heat 1 tablespoon vegetable oil in a large pan over medium-high heat. Fry the marinated beef until cooked through and browned. Remove and set aside.",
                "Add carrots, red bell pepper, cabbage, and ¼ cup (60 ml) water to the pan. Cook for 30–60 seconds until vegetables are vibrant and just tender.",
                "Add blanched noodles to the pan followed by the prepared sauce mixture. Toss until noodles are evenly coated and sauce thickens slightly.",
                "Return the cooked beef to the pan and add green onions. Toss everything together until well combined. Remove from heat and serve immediately."
            ],
            notes: "Use fresh egg noodles if possible for best texture. Do not overcook the vegetables—they should stay vibrant and slightly crisp. Freezing the beef before slicing makes it easier to cut thinly.This dish is great with a side of chili oil or pickled vegetables."
        )
        
        saveRecipe(
            name: "Beef Ragu Sauce (Classic)",
            category: "Main",
            difficulty: "Medium",
            prepTime: "15 minutes",
            cookingTime: "3 hours",
            baseServings: 4,
            currentServings: 4,
            ingredients: [
                Ingredient(baseQuantity: 600, unit: "g", name: "beef chuck or stewing beef, cut into cubes"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "salt (for seasoning beef)"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "black pepper (for seasoning beef)"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "olive oil"),
                Ingredient(baseQuantity: 1, unit: "", name: "onion, diced"),
                Ingredient(baseQuantity: 1, unit: "", name: "carrot, diced"),
                Ingredient(baseQuantity: 3, unit: "cloves", name: "garlic, chopped"),
                Ingredient(baseQuantity: 0.5, unit: "tsp", name: "red chili flakes"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "tomato paste"),
                Ingredient(baseQuantity: 125, unit: "ml", name: "red wine"),
                Ingredient(baseQuantity: 400, unit: "g", name: "canned whole tomatoes"),
                Ingredient(baseQuantity: 250, unit: "ml", name: "beef broth"),
                Ingredient(baseQuantity: 2, unit: "tbsp", name: "unsalted butter"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "dried oregano"),
                Ingredient(baseQuantity: 1, unit: "tsp", name: "dried thyme"),
                Ingredient(baseQuantity: 1, unit: "", name: "bay leaf"),
                Ingredient(baseQuantity: 1, unit: "tbsp", name: "red wine vinegar"),
                Ingredient(baseQuantity: 400, unit: "g", name: "pasta (e.g. pappardelle or tagliatelle)"),
                Ingredient(baseQuantity: 20, unit: "g", name: "Parmesan cheese, grated"),
                Ingredient(baseQuantity: 5, unit: "leaves", name: "fresh basil, torn")
            ],
            prePrepInstructions: [
                "Pat the beef cubes dry and season with 1 tsp salt and ½ tsp freshly ground black pepper.",
                "Prepare the vegetables: dice the onion and carrot, chop the garlic, and measure out remaining ingredients.",
                "Set aside pasta or polenta for serving later."
            ],
            instructions: [
                "Heat olive oil in a large heavy-bottomed pot over medium-high heat. Brown the beef in small batches to develop flavor, then remove and set aside.",
                "In the same pot, cook the diced onions and carrots for 3–4 minutes until softened. Add red chili flakes and garlic, cooking for another minute.",
                "Stir in the tomato paste and cook for 30 seconds. Deglaze the pot with red wine and reduce by half, about 3 minutes.",
                "Add the canned tomatoes (break them up slightly with a spoon), beef broth, butter, oregano, thyme, and a pinch of salt. Stir until the butter melts, then add the bay leaf and reserved beef.",
                "Bring to a boil, then reduce to low heat. Cover and simmer for 2½ hours, stirring occasionally.",
                "Once the beef is fork-tender, remove the bay leaf and shred the meat using a potato masher or fork.",
                "Add red wine vinegar and simmer uncovered for another 30 minutes to thicken the sauce. Adjust seasoning to taste.",
                "Meanwhile, cook the pasta in salted water until al dente. Drain and toss with the finished ragu.",
                "Let the pasta stand for a couple of minutes to absorb the sauce before serving.",
                "Garnish with Parmesan cheese and fresh basil."
            ],
            notes: "For a deeper flavor, allow the ragu to rest for 10–15 minutes before serving. This sauce can also be made ahead and refrigerated overnight—it tastes even better the next day. Polenta is a great alternative to pasta. Use quality canned tomatoes for best results."
        )
        print("Default recipes added!")
    }
}
