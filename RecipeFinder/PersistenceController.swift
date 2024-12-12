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
    
    func saveRecipe(name: String, category: String, difficulty: String, baseServings: Int, currentServings: Int,
                    prepTime: String, cookingTime: String, ingredients: [Ingredient], prePrepInstructions: [String],
                    instructions: [String], notes: String) {
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
            baseServings: 4,
            currentServings: 4,
            prepTime: "20 minutes",
            cookingTime: "20 minutes",
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
        print("Default recipes added!")
    }
}
