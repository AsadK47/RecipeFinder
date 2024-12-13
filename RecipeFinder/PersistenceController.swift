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
        print("Default recipes added!")
    }
}
